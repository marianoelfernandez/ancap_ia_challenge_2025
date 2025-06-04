from fastapi import APIRouter, Body, Depends
from datetime import datetime
import logging

from services.bigquery_service import BigQueryService
from models.query.model import QueryRequest, SQLQueryResponse, QueryStatus, QueryMetadata

router = APIRouter(
    tags=["query"]
)


@router.post("/query")
async def execute_sql_query(
    request: QueryRequest,
    bigquery_service: BigQueryService = Depends(BigQueryService)
) -> SQLQueryResponse:
    """
    Execute a SQL query and return results
    """
    try:
        start_time = datetime.now()
        
        # Execute the query
        raw_results = await bigquery_service.execute_query(
            query=request.sql_query,
            timeout=30,
            limit=1000
        )
        
        # Process results based on requested format
        
        execution_time = (datetime.now() - start_time).total_seconds()
        
        
        
        return SQLQueryResponse(
            status=QueryStatus.SUCCESS,
            data=[raw_results]
        )
        
    except ValueError as e:
        return SQLQueryResponse(
            status=QueryStatus.INVALID_SQL,
            metadata=QueryMetadata(
                execution_time=0,
                rows_processed=0,
                query_id=f"error_{int(datetime.now().timestamp())}",
                timestamp=datetime.now()
            ),
            error_message=str(e),
            suggestions=["Check your SQL syntax", "Ensure all table names are correct"]
        )
    except TimeoutError:
        return SQLQueryResponse(
            status=QueryStatus.TIMEOUT,
            metadata=QueryMetadata(
                execution_time= -1,
                rows_processed=0,
                query_id=f"timeout_{int(datetime.now().timestamp())}",
                timestamp=datetime.now()
            ),
            error_message="Query execution timed out",
            suggestions=["Try reducing the dataset size", "Add more specific WHERE clauses"]
        )
    except Exception as e:
        logging.error(f"Query execution error: {str(e)}")
        return SQLQueryResponse(
            status=QueryStatus.ERROR,
            metadata=QueryMetadata(
                execution_time=0,
                rows_processed=0,
                query_id=f"error_{int(datetime.now().timestamp())}",
                timestamp=datetime.now()
            ),
            error_message="Internal server error occurred",
            suggestions=["Contact support if the issue persists"]
        )

