from typing import Optional
from fastapi import APIRouter, HTTPException, Header
from pydantic import ValidationError,BaseModel
from utils.auth import get_user_id_from_auth
import logging
from services.agent import Agent
from services.chart_agent import ChartAgent
from services.sql_processing import process_sql_query

router = APIRouter()
agent = Agent()
chart_agent = ChartAgent()
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


class QueryRequest(BaseModel):
    query: str
    conversation_id: Optional[str] = None
    auth_payload: Optional[dict] = None


class ChartRequest(BaseModel):
    natural_query: str
    data_output: Optional[str] = None
    sql_query: Optional[str] = None

@router.post("/query")
def receive_query_endpoint(req:QueryRequest,  authorization: str = Header(...)):
    logger.debug("Received query request")
    try:
        user_id = get_user_id_from_auth(authorization)
        result, conv_id, tables, sql, ai_resp = agent.ask_agent(req.query, req.conversation_id, user_id)
        return {"response": result, "conversation_id":conv_id, "tables_used": tables, "sql": sql, "ai_response": ai_resp}
    except ValidationError as ve:
        logger.warning(f"Validation error: {ve.errors()}")
        raise HTTPException(422, ve.errors())
    except Exception as e:
        logger.error(f"Unexpected error with query: {str(e)}", exc_info=True)
        raise HTTPException(500, f"{e}")
    


@router.post("/query/sql")
def receive_query_endpoint(req:QueryRequest,  authorization: str = Header(...)):
    logger.debug("Received SQL query request")
    try:
        user_id = get_user_id_from_auth(authorization)
        sql_query = req.query.strip()
        conv_id = req.conversation_id
        result, conv_id, tables, sql, ai_response = process_sql_query(sql_query, conv_id,user_id)
        return {"response": result, "conversation_id":conv_id, "tables_used": tables, "sql": sql, "ai_response": ai_response}
    except ValidationError as ve:
        logger.warning(f"Validation error: {ve.errors()}")
        raise HTTPException(422, ve.errors())
    except Exception as e:
        logger.error(f"Unexpected error with query: {str(e)}", exc_info=True)
        raise HTTPException(500, f"{e}")

@router.post("/chart")
def receive_chart_endpoint(req:ChartRequest,  authorization: str = Header(...)):
    logger.debug("Received chart suggestion request")
    try:
        print(f"Received chart request: {req}")
        result = chart_agent.ask_agent(req.natural_query, req.data_output[:100], req.sql_query)
        return result
    except ValidationError as ve:
        logger.warning(f"Validation error: {ve.errors()}")
        raise HTTPException(422, ve.errors())
    except Exception as e:
        logger.error(f"Unexpected error with chart suggestions: {str(e)}", exc_info=True)
        raise HTTPException(500, f"{e}")

