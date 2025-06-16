import json
import logging
import time
import uuid
import os 
import datetime
from datetime import timedelta, timezone
from typing import List, Dict, Any, Optional

# Google Cloud SDK imports
import vertexai
from google.cloud import storage
from google.cloud import firestore 
from google.cloud.aiplatform.matching_engine import MatchingEngineIndex
from google.cloud.aiplatform.matching_engine import MatchingEngineIndexEndpoint
from google.cloud.aiplatform_v1.services.match_service import MatchServiceClient
from google.cloud.aiplatform_v1.types import FindNeighborsRequest, IndexDatapoint
from google.api_core import exceptions 
from vertexai.language_models import TextEmbeddingModel, TextEmbeddingInput
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

def _generate_embedding(text: str) -> List[float]:
    """Helper to generate a single embedding."""
    model = get_embedding_model()
    try:
        embedding_input = TextEmbeddingInput(
            text=text, 
            task_type=EMBEDDING_TASK_TYPE
        )
        embeddings = model.get_embeddings([embedding_input], output_dimensionality=EMBEDDING_DIMENSIONS)

        if embeddings and embeddings[0].values:
            return embeddings[0].values
        else:
            raise ValueError("No embeddings generated for the input text.")
    except Exception as e:
        logging.error(f"Error  generating embeddings for text '{text[:50]}...': {e}")
        raise


def create_or_get_and_deploy_streaming_vector_search_index() -> MatchingEngineIndexEndpoint:
    """
    Retrieves the existing streaming-enabled Vertex AI Vector Search Index
    and its associated deployed endpoint. Raises an error if not found or deployed.
    """
    print(f"Attempting to retrieve existing streaming index '{INDEX_DISPLAY_NAME}'...")
    my_streaming_index = None
    get_embedding_model()

    try:
        indexes = MatchingEngineIndex.list(filter=f'display_name="{INDEX_DISPLAY_NAME}"')
        if not indexes:
            raise RuntimeError(f"Error: Streaming index '{INDEX_DISPLAY_NAME}' not found. Please create it manually or adjust configuration.")
        my_streaming_index = indexes[0]
        print(f"Found existing streaming index: '{my_streaming_index.resource_name}'")
        global _streaming_index
        _streaming_index = my_streaming_index
    except Exception as e:
        print(f"Error retrieving streaming index: {e}")
        logging.error(f"Error retrieving streaming index: {e}")
        raise

    print(f"Attempting to retrieve existing endpoint '{ENDPOINT_DISPLAY_NAME}'...")
    deployed_endpoint = None
    try:
        endpoints = MatchingEngineIndexEndpoint.list(filter=f'display_name="{ENDPOINT_DISPLAY_NAME}"')
        if not endpoints:
            raise RuntimeError(f"Error: Endpoint '{ENDPOINT_DISPLAY_NAME}' not found. Please create it manually or adjust configuration.")
        deployed_endpoint = endpoints[0]
        print(f"Found existing endpoint: '{deployed_endpoint.resource_name}'")

    except Exception as e:
        print(f"Error retrieving endpoint: {e}")
        logging.error(f"Error retrieving endpoint: {e}")
        raise


    deployed_index_found = False
    for deployed_idx in deployed_endpoint.deployed_indexes:
       
        if deployed_idx.id == DEPLOYED_INDEX_ID and deployed_idx.index == my_streaming_index.resource_name:
            deployed_index_found = True
            print(f"Streaming Index '{my_streaming_index.display_name}' (ID: {deployed_idx.id}) is deployed on endpoint '{deployed_endpoint.display_name}'.")
            break
    
    if not deployed_index_found:
        raise RuntimeError(f"Error: Index '{my_streaming_index.display_name}' is not deployed on endpoint '{deployed_endpoint.display_name}' with deployed_index_id '{DEPLOYED_INDEX_ID}'. Please deploy it manually.")


    print(f"Endpoint '{deployed_endpoint.display_name}' is ready.")
    global _deployed_endpoint 
    _deployed_endpoint = deployed_endpoint  
    return deployed_endpoint


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
    print(f"\n--- Saving New Query to Cache (Streaming) ---")
    datapoint_id = str(uuid.uuid4())
    embedding_vector = _generate_embedding(query_text)

    firestore_client = get_firestore_client()
    
    expiration_time = datetime.datetime.now(timezone.utc) + timedelta(hours=TTL_DURATION_HOURS)

    metadata_collection_ref = firestore_client.collection(FIRESTORE_COLLECTION_NAME)
    metadata_document = {
        "id": datapoint_id, 
        "text": query_text,
        "sql": sql_query,
        "created_at": firestore.SERVER_TIMESTAMP,
        "expires_at": expiration_time 
    }
    try:
        metadata_collection_ref.document(datapoint_id).set(metadata_document)
        print(f"Metadata for ID '{datapoint_id}' saved to Firestore collection '{FIRESTORE_COLLECTION_NAME}' (expires at {expiration_time}).")
    except Exception as e:
        logging.error(f"Error saving metadata to Firestore for ID '{datapoint_id}': {e}")
        raise


    global _streaming_index 
    if _streaming_index:
        print(f"Upserting datapoint '{datapoint_id}' to streaming index...")
        datapoint = IndexDatapoint(
            datapoint_id=datapoint_id,
            feature_vector=embedding_vector
        )
        try:

            _streaming_index.upsert_datapoints(datapoints=[datapoint]) 
            print(f"Datapoint '{datapoint_id}' upserted to streaming index successfully.")
        except Exception as e:
            print(f"Error upserting datapoint '{datapoint_id}' to streaming index: {e}")
            
    else:
        print("Warning: Streaming index not initialized. Datapoint not upserted. Ensure create_or_get_and_deploy_streaming_vector_search_index() was called and waited for readiness.")
        logging.warning("Streaming index not initialized. Datapoint not upserted. Ensure create_or_get_and_deploy_streaming_vector_search_index() was called and waited for readiness.")
    return datapoint_id

