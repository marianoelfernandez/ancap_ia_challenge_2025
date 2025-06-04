import requests
from utils.settings import Settings
import uuid

settings = Settings()

def call_server(tool:str, query: str) -> str:
    request_id = str(uuid.uuid4()) 

    # payload = {
    #     "jsonrpc": "2.0",
    #     "id": request_id,
    #     "method": "tools/call",
    #     "params": {
    #         "name": tool,
    #         "arguments": query
            
    #     }
    # }

    payload = {
        "sql_query": query
    }
    uri = f"{settings.mcp_server_uri}/query"
    response = requests.post(uri, json=payload).json()
    try:
        print(f"BigQuery response: {response}")
        print(f"BigQuery response: {response['data'][0]}")
        return response["data"][0]["rows"]
    except Exception as e:
        return f"[Error parsing MCP response] {e}"