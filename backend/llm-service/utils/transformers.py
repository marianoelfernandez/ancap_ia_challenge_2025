import re

def extract_sql_and_message(text: str) -> tuple[str, str]:
  """
  Extracts SQL query and message from the provided text.
  """
  print(f"Extracting SQL and message from text: \n\n{text}")
  
  # Pattern to extract SQL query from ```sql code blocks
  sql_pattern = r"```sql\s*(.*?)\s*```"
  
  # Pattern to extract the description that comes before the SQL block
  # Look for text that starts with "**Descripción de los datos:**" and goes until the SQL block
  message_pattern = r"\*\*Descripción de los datos:\*\*\s*(.*?)(?=```sql|$)"
  
  sql_matches = re.findall(sql_pattern, text, re.DOTALL)
  message_matches = re.findall(message_pattern, text, re.DOTALL)
  
  if sql_matches:
    sql_query = sql_matches[0].strip()
    
    # If we found a message, use it; otherwise extract everything before the SQL block
    if message_matches:
      message = message_matches[0].strip()
    else:
      # Fallback: extract text before the first ```sql block
      sql_start = text.find("```sql")
      if sql_start > 0:
        message = text[:sql_start].strip()
        # Remove the "**Descripción de los datos:**" prefix if present
        if message.startswith("**Descripción de los datos:**"):
          message = message[len("**Descripción de los datos:**"):].strip()
      else:
        message = ""

    print(f"Extracted SQL query: {sql_query}")
    print(f"Extracted message: {message}")
    return sql_query, message
  else:
    # If no SQL block is found, return the original text as message and empty SQL query
    return '', text.strip() 

