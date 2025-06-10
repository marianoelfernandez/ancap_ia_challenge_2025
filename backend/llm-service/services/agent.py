from pydantic import ValidationError
from langsmith import traceable
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langgraph.graph import StateGraph, END
from langchain_google_genai import ChatGoogleGenerativeAI
from utils.connection import call_server
from utils.settings import Settings
from typing import TypedDict, Optional
from utils.constants import schema_constant, intent_prompt, data_dictionary_prompt
from db.dbconnection import check_or_generate_conversation_id, save_query
from utils.auth import permissions_check

settings = Settings()

class AgentState(TypedDict):
    input: str
    output: Optional[str]
    is_sql: Optional[bool]
    schema: Optional[str]
    generated_sql: Optional[str]
    needs_more_info: Optional[bool]
    conversation_id: Optional[str]
    cost: Optional[float]

class Agent():
    def __init__(self):
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.0-flash-001",
            temperature=0,
            google_api_key=settings.api_key
            )
        self.memory = ConversationBufferMemory(return_messages=True, memory_key="chat_history")

        self.general_prompt = ChatPromptTemplate.from_messages([
            ("system", "You are a helpful assistant."),
            MessagesPlaceholder("chat_history"),
            ("user", "{input}"),
        ])
        self.general_chain = self.general_prompt | self.llm



        self.sql_generation_prompt = ChatPromptTemplate.from_messages([
        ("system", """
         Eres un amigable experto SQL con acceso a un esquema de base de datos.\n
        Tienes acceso a las siguientes tablas y herramientas:\n\n{schema}"""),
        ("user", "{input}")
        ])
        self.sql_chain = self.sql_generation_prompt | self.llm

        self.graph = self._build_graph(AgentState)
        self.runnable = self.graph.compile()

    def _build_graph(self, schema):
        builder = StateGraph(state_schema=schema)

        def load_schema_node(state):
            if "schema" in state:
                return state 

            schema_str = schema_constant
            state["schema"] = schema_str
            state["needs_more_info"] = False

            if "conversation_id" not in state and "conversation_id" in state.get("input", {}):
                state["conversation_id"] = state["input"]["conversation_id"]
            return state


        def detect_type(state : AgentState) -> AgentState:
            query = state["input"]
            response = self.llm.invoke(intent_prompt.format(query=query))
            is_sql = "SQL" in response.content.upper()
            return {**state, "is_sql": is_sql}
        
        def query_translator(state: AgentState) -> AgentState:
            try:
                query = state["input"]
                prompt = data_dictionary_prompt.format(
                    query=query
                )

                response = self.llm.invoke(prompt)

                if "[RETRY]" in response.content.strip():
                    state["needs_more_info"] = True
                    state["output"] = response.content.strip()
                    return state
                else:
                    state["needs_more_info"] = False
                    state["output"] = response.content.strip()
                    return state
            except Exception as e:
                return {
                    **state,
                    "output": f"[Error al traducir consulta] {e}"
                }
        
        def route_from_query_translator(state: AgentState) -> str:
            if state.get("needs_more_info"):
                return "respond_with_retry"
            return "prepare_sql"
        
        def respond_with_retry(state: dict) -> dict:
            self.memory.chat_memory.add_user_message(state["input"])
            self.memory.chat_memory.add_ai_message(state["output"])
            return state
    
        def prepare_sql(state: AgentState) -> AgentState:
            try:
                query = state["input"]
                schema = state["schema"]
                conversation_id = state.get("conversation_id", None)
                response = self.sql_chain.invoke({"input": query, "schema": schema})
                generated_sql = response.content.strip()
                state["generated_sql"] = generated_sql
                permissions_check(generated_sql, conversation_id)
                return state
            except Exception as e:
                state["output"] = f"[Error durante la consulta] {e}"
                raise Exception(state["output"])

        def execute_sql(state: AgentState) -> AgentState:
            try:
                generated_sql = state["generated_sql"]
                if not generated_sql:
                    return {**state, "output": "No se generó SQL"}
                result = call_server(generated_sql)
                state["output"] = result
                state['cost'] = -1 # TODO: add cost from result
                self.memory.chat_memory.add_user_message(state["input"])
                self.memory.chat_memory.add_ai_message(result)
                return state
            except Exception as e:
                return {**state, "output": f"[Error al ejecutar SQL] {e}"}


        def general_llm(state):
            response = self.general_chain.invoke({
                "input": state["input"],
                "chat_history": self.memory.chat_memory.messages,
            })
            self.memory.chat_memory.add_user_message(state["input"])
            self.memory.chat_memory.add_ai_message(response.content)
            return {"output": response.content}

        builder.add_node("load_schema", load_schema_node)
        builder.add_node("detect_type", detect_type)
        builder.add_node("query_translator", query_translator)
        builder.add_node("respond_with_retry", respond_with_retry)
        builder.add_node("prepare_sql", prepare_sql)
        builder.add_node("execute_sql", execute_sql)
        builder.add_node("general_llm", general_llm)

        builder.set_entry_point("load_schema")
        builder.add_edge("load_schema", "detect_type")
        builder.add_conditional_edges(
            "detect_type",
            lambda s: "query_translator" if s["is_sql"] else "general_llm",
        )
        builder.add_conditional_edges("query_translator", route_from_query_translator)
        builder.set_finish_point("respond_with_retry")
        builder.add_edge("prepare_sql", "execute_sql")
        builder.add_edge("execute_sql", END)
        builder.add_edge("general_llm", END)

        return builder

    def ask_agent(self, query: str, conversation_id: str| None, user_id : str) -> str:
            @traceable(name="Agent Graph Run")
            def _run_with_trace(input_query, conv_id):
                return self.runnable.invoke({"input": input_query, "conversation_id": conv_id})

            try:


                conv_id = check_or_generate_conversation_id(user_id, conversation_id)

                result = _run_with_trace(query, conv_id)
                print(f"\nResult: {result}\n")
                save_query(result["input"],
                            result.get("generated_sql", ""),
                              result.get("output", ""),
                              result.get("cost", 0),
                              conv_id)
                
                return result["output"]
            except Exception as e:
                raise e
            
    def clr_history(self):
        self.memory.clear()
