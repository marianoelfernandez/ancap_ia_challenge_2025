import requests
from utils.settings import Settings
import uuid

settings = Settings()

def call_server(query: str) -> str:
    payload = {
        "query": query
    }
    uri = f"{settings.mcp_server_uri}/query"
    response = requests.post(uri, json=payload).json()
    try:
        print(f"BigQuery response: {response}")
        print(f"BigQuery response: {response['data'][0]}")
        return response["data"][0]["rows"]
    except Exception as e:
        return f"[Error parsing MCP response] {e}"
    

