import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import json
from routers import conversation, admin
from services.agent import UtilitiesAgent

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


@app.on_event("startup")
async def startup_event():
    asyncio.create_task(refresh_periodically())


async def refresh_periodically():
    while True:
        await refresh_schemas()
        await asyncio.sleep(24 * 60 * 60)

async def refresh_schemas():
    try:
        agent = UtilitiesAgent()
        schema = await agent.parse_schema()
        print(f"\nSchema refreshed: {schema}\n")
        logger.info(f"Schema refreshed successfully")
    except Exception as e:
        logger.error(f"Error refreshing schemas: {e}")
