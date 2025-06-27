import re

def extract_sql_from_text(text: str) -> str:
    """
    Extract SQL query from text that may contain markdown SQL blocks.
    Returns the first SQL query found between ```sql and ``` markers.
    If no SQL block is found, returns the original text.
    """
    # Look for SQL between markdown SQL blocks
    sql_pattern = r"```sql\s*(.*?)\s*```"
    matches = re.findall(sql_pattern, text, re.DOTALL)
    
    if matches:
        # Return the first SQL query found
        return matches[0].strip()
    
    return text.strip()