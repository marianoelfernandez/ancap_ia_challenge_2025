from fastapi import FastAPI
import logging
import json
from routers import conversation
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="SQL LLM Server", description="Server with SQL generation capabilities")
app.include_router(conversation.router)
