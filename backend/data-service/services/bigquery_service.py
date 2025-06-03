from google.cloud import bigquery
from google.cloud.exceptions import BadRequest
from typing import Dict, Any, Optional
import logging
from datetime import datetime
from app.config.settings import get_settings

settings = get_settings()

class BigQueryService:
    def __init__(self, project_id: str = settings.GCP_PROJECT_ID):
        """Initialize BigQuery service with project configuration"""
        self.client = bigquery.Client(project=project_id)
        self.project_id = project_id or self.client.project
        self.logger = logging.getLogger(__name__)

        self.logger.info(f"BigQueryService initialized with project_id: {project_id}")
        
    async def execute_query(
        self, 
        query: str, 
        timeout: int = 30,
        limit: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Execute a SQL query and return results with metadata
        """
        try:

            self.logger.info(f"Received query: {query}")
            self.logger.info(f"client: {self.client}")
            self.logger.info(f"project_id: {self.project_id}")
            self.logger.info(f"timeout: {timeout}")
            self.logger.info(f"limit: {limit}")
            
            # Configure query job
            job_config = bigquery.QueryJobConfig()
            
            # Set timeout
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
    
    async def validate_query(self, query: str) -> Dict[str, Any]:
        """
        Validate a SQL query using BigQuery's dry run feature
        """
        try:
            job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
            query_job = self.client.query(query, job_config=job_config)
            
            # Get statistics from dry run
            job_stats = query_job._properties.get('statistics', {})
            query_stats = job_stats.get('query', {})
            
            bytes_processed = int(query_stats.get('totalBytesProcessed', 0))
            
            # Get referenced tables
            referenced_tables = []
            if 'referencedTables' in query_stats:
                for table_ref in query_stats['referencedTables']:
                    table_name = f"{table_ref['projectId']}.{table_ref['datasetId']}.{table_ref['tableId']}"
                    referenced_tables.append(table_name)
            
            return {
                'valid': True,
                'estimated_bytes': bytes_processed,
                'tables_referenced': referenced_tables,
                'query_schema': [
                    {
                        'name': field.name,
                        'type': field.field_type,
                        'mode': field.mode
                    }
                    for field in query_job.schema or []
                ]
            }
            
        except BadRequest as e:
            return {
                'valid': False,
                'error': str(e)
            }
    
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