# --- New Function to Remove Expired Datapoints from Streaming Index ---
def _remove_expired_datapoints_from_streaming_index():
    """
    Identifies expired metadata documents in Firestore and removes corresponding
    datapoints from the deployed streaming Vector Search Index. This should be
    scheduled to run periodically (e.g., daily).
    """
    print(f"\n--- Initiating Streaming Index Cleanup (Remove Expired) ---")
    firestore_client = get_firestore_client()
    metadata_collection_ref = firestore_client.collection(FIRESTORE_COLLECTION_NAME)

    expired_datapoint_ids = []
    docs_to_delete_from_firestore = []

    current_time_utc = datetime.datetime.now(timezone.utc)


    print("Checking for expired metadata documents in Firestore...")
    try:

        docs = metadata_collection_ref.where('expires_at', '<', current_time_utc).stream()
        for doc in docs:
            doc_id = doc.id
            expired_datapoint_ids.append(doc_id)
            docs_to_delete_from_firestore.append(doc.reference)
            print(f"  Found expired document: {doc_id} (Expires: {doc.get('expires_at')})")
    except Exception as e:
        print(f"Error querying Firestore for expired documents: {e}")
        logging.error(f"Error querying Firestore for expired documents: {e}")
        return

    if not expired_datapoint_ids:
        print("No expired datapoints found for removal.")
        return



    # --- Streaming Update: Remove Datapoints Directly from the Index ---
    global _deployed_endpoint
    if _deployed_endpoint:
        try:
            print("Removing datapoints from streaming index...")
            _deployed_endpoint.remove_datapoints(
                deployed_index_id=DEPLOYED_INDEX_ID, 
                datapoint_ids=expired_datapoint_ids
            )
            print(f"Removed {len(expired_datapoint_ids)} datapoints from streaming index successfully.")

            # Only delete from Firestore AFTER successful removal from the index
            print(f"Cleaning up {len(docs_to_delete_from_firestore)} documents from Firestore metadata collection...")
            batch = firestore_client.batch()
            for doc_ref in docs_to_delete_from_firestore:
                batch.delete(doc_ref)
            batch.commit()
            print("Expired metadata cleared from Firestore.")

        except Exception as e:
            logging.error(f"Error removing datapoints from streaming index: {e}")
            
    else:
        print("Warning: Streaming endpoint not deployed. Datapoints not removed from index.")
        logging.warning("Streaming endpoint not deployed. Datapoints not removed from index. Ensure create_or_get_and_deploy_streaming_vector_search_index() was called and waited for readiness.")


