from http.client import HTTPException
from db.dbconnection import get_role, get_user
from utils.constants import entregas_tables, facturas_tables
import logging
import jwt
from fastapi import Header, HTTPException

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)
TABLES_PER_ROLE = {
    "Admin": [entregas_tables + facturas_tables],
    "Entregas": [entregas_tables],
    "Facturas": [facturas_tables]
}
def get_user_id_from_auth(authorization: str) -> str:
  if not authorization.startswith("Bearer "):
          raise HTTPException(401, "Invalid authorization header format")

  token = authorization.split(" ")[1]
  payload = jwt.decode(token, options={"verify_signature": False})
  user_id = payload.get("id") or payload.get("sub")

  if not user_id:
      raise HTTPException(401, "User ID not found in token")

  logger.debug(f"User ID from token: {user_id}")
  return user_id

def get_admin_user(authorization: str = Header(...)):
    user_id = get_user_id_from_auth(authorization)
    user = get_user(user_id)
    if not user or getattr(user, "role") != "Admin":
        raise HTTPException(status_code=403, detail="User is not authorized to perform this action")
    return user 

def permissions_check(sql, conversation_id) -> list:
    """
    Arg:
        conversation_id (str): The ID of the conversation to check.
    Returns:
        list: List of tables used in the query.
    """
    try:
        role = get_role(conversation_id)
        tables_used = extract_tables_from_sql(sql)
        
        allowed_tables = TABLES_PER_ROLE.get(role, [])
        tables_used = set(tables_used)
        if allowed_tables:
            allowed_tables = allowed_tables[0]

        unauthorized = [
            table for table in tables_used
            if table.strip().upper() not in allowed_tables
        ]
        if unauthorized:
            raise ValueError(f"El rol '{role}' no tiene acceso a las siguientes tablas: {unauthorized}")
        
        return tables_used
    except Exception as e:
        logger.error(f"Error in permissions_check: {e}")
        raise HTTPException(403, f"Permisos insuficientes: {str(e)}")
     

def extract_tables_from_sql(sql: str) -> list:
    """
    Extracts table names from a SQL query.

    Args:
        sql (str): The SQL query string.
        
    Returns:
        list: A list of table names found in the SQL query.
    """
    sql_lower = sql.lower()
    all_known_tables = entregas_tables + facturas_tables
    used_tables = [
        table.upper() for table in all_known_tables
        if table.lower() in sql_lower
    ]
    return used_tables

