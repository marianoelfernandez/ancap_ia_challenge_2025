import httpx
import time
from typing import List, Dict, Any, Optional
import os
import logging
import asyncio

CACHE_DURATION_SECONDS = 24 * 60 * 60  # 24 hours

logger = logging.getLogger(__name__)

class SchemaClient:
    def __init__(self):
        self._client = httpx.AsyncClient(base_url=os.getenv("MCP_SERVER_URI") or "http://data-service:8001", timeout=httpx.Timeout(None))
        self._cache: Optional[List[Dict[str, Any]]] = None
        self._last_fetched_time: float = 0
        self._lock = asyncio.Lock()

    async def get_schemas(self) -> List[Dict[str, Any]]:
        """
        Fetches all schemas, using a simple in-memory cache to store results for 24 hours.
        """
        # If cache is valid, return it immediately.
        if self._cache is not None:
            logger.info("Returning schemas from in-memory cache.")
            return self._cache

        # Use a lock to prevent multiple concurrent requests from trying to refresh the cache simultaneously.
        async with self._lock:
            # Re-check if cache became valid while waiting for the lock
            if self._cache is not None:
                logger.info("Returning schemas from in-memory cache (after acquiring lock).")
                return self._cache

            logger.info("In-memory cache is invalid or empty. Fetching schemas from data-service...")
            try:
                response = await self._client.get("/schemas")
                response.raise_for_status()
                
                # Update cache and timestamp
                self._cache = response.json()
                self._last_fetched_time = time.time()
                
                logger.info("Successfully fetched and updated in-memory cache for schemas.")

                return self._cache if self._cache is not None else []
            except httpx.RequestError as exc:
                logger.error(f"An error occurred while requesting schemas: {exc!r}")
                return self._cache if self._cache is not None else []
            except httpx.HTTPStatusError as exc:
                logger.error(f"Error response {exc.response.status_code} while fetching schemas.")
                return self._cache if self._cache is not None else []


# Create a singleton instance for use across the application
schema_client = SchemaClient()