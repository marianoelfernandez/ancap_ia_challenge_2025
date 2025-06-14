import json
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
# Assuming 'settings' is available and correctly configured
from config.settings import get_settings 
settings = get_settings()

# --- Configuration (Global Constants) ---
PROJECT_ID = settings.GCP_PROJECT_ID
LOCATION = "southamerica-east1"
GCS_BUCKET_NAME = settings.GCS_BUCKET_NAME 

EMBEDDING_MODEL_NAME = "gemini-embedding-001"
EMBEDDING_TASK_TYPE = "RETRIEVAL_DOCUMENT" 
EMBEDDING_DIMENSIONS = 768 

INDEX_DISPLAY_NAME = "ancap_equipo2_cache"
INDEX_DESCRIPTION = "Vertex AI Vector Search index for text embeddings"
ENDPOINT_DISPLAY_NAME = "ancap_equipo2_query_index-endpoint" 
DEPLOYED_INDEX_ID = "cache_index5" # Unique ID for this deployment on the endpoint
MACHINE_TYPE = "n1-standard-16" 
MIN_REPLICA_COUNT = 1
MAX_REPLICA_COUNT = 1
APPROXIMATE_NEIGHBORS_COUNT = 150 
DISTANCE_MEASURE_TYPE = "DOT_PRODUCT_DISTANCE" 

FIRESTORE_DATABASE_NAME = "vector-metadata" 
FIRESTORE_COLLECTION_NAME = "vector_search_metadata" 
FIRESTORE_STAGING_COLLECTION_NAME = "embeddings_for_index_update" 

TTL_DURATION_HOURS = 24  # 1 day TTL for cache entries

# --- Global Variables for Initialized Components ---
_embedding_model: Optional[TextEmbeddingModel] = None
_firestore_client: Optional[firestore.Client] = None
_deployed_endpoint: Optional[MatchingEngineIndexEndpoint] = None

# --- Initialization and Helper Functions ---

def _get_embedding_model() -> TextEmbeddingModel:
    """Gets or initializes the TextEmbeddingModel."""
    global _embedding_model
    if _embedding_model is None:
        vertexai.init(project=PROJECT_ID, location=LOCATION)
        _embedding_model = TextEmbeddingModel.from_pretrained(EMBEDDING_MODEL_NAME)
    return _embedding_model

def _get_firestore_client() -> firestore.Client:
    """Gets or initializes the Firestore client."""
    global _firestore_client
    if _firestore_client is None:
        _firestore_client = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE_NAME)
    return _firestore_client

def _generate_embedding(text: str) -> List[float]:
    """Helper to generate a single embedding."""
    model = _get_embedding_model() # Use the globally initialized model
    try:
        embedding_input = TextEmbeddingInput(
            text=text, 
            task_type=EMBEDDING_TASK_TYPE
        )
        embeddings = model.get_embeddings([embedding_input], output_dimensionality=EMBEDDING_DIMENSIONS)
        if embeddings and embeddings[0].values:
            return embeddings[0].values
        else:
            raise ValueError("No se encontraron valores de incrustación en la respuesta.")
    except Exception as e:
        print(f"Error generando incrustación para el texto '{text[:50]}...': {e}")
        raise

def _upload_to_gcs(bucket_name: str, source_file_name: str, destination_blob_name: str) -> str:
    """Carga un archivo a un bucket de Google Cloud Storage."""
    print(f"Cargando {source_file_name} a gs://{bucket_name}/{destination_blob_name}...")
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file_name)
    gcs_uri = f"gs://{bucket_name}/{destination_blob_name}"
    print(f"Archivo cargado exitosamente a {gcs_uri}")
    return gcs_uri

