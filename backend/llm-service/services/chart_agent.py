from langsmith import traceable
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from utils.settings import Settings
from typing import TypedDict, Optional


settings = Settings()


class ChartAgent():
    def __init__(self):
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.0-flash-001",
            temperature=0,
            google_api_key=settings.api_key
            )
        
        self.general_prompt = ChatPromptTemplate.from_messages([
            ("system", """Eres un agente especializado en recomendar qué tipo de gráfico se puede usar para una consulta de usuario.
            Tu tarea es sugerir un tipo de gráfico adecuado basado en la consulta del usuario, los tipos de gráficos que puedes sugerir son:
             Barras, Línea, Piechart. Debes responder con el nombre del gráfico, sin explicaciones adicionales. Devuelve NONE si no puedes sugerir un gráfico."""),
            ("user", "{natural_query}, received data output: {data_output}, using sql query: {sql_query}"),
        ])

        self.chart_chain = self.general_prompt | self.llm


    def ask_agent(self, natural_query: str, data_output: str | None, sql_query : str | None) -> str:
            @traceable(name="Chart Recommender Graph Run")
            def _run_with_trace(natural_query, data_output, sql_query):
                return self.chart_chain.invoke({"natural_query": natural_query,
                                                 "data_output": data_output,
                                                 "sql_query": sql_query})
            try:
              
                result = _run_with_trace(natural_query, data_output, sql_query)
                print(f"Chart recommendation result: {result.content.strip()}")
                return result.content.strip()
            except Exception as e:
                raise e
            

