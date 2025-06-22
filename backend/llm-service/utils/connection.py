import requests
from utils.settings import Settings


settings = Settings.get_settings()


def call_server(query: str) -> dict:
    payload = {
        "query": query
    }

    uri = f"{settings.mcp_server_uri}/query"
    response = requests.post(uri, json=payload).json()
    
    try:

        metadata = response.get('metadata', {})
        return {'response': response, 'cost': float(metadata.get('cost_estimate', 0.0))}
    except Exception as e:
        return {"error": f"[Error parsing MCP response] {e}"}
    

def get_cached_query(natural_query: str) -> dict:

    query_string = "?query_text=" + natural_query
    uri = f"{settings.mcp_server_uri}/embeddings/search" + query_string
    response = requests.post(uri).json()
    try:
        if (response['results'] is None or len(response['results']) == 0):
            return {"error": "No cached query found."}
        return {"response":response['results']['sql']}
    except Exception as e:
        return {"error": f"[Error parsing MCP embeddings response] {e}"}
    
def save_query_to_cache(natural_query: str, generated_SQL:str) -> dict:
    payload = {
        "query_text": natural_query,
        "sql_query": generated_SQL
    }
    uri = f"{settings.mcp_server_uri}/embeddings"
    response = requests.post(uri, json=payload).json()
    try:
        return response
    except Exception as e:
        return {"error": f"[Error parsing MCP embeddings response] {e}"}

