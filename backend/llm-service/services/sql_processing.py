from utils.connection import call_server
from utils.auth import permissions_check
from db.dbconnection import save_query
import logging
import json

def process_sql_query(sql_query: str, conv_id, user_id, ai_response="Aquí está el resultado de tu consulta SQL") -> str:
    """
    Process the SQL query to ensure it is valid, sends it to data-service.
    
    Args:
        query (str): The SQL query to process.
        user_id (str): The ID of the user making the request.
    Returns:
        str: The processed SQL query.
    """
    try:
      
      if (conv_id is not None):
        tables_used = permissions_check(sql_query, conv_id)
        filtered_tables = list(dict.fromkeys(tables_used))

      else:
        filtered_tables = []
        
      result = call_server(sql_query)
      if "error" in result:
          logging.error(f"Error from data service: {result['error']}")
          raise Exception(result["error"])
      
      print(f"Result from data service: {result}")
      
      # Format the response properly for the frontend
      raw_response = result.get("response", "")
      
      # If the response is a dict or list, convert it to a formatted JSON string
      if isinstance(raw_response, (dict, list)):
          output = json.dumps(raw_response, indent=2, ensure_ascii=False)
      else:
          # If it's already a string, use it as is
          output = str(raw_response)
      
      save_query("User input: SQL Query",
                  sql_query,
                  output,
                  result.get("cost", 0),
                  conv_id,
                  filtered_tables,
                  ai_response)
      
    except Exception as e:
        logging.error(f"Error calling data service: {str(e)}")
        raise Exception(f"Error processing SQL query: {str(e)}")
    
    return output, conv_id, filtered_tables, sql_query, ai_response