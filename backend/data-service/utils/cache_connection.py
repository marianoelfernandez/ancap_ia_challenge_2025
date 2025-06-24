from datetime import timedelta, timezone
import logging
from typing import List, Dict, Any, Optional


import vertexai
from google.cloud import storage
from google.cloud import firestore 
from google.cloud.aiplatform.matching_engine import MatchingEngineIndex
from google.cloud.aiplatform.matching_engine import MatchingEngineIndexEndpoint
from vertexai.language_models import TextEmbeddingModel
from config.settings import get_settings



settings = get_settings()  

PROJECT_ID = settings.GCP_PROJECT_ID
LOCATION = "southamerica-east1"
GCS_BUCKET_NAME = settings.GCS_BUCKET_NAME 

EMBEDDING_MODEL_NAME = "gemini-embedding-001"
EMBEDDING_TASK_TYPE = "RETRIEVAL_DOCUMENT" 
EMBEDDING_DIMENSIONS = 768 
SIMILARITY_THRESHOLD = settings.SIMILARITY_THRESHOLD


INDEX_DISPLAY_NAME = settings.INDEX_DISPLAY_NAME
ENDPOINT_DISPLAY_NAME = settings.ENDPOINT_DISPLAY_NAME
DEPLOYED_INDEX_ID = settings.DEPLOYED_INDEX_ID
 
FIRESTORE_DATABASE_NAME = settings.FIRESTORE_DATABASE_NAME
FIRESTORE_COLLECTION_NAME = settings.FIRESTORE_COLLECTION_NAME
TTL_DURATION_HOURS = 24

from langchain_google_vertexai import VertexAIEmbeddings
from langchain_google_firestore import FirestoreVectorStore

# Initialize your embedding model
embedding = VertexAIEmbeddings(
    model_name="text-multilingual-embedding-002",
    project=PROJECT_ID
)

# Create/connect your Firestore vector store
vector_store = FirestoreVectorStore(
    collection="query_cache",
    embedding_service=embedding
)

_embedding_model: Optional[TextEmbeddingModel] = None
_firestore_client: Optional[firestore.Client] = None
_deployed_endpoint: Optional[MatchingEngineIndexEndpoint] = None
_gcs_client: Optional[storage.Client] = None
_streaming_index: Optional[MatchingEngineIndex] = None


def get_embedding_model() -> TextEmbeddingModel:
    """Gets or initializes the TextEmbeddingModel."""
    global _embedding_model
    if _embedding_model is None:
        vertexai.init(project=PROJECT_ID, location=LOCATION)
        _embedding_model = TextEmbeddingModel.from_pretrained(EMBEDDING_MODEL_NAME)
    return _embedding_model

def get_firestore_client() -> firestore.Client:
    """Gets or initializes the Firestore client."""
    global _firestore_client
    if _firestore_client is None:
        _firestore_client = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_NAME)
    return _firestore_client

def get_gcs_client() -> storage.Client:
    """Gets or initializes the Google Cloud Storage client."""
    global _gcs_client
    if _gcs_client is None:
        _gcs_client = storage.Client(project=PROJECT_ID)
    return _gcs_client


def save_query(query_text: str, sql_query: str) -> str:
    """
    Saves a new query and its corresponding SQL to Firestore metadata,
    and directly adds its embedding to the deployed streaming Vector Search Index.
    Includes a TTL expiration timestamp.

    Args:
        query_text: The natural language query.
        sql_query: The SQL query corresponding to the natural language query.

    Returns:
        The unique datapoint ID generated for this entry.
    """
    id = vector_store.add_texts(
        texts=[query_text],
        metadatas=[{"sql":sql_query}]
    )
    print("Query saved, response:", id)
    return id


from typing import List, Dict, Any, Optional
from google.cloud import firestore
from google.cloud.firestore_v1.base_vector_query import DistanceMeasure
from google.cloud.firestore_v1.vector import Vector

def retrieve_query(query_text: str, num_results: int = 1, threshold: float = 0.15) -> Optional[List[str]]:
    """
    Retrieves SQL queries from Firestore whose natural language embeddings are similar
    to the input query, within a distance threshold.

    Args:
        query_text: The natural language query to search for.
        num_results: Max number of similar queries to retrieve.
        threshold: Max distance allowed for a match (lower = more similar).

    Returns:
        A list of SQL strings (max one by default) or None if no good match found.
    """
    try:
        query_vector = embedding.embed_query(query_text)  


        db = firestore.Client(project="ancap-equipo2")
        collection = db.collection("query_cache")

        docs = list(db.collection("query_cache").find_nearest(
            vector_field="embedding",
            query_vector=Vector(query_vector),
            distance_measure=DistanceMeasure.COSINE,
            limit=num_results,
            distance_threshold=threshold
        ).stream())


        results = []
        if not docs:
            print("No documents found in Firestore for the given query.")
            logging.info("No documents found in Firestore for the given query.")
            return None
        else:

            data = docs[0].to_dict()
            metadata = data.get("metadata")
            return metadata.get("sql", None)

    except Exception as e:
        print(f"Error in retrieve_query: {e}")
        logging.exception("retrieve_query failed")
        return None
