from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import ValidationError,BaseModel
from utils.auth import get_user_id_from_auth
import logging
from services.agent import Agent

router = APIRouter()
agent = Agent()
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


class QueryRequest(BaseModel):
    query: str
    conversation_id: Optional[str] = None
    auth_payload: Optional[dict] = None

@router.post("/query")
def receive_query_endpoint(req:QueryRequest,  authorization: str = Header(...)):
    logger.debug("Received query request")
    try:
        user_id = get_user_id_from_auth(authorization)
        result, conv_id = agent.ask_agent(req.query, req.conversation_id, user_id)
        return {"response": result, "conversation_id":conv_id}
    except ValidationError as ve:
        logger.warning(f"Validation error: {ve.errors()}")
        raise HTTPException(422, ve.errors())
    except Exception as e:
        logger.error(f"Unexpected error with query: {str(e)}", exc_info=True)
        raise HTTPException(500, f"{e}")

