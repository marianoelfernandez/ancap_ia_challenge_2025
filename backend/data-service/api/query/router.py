from typing import List
from fastapi import APIRouter, Body, Depends
from datetime import datetime
import logging

from services.bigquery_service import BigQueryService
from services.data_service import DataService
from models.query.model import SQLQueryRequest, SQLQueryResponse, QueryStatus, QueryMetadata, ValidateQueryResponse, DatasetSchema
from models.data.model import FlChartType
from utils.text_parser import extract_sql_from_text

router = APIRouter(
    tags=["query"]
)

@router.post("/query")
async def execute_sql_query(
    request: SQLQueryRequest,
    bigquery_service: BigQueryService = Depends(BigQueryService),
    data_service: DataService = Depends(DataService)
) -> SQLQueryResponse:
    """
    Execute a SQL query and return results
    """
    try:
        
        # Extract SQL from the request text
        clean_sql = extract_sql_from_text(request.query)
        
        # Execute the query
        raw_results = await bigquery_service.execute_query(
            query=clean_sql,
            timeout=request.timeout,
            limit=request.limit
        )

        start_time = raw_results.get("start_time")
        end_time = raw_results.get("end_time")
        bytes_billed = raw_results.get("bytes_billed", 0)
        estimated_cost = bigquery_service._estimate_cost(bytes_billed)
        job_id = raw_results.get("job_id", "null")

        execution_duration = 0.0
        if start_time and end_time:
            execution_duration = (end_time - start_time).total_seconds()
        
        processed_results = data_service.process_results(raw_results, FlChartType.LINE_CHART); # TODO: add format from request
    
        
        return SQLQueryResponse(
            status=QueryStatus.SUCCESS,
            data=processed_results,
            metadata=QueryMetadata(
                execution_time=execution_duration,
                bytes_processed=bytes_billed,
                query_id=job_id,
                timestamp=datetime.now(),
                cost_estimate=estimated_cost
            )
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


@router.post('/validate')
async def validate_sql_query(
    request: SQLQueryRequest,
    bigquery_service: BigQueryService = Depends(BigQueryService)
) -> ValidateQueryResponse:
    try:
        return await bigquery_service.validate_query(request.query)
    except Exception as e:
        return ValidateQueryResponse(
            status=QueryStatus.ERROR,
            error_message=str(e)
        )

@router.get("/schemas", response_model=List[DatasetSchema])
async def get_bigquery_schemas(
    bigquery_service: BigQueryService = Depends(BigQueryService)
) -> List[DatasetSchema]:
    """
    Get all BigQuery schemas
    """
    return await bigquery_service.get_schemas()