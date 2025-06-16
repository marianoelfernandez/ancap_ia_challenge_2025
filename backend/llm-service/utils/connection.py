import httpx
from utils.settings import Settings


settings = Settings.get_settings()

client = httpx.AsyncClient()

async def call_server(query: str) -> dict:
    payload = {
        "query": query
    }
    uri = f"{settings.mcp_server_uri}/query"
    response = await client.post(uri, json=payload)
    response.raise_for_status()

    response_data = response.json()
    try:
        print(f"\nBigQuery response: {response_data}\n")
        print(f"Data: {response_data['data']}\n")
        metadata = response_data.get('metadata', {})
        return {'response': response_data, 'cost': float(metadata.get('cost_estimate', 0.0))}
    except Exception as e:
        return {"error": f"[Error parsing MCP response] {e}"}
    

