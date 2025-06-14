import json
import time
from typing import List, Dict, Any, Optional

# Google Cloud SDK imports
import vertexai
from google.cloud import storage
from google.cloud.aiplatform.matching_engine import MatchingEngineIndex
from google.cloud.aiplatform.matching_engine import MatchingEngineIndexEndpoint
from google.cloud.aiplatform.matching_engine import MatchingEngineIndexConfig
from config.settings import get_settings
# For generating embeddings with gemini-embedding-001
from google import generativeai as genai
from google.generativeai.types import EmbedContentConfig

settings = get_settings()
# --- Configuration ---
# REPLACE THESE WITH YOUR ACTUAL VALUES
PROJECT_ID = settings.GCP_DATA_PROJECT_ID  # Your Google Cloud Project ID
LOCATION = "southamerica-east1"            # Region for Vertex AI services
GCS_BUCKET_NAME = settings.GCS_BUCKET_NAME # A unique GCS bucket name (must be globally unique)

# Embedding Model Configuration
EMBEDDING_MODEL_NAME = "gemini-embedding-001"
EMBEDDING_TASK_TYPE = "RETRIEVAL_DOCUMENT" # Choose appropriate task_type
EMBEDDING_DIMENSIONS = 768 # Output dimension for gemini-embedding-001, can be adjusted. Default is 3072.

# Vector Search Index Configuration
INDEX_DISPLAY_NAME = "ancap_equipo2_index"
INDEX_DESCRIPTION = "Vertex AI Vector Search index for text embeddings"
DEPLOYED_INDEX_ID = "my_text_embeddings_deployment" # Unique ID for the deployed index on the endpoint
MACHINE_TYPE = "n1-standard-16" # Machine type for the deployed index (adjust based on traffic)
MIN_REPLICA_COUNT = 1
MAX_REPLICA_COUNT = 1

# --- Initialize Vertex AI ---
def initialize_vertex_ai():
    """Initializes the Vertex AI SDK with project and location."""
    print(f"Initializing Vertex AI for project: {PROJECT_ID} in location: {LOCATION}")
    vertexai.init(project=PROJECT_ID, location=LOCATION)

# --- Embedding Generation Function ---
def generate_embedding(text: str) -> List[float]:
    """
    Generates a single embedding for a given text using Vertex AI's Gemini Embedding model.
    """
    print(f"Generating embedding for text: '{text[:50]}...'")
    try:
        client = genai.Client() # Initialize the generative AI client
        response = client.models.embed_content(
            model=EMBEDDING_MODEL_NAME,
            contents=text,
            config=EmbedContentConfig(
                task_type=EMBEDDING_TASK_TYPE,
                output_dimensionality=EMBEDDING_DIMENSIONS # Specify desired output dimension
            ),
        )
        if response.embeddings and response.embeddings[0].values:
            print("Embedding generated successfully.")
            return response.embeddings[0].values
        else:
            raise ValueError("No embedding values found in the response.")
    except Exception as e:
        print(f"Error generating embedding for text '{text[:50]}...': {e}")
        raise

# --- Data Preparation for Vector Search ---
def prepare_vector_search_data(
    data: List[Dict[str, str]],
    output_jsonl_path: str
) -> None:
    """
    Prepares data in JSONL format suitable for Vertex AI Vector Search.
    Generates embeddings for each text item.

    Args:
        data: A list of dictionaries, where each dict has at least an 'id' and 'text' key.
        output_jsonl_path: The local path to save the generated JSONL file.
    """
    print(f"Preparing data for Vector Search and generating embeddings...")
    embeddings_data_for_jsonl = []
    for item in data:
        item_id = item["id"]
        item_text = item["text"]
        try:
            embedding_vector = generate_embedding(item_text)
            embeddings_data_for_jsonl.append({
                "id": item_id,
                "embedding": embedding_vector,
                # Add optional 'restricts' or 'numeric_restricts' here if needed
                # For example: "restricts": [{"namespace": "category", "allow_list": ["news"]}]
            })
            print(f"  Processed item ID: {item_id}")
        except Exception as e:
            print(f"  Skipping item ID {item_id} due to embedding error: {e}")

    with open(output_jsonl_path, 'w') as f:
        for entry in embeddings_data_for_jsonl:
            f.write(json.dumps(entry) + '\n')
    print(f"Prepared {len(embeddings_data_for_jsonl)} embeddings and saved to {output_jsonl_path}")

