from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import ValidationError,BaseModel
from utils.auth import get_user_id_from_auth
import logging
from services.agent import Agent
from services.chart_agent import ChartAgent

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
        result, conv_id, tables, sql = agent.ask_agent(req.query, req.conversation_id, user_id)
        return {"response": result, "conversation_id":conv_id, "tables_used": tables, "sql": sql}
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
        tables = chart_agent.ask_agent(req.natural_query, req.data_output[:100], req.sql_query)
        return {"response": tables}
    except ValidationError as ve:
        logger.warning(f"Validation error: {ve.errors()}")
        raise HTTPException(422, ve.errors())
    except Exception as e:
        logger.error(f"Unexpected error with chart suggestions: {str(e)}", exc_info=True)
        raise HTTPException(500, f"{e}")

