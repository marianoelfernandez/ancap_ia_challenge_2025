import re
from langsmith import traceable
from langchain_openai import ChatOpenAI
from langchain.memory import ConversationBufferMemory
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from utils.settings import Settings
from typing import TypedDict, Optional
import json


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
              Tu tarea es sugerir un tipo de gráfico adecuado basado en la consulta del usuario, el resultado de la consulta y la SQL usada.

              Debes elegir *solo uno* de los siguientes tipos de gráfico, y devolver una respuesta en formato JSON:
              Barras: cuando se comparan cantidades o categorías distintas (por ejemplo: ventas por región, productos por tipo, etc.).
              Línea: cuando los datos representan una *evolución en el tiempo o muchos resultados* (por ejemplo: ingresos mensuales, etc.). 
              Piechart: cuando se muestra la *composición o proporción de un total*, ideal para porcentajes o distribución (por ejemplo: porcentaje de uso por tipo, participación por sector, etc.).

              Tu respuesta debe ser exclusivamente un JSON en este formato:
              title: TÍTULO DE GRÁFICA, chart: TIPO DE GRÁFICA 

              Si no puedes sugerir un gráfico adecuado, responde exactamente:
              title: NONE, chart: NONE 

              No des explicaciones adicionales bajo ninguna circunstancia."""),
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
                
                response = result.content.strip()
                clean_json_string = re.sub(r"^```json\s*|```$", "", response, flags=re.MULTILINE)
                formatted_result = json.loads(clean_json_string)

                return formatted_result
            except ValueError as e:
                print(f"Value error: {e}")
                return {
                    "title": "Sin título",
                    "chart": "NONE"
                }
            except Exception as e:
                raise e
            

