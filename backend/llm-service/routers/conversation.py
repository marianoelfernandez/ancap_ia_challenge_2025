
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import ValidationError,BaseModel

import logging
from services.agent import Agent

router = APIRouter()
agent = Agent()
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


class QueryRequest(BaseModel):
    query: str
    auth_payload: Optional[dict] = None

@router.post("/query")
def receive_query_endpoint(req:QueryRequest):
    logger.debug("Received create house request")
    try:
        result = agent.ask_agent(req.query)
        return {"message": result}
    except ValidationError as ve:
        logger.warning(f"Validation error: {ve.errors()}")
        raise HTTPException(422, ve.errors())
    except Exception as e:
        logger.error(f"Unexpected error inserting house: {str(e)}", exc_info=True)
        raise HTTPException(500, f"Error inserting house")

