
import os
from dotenv import find_dotenv, load_dotenv
import openai


class Settings:
    def __init__(self):
        load_dotenv(find_dotenv())
        openai.api_key = os.environ['OPENAI_API_KEY']
        self.mcp_server_uri = os.environ.get('MCP_SERVER_URI')
        