from google.cloud import bigquery
from google.cloud.exceptions import BadRequest
from typing import Dict, Any, List, Optional
import logging
from datetime import datetime
from itertools import groupby
from config.settings import get_settings
from models.query.model import QueryStatus, ValidateQueryResponse, DatasetSchema

settings = get_settings()

class BigQueryService:
    def __init__(self, project_id: str = settings.GCP_DATA_PROJECT_ID, dataset_id: str = settings.GCP_DATA_DATASET_ID):
        """Initialize BigQuery service with project configuration"""
        self.client = bigquery.Client(project=project_id)
        self.project_id = project_id or self.client.project
        self.logger = logging.getLogger(__name__)
        self.dataset_id = dataset_id
        self.logger.info(f"BigQueryService initialized with project_id: {project_id}")
        
    async def execute_query(
        self, 
        query: str, 
        timeout: Optional[int] = 30,
        limit: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Execute a SQL query and return results with metadata
        """
        try:

            self.logger.info(f"\nReceived query: {query}\n")
           
            # Configure query job
            job_config = bigquery.QueryJobConfig()
            
            # Set timeout
            if timeout:
                job_config.job_timeout_ms = timeout * 1000

            # Add LIMIT clause if specified and not already present
            if limit and 'LIMIT' not in query.upper():
                query = f"{query.rstrip(';')} LIMIT {limit}"
            
            # Start query job
            self.logger.info(f"Executing query: {query}")
            query_job = self.client.query(query, job_config=job_config)
            
            # Wait for completion
            results = query_job.result(timeout=timeout)
            
            # Convert results to list of dictionaries
            rows = []
            columns = []
            
            if results.total_rows and results.total_rows > 0:
                # Get column information
                for field in results.schema:
                    columns.append({
                        'name': field.name,
                        'type': field.field_type,
                        'mode': field.mode,
                        'description': field.description
                    })
                
                # Get row data
                for row in results:
                    row_dict = {}
                    for i, value in enumerate(row):
                        column_name = columns[i]['name']
                        row_dict[column_name] = self._serialize_value(value)
                    rows.append(row_dict)
            
            # Collect job statistics
            job_stats = query_job._properties.get('statistics', {})
            query_stats = job_stats.get('query', {})
            
            return {
                'rows': rows,
                'columns': columns,
                'total_rows': results.total_rows,
                'bytes_processed': int(query_stats.get('totalBytesProcessed', 0)),
                'bytes_billed': int(query_stats.get('totalBytesBilled', 0)),
                'slot_ms': int(query_stats.get('totalSlotMs', 0)),
                'creation_time': query_job.created,
                'start_time': query_job.started,
                'end_time': query_job.ended,
                'job_id': query_job.job_id,
            }
            
        except BadRequest as e:
            self.logger.error(f"Invalid query: {str(e)}")
            raise ValueError(f"Invalid SQL query: {str(e)}")
        except Exception as e:
            self.logger.error(f"Query execution error: {str(e)}")
            raise
    
    async def validate_query(self, query: str) -> ValidateQueryResponse:
        """
        Validate a SQL query using BigQuery's dry run feature
        """
        try:
            job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
            query_job = self.client.query(query, job_config=job_config)
            
            # Get statistics from dry run
            job_stats = query_job._properties.get('statistics', {})
            query_stats = job_stats.get('query', {})
            
            bytes_processed = int(query_job.total_bytes_processed)
            
            # Get referenced tables
            referenced_tables = []
            if 'referencedTables' in query_stats:
                for table_ref in query_stats['referencedTables']:
                    table_name = f"{table_ref['projectId']}.{table_ref['datasetId']}.{table_ref['tableId']}"
                    referenced_tables.append(table_name)
            
            return ValidateQueryResponse(
                status=QueryStatus.SUCCESS,
                estimated_bytes=bytes_processed,
                estimated_cost=self._estimate_cost(bytes_processed),
                tables_referenced=referenced_tables
            )
            
        except BadRequest as e:
            return ValidateQueryResponse(
                status=QueryStatus.INVALID_SQL,
                error_message=str(e),
            )

    async def get_schemas(self) -> List[DatasetSchema]:
        """
        Retrieves all tables and their schemas from a specific BigQuery dataset.
        """
        try:
            self.logger.info(f"Fetching schemas for dataset: {self.dataset_id} in project: {self.project_id}")
            
            sql = f"""
                SELECT table_name, column_name, data_type
                FROM `{self.project_id}.{self.dataset_id}.INFORMATION_SCHEMA.COLUMNS`
                ORDER BY table_name, ordinal_position
            """

            self.logger.info(f"Executing query: {sql}")
            
            query_job = self.client.query(sql)
            results = query_job.result()

            
            tables = []
            for table_name, columns in groupby(results, key=lambda r: r.table_name):
                
                schema_info = [
                    {
                        "name": col.column_name,
                        "type": col.data_type,
                    }
                    for col in columns
                ]

                tables.append({
                    "table_id": table_name,
                    "schema": schema_info
                })
            
            dataset_schema = DatasetSchema(
                dataset_id=f"{self.project_id}.{self.dataset_id}",
                tables=tables
            )
            
            self.logger.info(f"Successfully fetched schema for dataset: {self.dataset_id}")
            return [dataset_schema]

        except Exception as e:
            self.logger.error(f"Error fetching schemas: {str(e)}")
            raise

    def _estimate_cost(self, bytes_processed: int) -> float:
        """Estimate query cost based on bytes processed
        
        BigQuery pricing (on-demand):
        - $6.25 per TiB (1,099,511,627,776 bytes)
        - First 1 TiB per month is free
        - All calculations are in USD
        """
        # Convert bytes to TiB (1 TiB = 1024^4 bytes)
        tib_processed = bytes_processed / (1024 ** 4)
        cost_usd = tib_processed * 6.25
        
        return round(cost_usd, 4)
    
    def _serialize_value(self, value: Any) -> Any:
        """Serialize BigQuery values to JSON-compatible format"""
        if value is None:
            return None
        elif isinstance(value, datetime):
            return value.isoformat()
        elif isinstance(value, (list, tuple)):
            return [self._serialize_value(item) for item in value]
        elif isinstance(value, dict):
            return {k: self._serialize_value(v) for k, v in value.items()}
        else:
            return value