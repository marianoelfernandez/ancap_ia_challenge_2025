from contextlib import asynccontextmanager
from typing import AsyncGenerator
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from config.settings import get_settings
from api.query.router import router as query_router

from utils.cache_connection import create_or_get_and_deploy_streaming_vector_search_index, get_firestore_client, get_gcs_client, get_embedding_model

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()

firestore_client = None
gcs_client = None
embedding_model = None

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan events."""
    global firestore_client, gcs_client, embedding_model
    
    logger.info(f"Starting chatbot data service V: {settings.VERSION}")
    
    try:

        
        # Initialize clients once during startup
        logger.info("Initializing Firestore client...")
        firestore_client = get_firestore_client()
        
        logger.info("Initializing GCS client...")
        gcs_client = get_gcs_client()
        
        create_or_get_and_deploy_streaming_vector_search_index()
        logger.info("Initializing embedding model...")
        embedding_model = get_embedding_model()
        

        logger.info("Testing client connections...")
        

        try:
            
            collections = list(firestore_client.collections())
            logger.info("Firestore connection successful")
        except Exception as e:
            logger.warning(f"Firestore connection test failed: {e}")
        

        try:
           
            buckets = list(gcs_client.list_buckets())
            logger.info("GCS connection successful")
        except Exception as e:
            logger.warning(f"GCS connection test failed: {e}")
        

        
        logger.info("All clients initialized successfully!")
        

        app.state.firestore_client = firestore_client
        app.state.gcs_client = gcs_client
        app.state.embedding_model = embedding_model
        
    except Exception as e:
        logger.error(f"Failed to initialize clients: {e}")
        raise e

    yield

    logger.info("Shutting down chatbot data service")
    

def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Chatbot Data Service",
        description="Data service for chatbot system with BigQuery integration",
        version=settings.VERSION,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

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

@app.get("/health")
async def health_check():
    """Health check endpoint to verify all clients are working."""
    try:
        health_status = {
            "service": "Chatbot Data Service",
            "version": settings.VERSION,
            "status": "healthy",
            "clients": {}
        }
        
        # Check Firestore client
        try:
            list(app.state.firestore_client.collections())
            health_status["clients"]["firestore"] = "connected"
        except Exception as e:
            health_status["clients"]["firestore"] = f"error: {str(e)}"
            health_status["status"] = "degraded"
        
        # Check GCS client
        try:
            list(app.state.gcs_client.list_buckets())
            health_status["clients"]["gcs"] = "connected"
        except Exception as e:
            health_status["clients"]["gcs"] = f"error: {str(e)}"
            health_status["status"] = "degraded"
        
        # Check embedding model
        try:
            app.state.embedding_model.encode(["health check"])
            health_status["clients"]["embedding_model"] = "loaded"
        except Exception as e:
            health_status["clients"]["embedding_model"] = f"error: {str(e)}"
            health_status["status"] = "degraded"
        
        return health_status
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "service": "Chatbot Data Service",
            "version": settings.VERSION,
            "status": "unhealthy",
            "error": str(e)
        }


def get_firestore_client_from_app():
    """Get the initialized Firestore client from app state."""
    return firestore_client

def get_gcs_client_from_app():
    """Get the initialized GCS client from app state."""
    return gcs_client

def get_embedding_model_from_app():
    """Get the initialized embedding model from app state."""
    return embedding_model

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )