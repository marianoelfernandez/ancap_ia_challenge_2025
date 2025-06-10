import requests
from utils.settings import Settings


settings = Settings()

def call_server(query: str) -> dict:
    payload = {
        "query": query
    }
    uri = f"{settings.mcp_server_uri}/query"
    response = requests.post(uri, json=payload).json()
    try:
        print(f"\nBigQuery response: {response}\n")
        print(f"Data: {response['data']}\n")
        metadata = response.get('metadata', {})
        return {'response': response, 'cost': float(metadata.get('cost_estimate', 0.0))}
    except Exception as e:
        return {"error": f"[Error parsing MCP response] {e}"}
    

