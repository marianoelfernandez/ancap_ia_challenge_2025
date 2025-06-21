
import os
from dotenv import find_dotenv, load_dotenv
import openai


class Settings:
    _instance = None

    @classmethod
    def get_settings(cls):
        """Get cached settings instance."""
        if cls._instance is None:
            cls._instance = Settings()
        return cls._instance
        

    def __init__(self):
        load_dotenv(find_dotenv())
        self.api_key = os.environ['GEMINI_API_KEY']
        self.mcp_server_uri = os.environ.get('MCP_SERVER_URI')
        self.pocketbase_url = os.environ.get('POCKETBASE_URL')
        self.schema = None


            
        