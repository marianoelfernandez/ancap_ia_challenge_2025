from contextlib import asynccontextmanager
from typing import AsyncGenerator
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config.settings import get_settings
from api.query.router import router as query_router

logging.basicConfig(level=logging.INFO)

logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan events."""
    # Startup
    logger.info(f"Starting chatbot data service V: {settings.VERSION}")
    
    yield
    
    # Shutdown


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Chatbot Data Service",
        description="Data service for chatbot system with BigQuery integration",
        version=settings.VERSION,
        lifespan=lifespan,
    )

    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include routers
    app.include_router(query_router)

    return app

app = create_app()

@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "service": "Chatbot Data Service",
        "version": settings.VERSION,
        "status": "running"
    }

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )