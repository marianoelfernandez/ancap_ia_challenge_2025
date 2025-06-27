from fastapi import APIRouter, Depends, Query
from db.dbconnection import PocketBaseClient
from utils.auth import get_admin_user

router = APIRouter()

@router.get("/queries")
def get_queries(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    admin_user=Depends(get_admin_user),
):
    """
    Retrieves a paginated list of queries from the database.

    - **page**: The page number to retrieve.
    - **per_page**: The number of items per page.
    - **admin_user**: Dependency to ensure the user is an admin.
    """
    client = PocketBaseClient().get_client()
    queries = client.collection("queries").get_list(page, per_page)
    return queries
