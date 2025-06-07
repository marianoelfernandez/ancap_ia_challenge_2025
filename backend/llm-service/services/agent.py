from langsmith import traceable
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langgraph.graph import StateGraph, END
from utils.connection import call_server
from utils.settings import Settings
from typing import TypedDict, Optional
from utils.constants import schema_constant, intent_prompt
from db.dbconnection import generate_conversation_id, save_query
from utils.auth import permissions_check

settings = Settings()

class AgentState(TypedDict):
    input: str
    output: Optional[str]
    is_sql: Optional[bool]
    schema: Optional[str]
    generated_sql: Optional[str]


class Agent():
    def __init__(self):
        self.llm = ChatOpenAI(model_name="gpt-4o-mini-2024-07-18", temperature=0)
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
            return state


        def detect_type(state):
            query = state["input"]
            response = self.llm.invoke(intent_prompt.format(query=query))
            # is_sql = "SQL" in response.content.upper()
            is_sql = True
            return {**state, "is_sql": is_sql}


        def prepare_sql(state: AgentState) -> AgentState:
            try:
                query = state["input"]
                schema = state["schema"]
                response = self.sql_chain.invoke({"input": query, "schema": schema})
                generated_sql = response.content.strip()
                state["generated_sql"] = generated_sql
                conversation_id = state.get("conversation_id", None)
                permissions_check(generated_sql, conversation_id)
                return state
            except Exception as e:
                return {"output": f"[Error al generar SQL] {e}"}

        def execute_sql(state: AgentState) -> AgentState:
            try:
                generated_sql = state["generated_sql"]
                if not generated_sql:
                    return {"output": "No se generó SQL"}
                result = call_server(generated_sql)
                state["output"] = result
                self.memory.chat_memory.add_user_message(state["input"])
                self.memory.chat_memory.add_ai_message(result)
                return state
            except Exception as e:
                return {"output": f"[Error al ejecutar SQL] {e}"}


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
        builder.add_node("prepare_sql", prepare_sql)
        builder.add_node("execute_sql", execute_sql)
        builder.add_node("general_llm", general_llm)

        builder.set_entry_point("load_schema")
        builder.add_edge("load_schema", "detect_type")
        builder.add_conditional_edges(
            "detect_type",
            lambda s: "prepare_sql" if s["is_sql"] else "general_llm",
        )
        builder.add_edge("prepare_sql", "execute_sql")
        builder.add_edge("execute_sql", END)
        builder.add_edge("general_llm", END)

        return builder

    def ask_agent(self, query: str, conversation_id: str| None, user_id : str) -> str:
            @traceable(name="Agent Graph Run")
            def _run_with_trace(input_query):
                return self.runnable.invoke({"input": input_query, "conversation_id": conversation_id})

            try:
                conv_id = conversation_id
                if not conversation_id:
                    conv_id = generate_conversation_id(user_id)

                result = _run_with_trace(query)
                save_query(result["input"],
                            result.get("generated_sql", ""),
                              result.get("output", ""),
                              0,
                              conv_id)
                
                return result["output"]
            except Exception as e:
                return f"[LangGraph Error] {e}"
    def clr_history(self):
        self.memory.clear()
