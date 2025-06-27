"""
Application settings and configuration.
"""
from functools import lru_cache
from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True
    )
    
    # Application settings
    VERSION: str = "0.1.0"
    DEBUG: bool = Field(default=False, description="Debug mode")
    ENVIRONMENT: str = Field(default="development", description="Environment")
    
    # Server settings
    HOST: str = Field(default="0.0.0.0", description="Server host")
    PORT: int = Field(default=8001, description="Server port")
    
    # CORS settings
    ALLOWED_ORIGINS: List[str] = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        description="Allowed CORS origins"
    )
    
    # GCP Settings
    GCP_PROJECT_ID: str = Field(..., description="GCP Project ID")
    GCP_DATA_PROJECT_ID: str = Field(..., description="GCP Data Project ID")
    GCP_DATA_DATASET_ID: str = Field(..., description="GCP Data Dataset ID")
    GCP_CREDENTIALS_PATH: str = Field(
        default="", 
        description="Path to GCP service account JSON file"
    )
    GCS_BUCKET_NAME: str = Field(..., description="GCS bucket name for cache, query storage")
    
    # BigQuery Settings
    BIGQUERY_DATASET: str = Field(..., description="BigQuery dataset name")
    BIGQUERY_LOCATION: str = Field(default="US", description="BigQuery location")
    
    # API Keys and External Services
    LLM_SERVICE_URL: str = Field(
        default="http://localhost:8000",
        description="LLM service URL"
    )
    SIMILARITY_THRESHOLD: float = Field(..., description="Threshold for similarity in cache retrieval")
    INDEX_DISPLAY_NAME: str = Field(...,description="Display name for the index in the cache")
    ENDPOINT_DISPLAY_NAME: str = Field(..., description="Display name for the index endpoint")
    DEPLOYED_INDEX_ID: str = Field(..., description="Deployed index ID for the cache")
    FIRESTORE_DATABASE_NAME: str = Field(..., description="Firestore database name for vector metadata")
    FIRESTORE_COLLECTION_NAME: str = Field(..., description="Firestore collection name for vector metadata")


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()