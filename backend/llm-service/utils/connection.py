import requests
from utils.settings import Settings


settings = Settings()

def call_server(query: str) -> str:
    payload = {
        "query": query
    }
    uri = f"{settings.mcp_server_uri}/query"
    response = requests.post(uri, json=payload).json()
    try:
        print(f"\nBigQuery response: {response}\n")
        print(f"Data: {response['data']}\n")
        return str(response["data"])
    except Exception as e:
        return f"[Error parsing MCP response] {e}"
    

