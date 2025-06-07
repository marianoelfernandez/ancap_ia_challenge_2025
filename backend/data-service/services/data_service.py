from typing import List, Dict, Any
import logging

from models.data.model import FlChartType


class DataService:
    """Service for processing and transforming query results into frontend-friendly formats"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)


    def process_results(self, raw_results: Dict[str, Any], type: FlChartType) -> Dict[str, Any]:

        try:
            rows = raw_results.get('rows', [])
            columns = raw_results.get('columns', [])

            return self._process_line_chart(rows, columns)
        except Exception as e:
            self.logger.error(f"Error processing results: {e}")
            raise e
        
    def _process_line_chart(self, rows: List[Dict[str, Any]], columns: List[Dict[str, Any]]) -> Dict[str, Any]:
        return {
            "data": rows,
            "columns": columns
        }