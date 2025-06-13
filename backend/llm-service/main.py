from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import json
from routers import conversation, admin
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="SQL LLM Server", description="Server with SQL generation capabilities")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(conversation.router)
app.include_router(admin.router)
