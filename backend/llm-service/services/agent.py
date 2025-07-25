from langsmith import traceable
from langchain.memory import ConversationBufferMemory
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langgraph.graph import StateGraph, END
from langchain_google_genai import ChatGoogleGenerativeAI
from utils.connection import call_server, get_cached_query, save_query_to_cache
from utils.settings import Settings
from typing import TypedDict, Optional
from utils.constants import schema_constant, intent_prompt, data_dictionary_prompt, schema_formatting_prompt
from db.dbconnection import check_or_generate_conversation_id, save_query, build_memory_of_conversation
from utils.auth import permissions_check
from utils.transformers import extract_sql_and_message
from services.schema_client import schema_client
import json

settings = Settings.get_settings()

class AgentState(TypedDict):
    input: str
    output: Optional[str]
    is_sql: Optional[bool]
    schema: Optional[str]
    generated_sql: Optional[str]
    needs_more_info: Optional[bool]
    conversation_id: Optional[str]
    tables_used: Optional[list[str]]
    cost: Optional[float]
    SQL_retries : Optional[int] = 3
    memory: Optional[ConversationBufferMemory]
    agent_response: Optional[str]

class Agent():
    def __init__(self):
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.0-flash-001",
            temperature=0,
            google_api_key=settings.api_key
            )
        self.pro_agent =ChatGoogleGenerativeAI(
            model="gemini-2.5-flash-preview-05-20",
            temperature=0,
            google_api_key=settings.api_key
            )
        self.general_prompt = ChatPromptTemplate.from_messages([
            ("system", """Sos una asistente de un sistema de ANCAP Uruguay, 
             tu objetivo es ayudar al usuario a consultar la base de datos de ANCAP, esta esta relacionada con el sistema de facturacion y entregas. 
             Deberas interpretar sus consultas en lenguaje natural. 
             NO CONTESTES OTRA COSA QUE NO SE RELACIONE CON EL SISTEMA DE ANCAP \n"""),
            MessagesPlaceholder("chat_history"),
            ("user", "{input}"),
        ])


        self.summarize_query_prompt = ChatPromptTemplate.from_messages([
            ("system", """Sos un agente especializado en resumir consultas de usuario a frases breves, 
             estas van a ser usadas como resumen de toda una conversacion.
             No agregues puntos al final de la frase."""),
            ("user", "{input}"),
        ])

        self.general_chain = self.general_prompt | self.llm

        self.summarize_query_chain = self.summarize_query_prompt | self.llm

        self.sql_generation_prompt = ChatPromptTemplate.from_messages([
        ("system", """
         Eres un amigable experto SQL con acceso a un esquema de base de datos.\n
        Tienes acceso a las siguientes tablas y herramientas:\n\n{schema}"""),
        ("system", """
         El usuario te proporcionará una consulta en lenguaje natural.\n"""),
        ("user", "{input}"),
        ("system", """
         También tienes la consulta enriquecida con nombres de tablas para ayudarte a generar el código SQL: {curated_query}.\n
         Debes generar una consulta SQL que responda a la consulta del usuario, NO debes preguntarle al usuario.
         Tambien es obligatorio que agregues un mensaje **Descripción de los datos:** y a continuacion agregues una descripción breve de los datos que va a poder ver en la grafica. Intenta explicar de forma detallada pero que le permita a una persona sin conocimientos de SQL entender que datos va a ver en la grafica.
         El contexto de los datos es sobre una refinadora de petróleo ANCAP""")
        ])

        self.sql_chain = self.sql_generation_prompt | self.pro_agent

        self.graph = self._build_graph(AgentState)
        self.runnable = self.graph.compile()


    def _build_graph(self, schema):
        builder = StateGraph(state_schema=schema)

        def check_cache(state: AgentState) -> AgentState:
            query = state["input"]


            cached_result = get_cached_query(query)
            print(f"Cached Result: {cached_result}")
            if cached_result and 'response' in cached_result:
                state["generated_sql"] = cached_result['response']
                state["needs_more_info"] = False
                return state
            else:
                state["needs_more_info"] = True
                return state


        def load_schema_node(state):
            if "schema" in state:
                return state 

            state["schema"] = settings.get_schema()
            state["needs_more_info"] = False
            state["tables_used"] = []
            state["SQL_retries"] = 3
            if "conversation_id" not in state and "conversation_id" in state.get("input", {}):
                state["conversation_id"] = state["input"]["conversation_id"]
            conv_id = state["conversation_id"]
            state["memory"] = build_memory_of_conversation(conv_id)
            return state


        def detect_type(state : AgentState) -> AgentState:
            query = state["input"]
            conv_id = state["conversation_id"]
            memory = state.get("memory", ConversationBufferMemory())
            response = self.llm.invoke(intent_prompt.format(query=query, chat_history=memory.chat_memory.messages))
            is_sql = "SQL" in response.content.upper()
            return {**state, "is_sql": is_sql}
        
        def query_translator(state: AgentState) -> AgentState:
            try:
                query = state["input"]
                memory = state.get("memory", ConversationBufferMemory())
                prompt = data_dictionary_prompt.format(
                    query=query,
                    chat_history = memory.chat_memory.messages,
                )

                response = self.llm.invoke(prompt)
                content = str(response.content)

                if "[RETRY]" in content.strip():
                    state["needs_more_info"] = True
                    state["output"] = content.strip()[7:]
                    return state
                else:
                    state["needs_more_info"] = False
                    state["output"] = content.strip()
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
            return state
    
        def prepare_sql(state: AgentState) -> AgentState:
            try:
                query = state["input"]
                schema = state["schema"]
                curated_query = state["output"]
                print(f"Curated Query: {curated_query}")
                conversation_id = state.get("conversation_id", None)
                response = self.sql_chain.invoke({"input": query, "schema": schema, "curated_query": curated_query})
                sql, ai_message = extract_sql_and_message(response.content)
                agent_response = ai_message.strip()
                generated_sql = sql.strip()
                state["agent_response"] = agent_response
                state["generated_sql"] = generated_sql
                save_query_to_cache(state["input"], generated_sql)
                return state
            except Exception as e:
                state["output"] = f"[Error durante la consulta] {e}"
                raise Exception(state["output"])

        def execute_sql(state: AgentState) -> AgentState:
            try:
                generated_sql = state["generated_sql"]
                conv_id = state.get("conversation_id", None)
                tables_used = permissions_check(generated_sql, conv_id)
                state["tables_used"] = list(dict.fromkeys(tables_used))
                if not generated_sql:
                    return {**state, "output": "No se generó SQL"}
                
                result = call_server(generated_sql)
                state["output"] = str(result['response']) if 'response' in result else str(result['error'])
                state['cost'] = float(result.get('cost', 0.0))

                return state
            except Exception as e:
                state["SQL_retries"] -= 1
                return {**state, "output": f"[Error al ejecutar SQL] {e}"}


        def general_llm(state):
            conv_id = state["conversation_id"]
            memory = state.get("memory", ConversationBufferMemory())
            response = self.general_chain.invoke({
                "input": state["input"],
                "chat_history": memory.chat_memory.messages,
            })
            return {"output": response.content}

        builder.add_node("load_schema", load_schema_node)
        builder.add_node("detect_type", detect_type)
        builder.add_node("check_cache", check_cache)
        builder.add_node("query_translator", query_translator)
        builder.add_node("respond_with_retry", respond_with_retry)
        builder.add_node("prepare_sql", prepare_sql)
        builder.add_node("execute_sql", execute_sql)
        builder.add_node("general_llm", general_llm)

        builder.set_entry_point("check_cache")
        builder.add_edge("check_cache", "load_schema")
        builder.add_edge("load_schema", "detect_type")
        builder.add_conditional_edges(
            "detect_type",
            lambda s: "query_translator" if s["is_sql"] else "general_llm",
        )
        builder.add_conditional_edges("query_translator", route_from_query_translator)
        builder.set_finish_point("respond_with_retry")
        builder.add_edge("prepare_sql", "execute_sql")
        
        builder.add_conditional_edges(
            "execute_sql",
            lambda s: "prepare_sql" if (s["SQL_retries"]<3 and s["SQL_retries"]>0)  else END,
        )

        builder.add_edge("execute_sql", END)
        builder.add_edge("general_llm", END)

        return builder

    def ask_agent(self, query: str, conversation_id: str, user_id : str) -> tuple[str, str]:
            @traceable(name="Agent Graph Run")
            def _run_with_trace(input_query, conv_id):
                return self.runnable.invoke({"input": input_query, "conversation_id": conv_id})

            try:

                summarized_title = self.summarize_query_chain.invoke({"input": query})
                conv_id = check_or_generate_conversation_id(user_id, conversation_id, summarized_title.content.strip())

                result = _run_with_trace(query, conv_id)
                
                save_query(result["input"],
                            result.get("generated_sql", ""),
                              result.get("output", ""),
                              result.get("cost", 0),
                              conv_id,
                              result.get("tables_used", []),
                              result.get("agent_response", ""))
                

                return result["output"], result["conversation_id"], result.get("tables_used", []), result.get("generated_sql", ""), result.get("agent_response", "")
            except Exception as e:
                raise e



class UtilitiesAgent():

    def __init__(self):
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-pro-preview-06-05",
            temperature=0,
            google_api_key=settings.api_key
            )
        self.schema_formatting_chain = schema_formatting_prompt | self.llm

    async def parse_schema(self):
      if settings.local:
          return settings.set_schema(schema_constant)
      try:
          schema_json: str = json.dumps(await schema_client.get_schemas(), indent=2)
          response = self.schema_formatting_chain.invoke({
              "schema_json": schema_json,
              "schema_example": schema_constant
          })
          
          return settings.set_schema(str(response.content)) 
      except Exception as e:
          raise Exception(f"[Error al formatear el esquema] {e}")