# --- Upload to Google Cloud Storage ---
def upload_to_gcs(bucket_name: str, source_file_name: str, destination_blob_name: str) -> str:
    """
    Uploads a file to a Google Cloud Storage bucket.

    Args:
        bucket_name: The name of the GCS bucket.
        source_file_name: The path to the local file to upload.
        destination_blob_name: The desired path/name of the blob in GCS.

    Returns:
        The GCS URI of the uploaded file.
    """
    print(f"Uploading {source_file_name} to gs://{bucket_name}/{destination_blob_name}...")
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file_name)
    gcs_uri = f"gs://{bucket_name}/{destination_blob_name}"
    print(f"File uploaded successfully to {gcs_uri}")
    return gcs_uri

# --- Create and Deploy Vector Search Index ---
def create_and_deploy_vector_search_index(
    gcs_input_uri: str
) -> MatchingEngineIndexEndpoint:
    """
    Creates a Vertex AI Vector Search index and deploys it to an endpoint.

    Args:
        gcs_input_uri: The GCS URI of the JSONL file containing the embeddings.

    Returns:
        The deployed MatchingEngineIndexEndpoint object.
    """
    print(f"\n--- Creating and Deploying Vector Search Index ---")

    # Define the index configuration
    index_config = MatchingEngineIndexConfig(
        dimensions=EMBEDDING_DIMENSIONS,
        approximate_nearest_neighbor_config=MatchingEngineIndexConfig.ApproximateNearestNeighborConfig(
            leaf_node_embedding_count=500, # Recommended 500 for smaller datasets, adjust for larger
            leaf_nodes_to_search_percent=7, # Adjust for recall vs. latency tradeoff
        )
    )

    # Create the index
    print(f"Creating index '{INDEX_DISPLAY_NAME}' from {gcs_input_uri}...")
    my_index = MatchingEngineIndex.create_and_deploy_index(
        display_name=INDEX_DISPLAY_NAME,
        contents_delta_uri=gcs_input_uri,
        matching_engine_index_config=index_config,
        sync=True, # Wait for index creation to complete
        description=INDEX_DESCRIPTION,
    )
    print(f"Index '{my_index.display_name}' created (Resource Name: {my_index.resource_name})")

    # Create or get an existing index endpoint
    print(f"Creating or retrieving index endpoint...")
    try:
        # Attempt to create a new endpoint
        my_endpoint = MatchingEngineIndexEndpoint.create(
            display_name=f"{INDEX_DISPLAY_NAME}-endpoint",
            public_endpoint_enabled=True, # Set to False if you only need private network access
            project=PROJECT_ID,
            location=LOCATION
        )
        print(f"Endpoint '{my_endpoint.display_name}' created (Resource Name: {my_endpoint.resource_name})")
    except Exception as e:
        # If creation fails (e.g., endpoint with same name exists), try to retrieve it
        print(f"Could not create endpoint directly, attempting to retrieve existing: {e}")
        endpoints = MatchingEngineIndexEndpoint.list(filter=f'display_name="{INDEX_DISPLAY_NAME}-endpoint"')
        if endpoints:
            my_endpoint = endpoints[0]
            print(f"Retrieved existing endpoint '{my_endpoint.display_name}' (Resource Name: {my_endpoint.resource_name})")
        else:
            raise Exception("Failed to create or retrieve index endpoint.")

    # Deploy the index to the endpoint
    print(f"Deploying index '{my_index.display_name}' to endpoint '{my_endpoint.display_name}'...")
    my_endpoint.deploy_index(
        index=my_index,
        deployed_index_id=DEPLOYED_INDEX_ID,
        machine_type=MACHINE_TYPE,
        min_replica_count=MIN_REPLICA_COUNT,
        max_replica_count=MAX_REPLICA_COUNT,
        sync=True # Wait for deployment to complete
    )
    print(f"Index '{my_index.display_name}' deployed to endpoint '{my_endpoint.display_name}' successfully!")
    return my_endpoint