def _create_or_get_and_deploy_vector_search_index(gcs_input_uri: str) -> MatchingEngineIndexEndpoint:
    """
    Checks if a Vector Search index exists and is deployed. If not, it creates
    and deploys a new one.

    Args:
        gcs_input_uri: The GCS URI to the initial data for index creation.

    Returns:
        The deployed MatchingEngineIndexEndpoint object.
    """
    print(f"Checking for existing index '{INDEX_DISPLAY_NAME}'...")
    my_index = None
    try:
        indexes = MatchingEngineIndex.list(filter=f'display_name="{INDEX_DISPLAY_NAME}"')
        if indexes:
            my_index = indexes[0]
            print(f"Found existing index: '{my_index.resource_name}'")
        else:
            print(f"Index '{INDEX_DISPLAY_NAME}' not found. Creating a new one...")
            my_index = MatchingEngineIndex.create_tree_ah_index(
                display_name=INDEX_DISPLAY_NAME,
                description=INDEX_DESCRIPTION,
                contents_uri=gcs_input_uri,
                dimensions=EMBEDDING_DIMENSIONS,
                approximate_neighbors_count=APPROXIMATE_NEIGHBORS_COUNT,
                distance_measure_type=DISTANCE_MEASURE_TYPE,
                labels={"cache_example": "true"},
                sync=True,  # Wait for index creation to complete
            )
            print(f"Index '{my_index.display_name}' created: {my_index.resource_name}")

    except Exception as e:
        print(f"Error creating/getting index: {e}")
        raise

    print(f"Checking for existing endpoint '{ENDPOINT_DISPLAY_NAME}'...")
    deployed_endpoint = None
    try:
        endpoints = MatchingEngineIndexEndpoint.list(filter=f'display_name="{ENDPOINT_DISPLAY_NAME}"')
        if endpoints:
            deployed_endpoint = endpoints[0]
            print(f"Found existing endpoint: '{deployed_endpoint.resource_name}'")
        else:
            print(f"Endpoint '{ENDPOINT_DISPLAY_NAME}' not found. Creating a new one...")
            deployed_endpoint = MatchingEngineIndexEndpoint.create(
                display_name=ENDPOINT_DISPLAY_NAME,
                description="Endpoint for Vertex AI Vector Search cache example",
                network=None, # Or specify your VPC network if applicable
                labels={"cache_example": "true"},
                sync=True,
            )
            print(f"Endpoint '{deployed_endpoint.display_name}' created: {deployed_endpoint.resource_name}")

    except Exception as e:
        print(f"Error creating/getting endpoint: {e}")
        raise

    # Check if the index is already deployed on this endpoint
    if DEPLOYED_INDEX_ID not in [d.id for d in deployed_endpoint.deployed_indexes]:
        print(f"Deploying index '{my_index.display_name}' to endpoint '{deployed_endpoint.display_name}' with ID '{DEPLOYED_INDEX_ID}'...")
        try:
            deployed_endpoint.deploy_index(
                index=my_index,
                deployed_index_id=DEPLOYED_INDEX_ID,
                machine_type=MACHINE_TYPE,
                min_replica_count=MIN_REPLICA_COUNT,
                max_replica_count=MAX_REPLICA_COUNT,
                sync=True,  # Wait for deployment to complete
            )
            print(f"Index '{DEPLOYED_INDEX_ID}' deployed successfully.")
        except exceptions.Conflict as e:
            print(f"Index '{DEPLOYED_INDEX_ID}' is already being deployed or exists on the endpoint: {e}")
            # If conflict, try to fetch the deployed index to ensure it's ready
            deployed_endpoint.wait_for_resource_ready()
        except Exception as e:
            print(f"Error deploying index: {e}")
            raise
    else:
        print(f"Index '{DEPLOYED_INDEX_ID}' already deployed on endpoint '{deployed_endpoint.display_name}'.")

    deployed_endpoint.wait_for_resource_ready() # Ensure endpoint is ready for queries
    return deployed_endpoint


# --- 1. Clean Function to Save a New Query to Cache ---
def save_query(query_text: str, sql_query: str) -> str:
    """
    Saves a new query and its corresponding SQL to Firestore metadata,
    and stages its embedding for a future Vector Search index update.
    Includes a TTL expiration timestamp.

    Args:
        query_text: The natural language query.
        sql_query: The SQL query corresponding to the natural language query.

    Returns:
        The unique datapoint ID generated for this entry.
    """
    print(f"\n--- Saving New Query to Cache ---")
    datapoint_id = str(uuid.uuid4())

    print(f"Generating embedding for query: '{query_text}'")
    embedding_vector = _generate_embedding(query_text)

    firestore_client = _get_firestore_client()
    
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
        print(f"Error saving metadata to Firestore for ID '{datapoint_id}': {e}")
        raise

    staging_collection_ref = firestore_client.collection(FIRESTORE_STAGING_COLLECTION_NAME)
    staging_document = {
        "id": datapoint_id,
        "embedding": embedding_vector,
        "staged_at": firestore.SERVER_TIMESTAMP
    }
    try:
        staging_collection_ref.document(datapoint_id).set(staging_document)
        print(f"Embedding for ID '{datapoint_id}' staged in Firestore collection '{FIRESTORE_STAGING_COLLECTION_NAME}'.")
    except Exception as e:
        print(f"Error staging embedding to Firestore for ID '{datapoint_id}': {e}")
        raise

    return datapoint_id