def retrieve_query(query_text: str, num_results: int = 1) -> List[Dict[str, Any]]:
    """
    Generates an embedding for a query text, performs a nearest neighbor search
    on the streaming index, and then retrieves associated metadata (including 'sql') from Firestore.

    Args:
        query_text: The natural language query to search for.
        num_results: The number of nearest neighbors to retrieve.

    Returns:
        A list of dictionaries, where each dictionary contains the 'id', 'distance',
        'text', and 'sql' of a retrieved similar datapoint.
        Returns an empty list if no neighbors are found or an error occurs.
    """
    global _deployed_endpoint
    if _deployed_endpoint is None:
        print("Error: Vector Search endpoint not initialized. Call setup_cache_environment() first.")
        logging.error("Vector Search endpoint not initialized. Call setup_cache_environment() first.")
        return []


    try:
        query_embedding = _generate_embedding(query_text)

    except Exception as e:
        print(f"Error generating query embedding: {e}")
        logging.error(f"Error generating query embedding: {e}")
        return []

    print(f"Searching for {num_results} neighbors...")
    
    public_endpoint_domain = _deployed_endpoint.public_endpoint_domain_name
    match_client = MatchServiceClient(client_options={"api_endpoint": public_endpoint_domain})

    query_datapoint = IndexDatapoint(
        feature_vector=query_embedding
    )

    query_obj = FindNeighborsRequest.Query(
        datapoint=query_datapoint,
        neighbor_count=num_results,
    )
    
    request = FindNeighborsRequest(
        index_endpoint=_deployed_endpoint.resource_name,
        deployed_index_id=DEPLOYED_INDEX_ID,
        queries=[query_obj] 
    )


    try:
        response = match_client.find_neighbors(request=request)
    except Exception as e:
        print(f"Error performing nearest neighbors search: {e}")
        return []

    results = []
    if response and response.nearest_neighbors:
        found_id = None
        for neighbors_in_query in response.nearest_neighbors:
            for neighbor in neighbors_in_query.neighbors:
                if (neighbor.distance > SIMILARITY_THRESHOLD):
                 found_id = neighbor.datapoint.datapoint_id
                 break

        
        firestore_client = get_firestore_client()
        collection_ref = firestore_client.collection(FIRESTORE_COLLECTION_NAME)
        
  
        doc_refs = collection_ref.document(found_id)
        
        firestore_docs = {}
        if doc_refs:
            try:
                for doc_snapshot in firestore_client.get_all([doc_refs]):
                    if doc_snapshot.exists:
                        expires_at_ts = doc_snapshot.get('expires_at')
                        if expires_at_ts and expires_at_ts.isoformat() < datetime.datetime.now(timezone.utc).isoformat():
                            print(f"  Firestore document {doc_snapshot.id} found but expired. Skipping.")
                            continue
                        firestore_docs[doc_snapshot.id] = doc_snapshot.to_dict()
            except Exception as e:
                print(f"Error retrieving metadata from Firestore: {e}")
                logging.error(f"Error retrieving metadata from Firestore: {e}")
    
        for neighbors_in_query in response.nearest_neighbors:
            for neighbor in neighbors_in_query.neighbors:
                if (neighbor.distance > SIMILARITY_THRESHOLD):
                    found_id = neighbor.datapoint.datapoint_id
                    associated_metadata = firestore_docs.get(found_id)
                    
                    if associated_metadata:
                        return{
                            "id": found_id,
                            "distance": neighbor.distance,
                            "text": associated_metadata.get('text', 'N/A'),
                            "sql": associated_metadata.get('sql', 'N/A')
                        }
                    else:
                        print(f"  ID: {found_id}, Distance: {neighbor.distance} (Metadata not found or expired in Firestore)")

    print(f"No neighbors found for query: '{query_text}'.")
    
    return results
