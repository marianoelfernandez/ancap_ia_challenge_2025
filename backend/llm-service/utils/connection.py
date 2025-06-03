import requests
from utils.settings import Settings
import uuid

settings = Settings()

def call_server(tool:str, query: str) -> str:
    request_id = str(uuid.uuid4()) 

    payload = {
        "jsonrpc": "2.0",
        "id": request_id,
        "method": "tools/call",
        "params": {
            "name": tool,
            "arguments": query
            
        }
    }
    uri = f"{settings.mcp_server_uri}/mcp"
    response = requests.post(uri, json=payload).json()
    try:
        return response["result"]["content"][0]["text"]
    except Exception as e:
        return f"[Error parsing MCP response] {e}"