# --- 2. Clean Function to Retrieve SQL from Cache ---
def retrieve_query(query_text: str, num_results: int = 1) -> List[Dict[str, Any]]:
    """
    Generates an embedding for a query text, performs a nearest neighbor search,
    and then retrieves associated metadata (including 'sql') from cache (Firestore).

    Args:
        query_text: The natural language query to search for.
        num_results: The number of nearest neighbors to retrieve.

    Returns:
        A list of dictionaries, where each dictionary contains the 'id', 'distance',
        'text', and 'sql' of a retrieved similar datapoint.
        Returns an empty list if no neighbors are found or an error occurs.
    """
    if _deployed_endpoint is None:
        print("Error: Vector Search endpoint not initialized. Call setup_cache_environment() first.")
        return []

    print(f"\n--- Retrieving Query from Cache ---")
    print(f"Generating embedding for query: '{query_text}'")
    try:
        query_embedding = _generate_embedding(query_text)
    except Exception as e:
        print(f"Error generating query embedding: {e}")
        return []

    print(f"Searching for {num_results} neighbors...")
    
    public_endpoint_domain = _deployed_endpoint.public_endpoint_domain_name
    match_client = MatchServiceClient(client_options={"api_endpoint": public_endpoint_domain})

    query_datapoint = IndexDatapoint(
        datapoint_id="query",
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
        found_ids = []
        for neighbors_in_query in response.nearest_neighbors:
            for neighbor in neighbors_in_query.neighbors:
                found_ids.append(neighbor.datapoint_id)
        
        firestore_client = _get_firestore_client()
        collection_ref = firestore_client.collection(FIRESTORE_COLLECTION_NAME)
        
        doc_refs = [collection_ref.document(id_val) for id_val in found_ids]
        
        firestore_docs = {}
        if doc_refs:
            try:
                for doc_snapshot in firestore_client.get_all(doc_refs):
                    if doc_snapshot.exists:
                        # Optional: Client-side check for TTL, though Firestore TTL handles deletion
                        expires_at = doc_snapshot.get('expires_at')
                        if expires_at and expires_at.date() < datetime.datetime.now(timezone.utc).date():
                             print(f"  Firestore document {doc_snapshot.id} found but expired. Skipping.")
                             continue
                        firestore_docs[doc_snapshot.id] = doc_snapshot.to_dict()
            except Exception as e:
                print(f"Error retrieving metadata from Firestore: {e}")
        
        for neighbors_in_query in response.nearest_neighbors:
            for neighbor in neighbors_in_query.neighbors:
                found_id = neighbor.datapoint_id
                associated_metadata = firestore_docs.get(found_id)
                
                if associated_metadata:
                    results.append({
                        "id": found_id,
                        "distance": neighbor.distance,
                        "text": associated_metadata.get('text', 'N/A'),
                        "sql": associated_metadata.get('sql', 'N/A')
                    })
                else:
                    print(f"  ID: {found_id}, Distance: {neighbor.distance} (Metadata not found or expired in Firestore)")
    else:
        print(f"No neighbors found for query: '{query_text}'.")
    
    return results

# --- Function to Trigger Batch Index Update ---
def trigger_batch_index_update() -> Optional[str]:
    """
    Reads new embeddings from the Firestore staging collection,
    writes them to a GCS delta file, and triggers an incremental
    update for the Vertex AI Vector Search Index.
    """
    print(f"\n--- Initiating Batch Index Update Process ---")
    firestore_client = _get_firestore_client()
    staging_collection_ref = firestore_client.collection(FIRESTORE_STAGING_COLLECTION_NAME)

    new_embeddings_data = []
    docs_to_delete_refs = []

    print(f"Fetching new embeddings from Firestore staging collection '{FIRESTORE_STAGING_COLLECTION_NAME}'...")
    try:
        docs = staging_collection_ref.stream()
        for doc in docs:
            data = doc.to_dict()
            if 'id' in data and 'embedding' in data:
                new_embeddings_data.append({
                    "id": data["id"],
                    "embedding": data["embedding"]
                })
                docs_to_delete_refs.append(doc.reference)
            else:
                print(f"Skipping malformed staged document: {doc.id}")
    except Exception as e:
        print(f"Error reading from Firestore staging collection: {e}")
        return None

    if not new_embeddings_data:
        print("No new embeddings found in staging collection. No index update needed.")
        return None

    print(f"Found {len(new_embeddings_data)} new embeddings to process.")

    timestamp = int(time.time())
    local_delta_file = f"embeddings_delta_{timestamp}.json"
    
    with open(local_delta_file, 'w') as f:
        for entry in new_embeddings_data:
            f.write(json.dumps(entry) + '\n')
    print(f"New embeddings written to local delta file: {local_delta_file}")

    gcs_delta_blob_path = f"vector_search_data/deltas/embeddings_delta_{timestamp}.json"
    gcs_delta_uri = _upload_to_gcs(GCS_BUCKET_NAME, local_delta_file, gcs_delta_blob_path)
    
    os.remove(local_delta_file)
    print(f"Local delta file '{local_delta_file}' removed.")

    print(f"Attempting to update Vector Search index '{INDEX_DISPLAY_NAME}' with delta from '{gcs_delta_uri}'...")
    try:
        my_index = None
        indexes = MatchingEngineIndex.list(filter=f'display_name="{INDEX_DISPLAY_NAME}"')
        if indexes:
            my_index = indexes[0]
            print(f"Found existing index: '{my_index.resource_name}'")
        else:
            print(f"Error: Index '{INDEX_DISPLAY_NAME}' not found. Cannot update.")
            return None

        my_index.update_tree_ah_index(
            contents_delta_uri=gcs_delta_uri,
            sync=True 
        )
        print(f"Vector Search Index '{INDEX_DISPLAY_NAME}' updated successfully from '{gcs_delta_uri}'.")

        print(f"Cleaning up {len(docs_to_delete_refs)} documents from Firestore staging collection...")
        batch = firestore_client.batch()
        for doc_ref in docs_to_delete_refs:
            batch.delete(doc_ref)
        batch.commit()
        print("Staged embeddings cleared from Firestore.")

    except exceptions.FailedPrecondition as e:
        print(f"Index update failed due to precondition (e.g., another update in progress): {e}")
    except Exception as e:
        print(f"An unexpected error occurred during index update: {e}")
        return None
    
    return gcs_delta_uri


# --- Main Execution ---
if __name__ == "__main__":
    print(PROJECT_ID, LOCATION, GCS_BUCKET_NAME)
    if PROJECT_ID == "your-gcp-project-id" or GCS_BUCKET_NAME == "your-unique-gcs-bucket-name":
        print("ERROR: Update PROJECT_ID, LOCATION, and GCS_BUCKET_NAME in the script before running.")
        exit()

    # --- Setup Cache Environment (ONE-TIME or on application start) ---
    print("\n--- Setting Up Cache Environment ---")
    start_time = time.time()
    
    # 1. Prepare initial data for index creation (if index needs to be created)
    # This simulates your initial dataset for the cache.
    sample_documents = [
        {"id": "doc_1", "text": "The quick brown fox jumps over the lazy dog.", "sql": "SELECT * FROM animals WHERE species = 'fox'"},
        {"id": "doc_2", "text": "A cat naps peacefully on the windowsill, enjoying the sun.", "sql": "SELECT name, breed FROM pets WHERE type = 'cat'"},
        {"id": "doc_10", "text": "animals playing outdoor", "sql": "SELECT activity, location FROM wildlife WHERE behavior = 'playing' AND environment = 'outdoor'"},
        {"id": "doc_11", "text": "animals playing outside", "sql": "SELECT * FROM nature_activities WHERE category = 'animal_play'"},
        {"id": "doc_20", "text": "Retrieve customer names and their order counts.", "sql": "SELECT c.name, COUNT(o.order_id) FROM customers c JOIN orders o ON c.customer_id = o.customer_id GROUP BY c.name;"},
        {"id": "doc_21", "text": "Find products with more than 100 units in stock.", "sql": "SELECT product_name FROM products WHERE stock_quantity > 100;"},
        {"id": "doc_22", "text": "Show me all employees hired after 2020.", "sql": "SELECT employee_name, hire_date FROM employees WHERE hire_date > '2020-01-01';"}
    ]
    
    initial_embeddings_jsonl_file = "initial_embeddings_data.json" 
    gcs_initial_embeddings_blob_path = "vector_search_data/initial_embeddings_data.json" 

    # This helper internally uses _get_embedding_model() and _get_firestore_client()
    def _prepare_initial_vector_search_data(data: List[Dict[str, str]], output_jsonl_path: str) -> None:
        print(f"Preparing initial data for Vector Search and Firestore...")
        embeddings_data_for_jsonl = []
        firestore_client_local = _get_firestore_client() # Get client for this local scope
        metadata_collection_ref = firestore_client_local.collection(FIRESTORE_COLLECTION_NAME)

        for item in data:
            item_id = item["id"]
            item_text = item["text"]
            item_sql = item.get("sql", None) 
            try:
                embedding_vector = _generate_embedding(item_text)
                embeddings_data_for_jsonl.append({"id": item_id, "embedding": embedding_vector})
                
                expiration_time = datetime.datetime.now(timezone.utc) + timedelta(hours=TTL_DURATION_HOURS)
                metadata_document = {
                    "id": item_id, 
                    "text": item_text, 
                    "sql": item_sql,
                    "created_at": firestore.SERVER_TIMESTAMP,
                    "expires_at": expiration_time
                }
                metadata_collection_ref.document(item_id).set(metadata_document)
                print(f"  Initial item ID: {item_id} processed.")
            except Exception as e:
                print(f"  Skipping initial item ID {item_id} due to error: {e}")

        with open(output_jsonl_path, 'w') as f:
            for entry in embeddings_data_for_jsonl:
                f.write(json.dumps(entry) + '\n')
        print(f"Initial embeddings data saved to {output_jsonl_path} and metadata to Firestore.")

    _prepare_initial_vector_search_data(sample_documents, initial_embeddings_jsonl_file)
    gcs_initial_input_uri = _upload_to_gcs(GCS_BUCKET_NAME, initial_embeddings_jsonl_file, gcs_initial_embeddings_blob_path)
    print(f"Initial data uploaded to GCS at: {gcs_initial_input_uri}")
    
    # 2. Deploy or retrieve the Vector Search Index Endpoint
    # This will set the global _deployed_endpoint
    _deployed_endpoint = _create_or_get_and_deploy_vector_search_index(gcs_initial_input_uri)
    
    end_time = time.time()
    print(f"Cache environment setup took: {end_time - start_time:.2f} seconds.")

    # --- Test Core Cache Functions ---
    
    print("\n\n--- Testing `save_query` ---")
    new_query_text_1 = "what are the details for employee onboarding?"
    new_sql_query_1 = "SELECT * FROM hr.employees WHERE status = 'onboarding';"
    new_id_1 = save_query(new_query_text_1, new_sql_query_1)
    print(f"Saved new query with ID: {new_id_1}")

    new_query_text_2 = "how much stock is available for popular items?"
    new_sql_query_2 = "SELECT product_name, stock_quantity FROM products WHERE popularity_score > 0.8;"
    new_id_2 = save_query(new_query_text_2, new_sql_query_2)
    print(f"Saved new query with ID: {new_id_2}")

    print("\n--- Testing `retrieve_query` (BEFORE index update) ---")
    # New data added above will NOT be found by Vector Search yet.
    results_before_update = retrieve_query(query_text="employee onboarding steps", num_results=1)
    if results_before_update:
        print(f"Results for 'employee onboarding steps' (before update): {results_before_update}")
    else:
        print("No results found for 'employee onboarding steps' (as expected before index update).")

    # --- Manually Trigger Batch Update (simulating a scheduled job) ---
    print("\n\n--- Manually Triggering Batch Index Update ---")
    print("This simulates a scheduled job that updates the Vector Search index.")
    
    time.sleep(5) # Give a moment for Firestore writes to propagate
    
    delta_uri = trigger_batch_index_update()
    if delta_uri:
        print(f"Batch index update initiated using GCS delta: {delta_uri}")
        print(f"Propagation takes time (approx. {MACHINE_TYPE} replica_count {MIN_REPLICA_COUNT}-{MAX_REPLICA_COUNT}). Please wait 5-15 minutes or more...")
        # IMPORTANT: In a real app, you'd monitor the index operation, not just sleep.
        time.sleep(300) # Wait for 5 minutes (adjust based on your index size and region)
    else:
        print("No index update was triggered (no new data staged).")

    # --- Test `retrieve_query` (AFTER index update) ---
    print("\n--- Testing `retrieve_query` (AFTER index update) ---")
    
    results_after_update = retrieve_query(query_text="employee onboarding steps", num_results=1)
    if results_after_update:
        print(f"\nRetrieved results for 'employee onboarding steps' (AFTER update):")
        for res in results_after_update:
            print(f"  ID: {res['id']}, Distance: {res['distance']:.4f}, Text: '{res['text']}', SQL: '{res['sql']}'")
    else:
        print("Still no results found for 'employee onboarding steps' (propagation might take longer or query mismatch).")

    results_after_update_2 = retrieve_query(query_text="popular product stock levels", num_results=1)
    if results_after_update_2:
        print(f"\nRetrieved results for 'popular product stock levels' (AFTER update):")
        for res in results_after_update_2:
            print(f"  ID: {res['id']}, Distance: {res['distance']:.4f}, Text: '{res['text']}', SQL: '{res['sql']}'")
    else:
        print("Still no results found for 'popular product stock levels' (propagation might take longer or query mismatch).")

    print("\n--- Cleanup instructions remain the same ---")
    # Remember to uncomment and use cleanup code if you want to delete resources.