# --- Query Vector Search Index ---
def query_vector_search(
    endpoint: MatchingEngineIndexEndpoint,
    query_text: str,
    num_neighbors: int = 5
) -> None:
    """
    Generates an embedding for a query text and performs a nearest neighbor search.

    Args:
        endpoint: The deployed MatchingEngineIndexEndpoint object.
        query_text: The text to query for.
        num_neighbors: The number of nearest neighbors to retrieve.
    """
    print(f"\n--- Querying Vector Search Index ---")
    print(f"Generating embedding for query: '{query_text}'")
    try:
        query_embedding = generate_embedding(query_text)
    except Exception as e:
        print(f"Failed to generate query embedding: {e}")
        return

    print(f"Searching for {num_neighbors} neighbors...")
    response = endpoint.find_neighbors(
        deployed_index_id=DEPLOYED_INDEX_ID,
        queries=[query_embedding],
        num_neighbors=num_neighbors,
        # query_restricts=[
        #     MatchingEngineIndexEndpoint.QueryRestrict(namespace="category", allow_list=["news"])
        # ] # Example: add query restrictions if you used them during data prep
    )

    if response and response[0].neighbors:
        print(f"Found neighbors for query '{query_text}':")
        for neighbor in response[0].neighbors:
            print(f"  ID: {neighbor.id}, Distance: {neighbor.distance}")
    else:
        print(f"No neighbors found for query '{query_text}'.")

# --- Main Execution ---
if __name__ == "__main__":
    # Ensure you've set your PROJECT_ID, LOCATION, and GCS_BUCKET_NAME above!
    if PROJECT_ID == "your-gcp-project-id" or GCS_BUCKET_NAME == "your-unique-gcs-bucket-name":
        print("ERROR: Please update PROJECT_ID, LOCATION, and GCS_BUCKET_NAME in the script before running.")
        exit()

    initialize_vertex_ai()

    # 1. Sample Data (replace with your actual data)
    sample_documents = [
        {"id": "doc_1", "text": "The quick brown fox jumps over the lazy dog."},
        {"id": "doc_2", "text": "A cat naps peacefully on the windowsill, enjoying the sun."},
        {"id": "doc_3", "text": "Machine learning algorithms are transforming industries."},
        {"id": "doc_4", "text": "Data science involves statistical analysis and programming."},
        {"id": "doc_5", "text": "The dog eagerly chases the squirrel up the tree."},
        {"id": "doc_6", "text": "Artificial intelligence is a rapidly evolving field."},
        {"id": "doc_7", "text": "Deep learning models require vast amounts of data."},
        {"id": "doc_8", "text": "A furry friend curled up on the couch for a long sleep."},
        {"id": "doc_9", "text": "Natural language processing focuses on human language understanding."},
        {"id": "doc_10", "text": "Software development involves writing, testing, and maintaining code."}
    ]

    local_embeddings_jsonl_file = "embeddings_data.jsonl"
    gcs_embeddings_blob_path = "vector_search_data/embeddings_data.jsonl" # Path within your GCS bucket

    # 2. Prepare data (generate embeddings and save to JSONL)
    prepare_vector_search_data(sample_documents, local_embeddings_jsonl_file)

    # 3. Upload JSONL to GCS
    gcs_input_uri = upload_to_gcs(GCS_BUCKET_NAME, local_embeddings_jsonl_file, gcs_embeddings_blob_path)

    # 4. Create and Deploy Vector Search Index
    # NOTE: This step can take a significant amount of time (10-30+ minutes or more)
    # depending on data size and resource availability.
    print("\nStarting index creation and deployment. This may take a while...")
    start_time = time.time()
    deployed_endpoint = create_and_deploy_vector_search_index(gcs_input_uri)
    end_time = time.time()
    print(f"Index creation and deployment took: {end_time - start_time:.2f} seconds.")

    # 5. Query the deployed index
    print("\n--- Testing Queries ---")
    query_vector_search(deployed_endpoint, "animals playing outdoors")
    query_vector_search(deployed_endpoint, "latest advancements in AI technologies")
    query_vector_search(deployed_endpoint, "coding and software engineering")

