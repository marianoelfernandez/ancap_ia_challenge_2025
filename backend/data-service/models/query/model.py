from pydantic import BaseModel, Field, field_validator
from typing import List, Dict, Any, Optional
from datetime import datetime
from enum import Enum


class QueryStatus(str, Enum):
    SUCCESS = "success"
    ERROR = "error"
    TIMEOUT = "timeout"
    INVALID_SQL = "invalid_sql"


# Request Models
class SQLQueryRequest(BaseModel):
    query: str = Field(..., description="SQL query to execute", min_length=1)
    limit: Optional[int] = Field(default=1000, ge=1, le=10000, description="Maximum number of rows to return")
    timeout: Optional[int] = Field(default=30, ge=5, le=300, description="Query timeout in seconds")
    parameters: Optional[Dict[str, Any]] = Field(default={}, description="Query parameters for parameterized queries")
    metadata: Optional[Dict[str, Any]] = Field(default={}, description="Additional metadata for the query")
    
    @field_validator('query')
    @classmethod
    def validate_sql_query(cls, v):
        dangerous_keywords = ['DROP', 'DELETE', 'TRUNCATE', 'UPDATE', 'ALTER', 'CREATE', 'INSERT']
        upper_query = v.upper()
        for keyword in dangerous_keywords:
            if keyword in upper_query:
                raise ValueError(f"Dangerous SQL keyword '{keyword}' is not allowed")
            
        if 'SELECT' not in upper_query:
            raise ValueError("Query must contain a SELECT statement")
        
        if 'FROM' not in upper_query:
            raise ValueError("Query must contain a FROM statement")
        
        return v

class BatchQueryRequest(BaseModel):
    queries: List[SQLQueryRequest] = Field(..., description="List of SQL queries to execute")
    parallel: bool = Field(default=False, description="Execute queries in parallel")

class QueryMetadata(BaseModel):
    execution_time: float 
    rows_processed: Optional[int] = None
    bytes_processed: Optional[int] = None
    query_id: str
    timestamp: datetime
    cost_estimate: Optional[float] = None

class SQLQueryResponse(BaseModel):
    status: QueryStatus
    data: Optional[Dict[str, Any]] = None
    metadata: Optional[QueryMetadata] = None
    error_message: Optional[str] = None
    suggestions: Optional[List[str]] = None


class ValidateQueryResponse(BaseModel):
    status: QueryStatus
    estimated_bytes: Optional[int] = None
    estimated_cost: Optional[float] = None
    tables_referenced: Optional[List[str]] = None
    error_message: Optional[str] = None
    suggestions: Optional[List[str]] = None


class BatchQueryResponse(BaseModel):
    results: List[SQLQueryResponse]
    overall_status: QueryStatus
    total_execution_time: float
    successful_queries: int
    failed_queries: int

class ColumnSchema(BaseModel):
    name: str
    type: str
    mode: str
    description: Optional[str] = None

class TableSchema(BaseModel):
    table_id: str
    schema: List[ColumnSchema]

class DatasetSchema(BaseModel):
    dataset_id: str
    tables: List[TableSchema]