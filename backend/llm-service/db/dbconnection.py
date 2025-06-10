from pocketbase import PocketBase
from pocketbase.models import Record
from pocketbase.errors import ClientResponseError
from threading import Lock
from utils.settings import Settings
from typing import cast
import logging

logger = logging.getLogger(__name__)

class PocketBaseClient:
    _instance = None
    _lock = Lock()
    settings = Settings()
    client: PocketBase
    def __new__(cls, url=settings.pocketbase_url):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super().__new__(cls)
                cls._instance.client = PocketBase(cast(str, url))
        return cls._instance

    def get_client(self):
        return self.client


def save_query(natural_query: str, query: str, response: dict, cost:int, conversation_id:str) -> Record:
    client = PocketBaseClient().get_client()

    data = {
        "natural_query": natural_query,
        "sql_query": query,
        "output": response,
        "cost": cost,
        "conversation_id": conversation_id,
    }

    try:
        record = client.collection("queries").create(data)
        return record
    except Exception as e:
        raise RuntimeError(f"Error saving query to PocketBase: {e}")
    
def check_or_generate_conversation_id(
    user_id: str, 
    conversation_id: str | None, 
    title: str = "Conversation"
    ) -> str:
    """
    Checks if conversation_id belongs to user_id; if None, creates a new conversation.

    Args:
        user_id (str): ID of the user who owns the conversation.
        conversation_id (str | None): Conversation ID to check.
        title (str): Optional title for the conversation.

    Returns:
        str: Valid conversation ID.
    """
    client: PocketBase = PocketBaseClient().get_client()

    if conversation_id is None:
        try:
            record: Record = client.collection("conversations").create({
                "user_id": user_id,
                "conversation": title
            })
            return record.id
        except Exception as e:
            raise RuntimeError(f"Error creating conversation: {e}")
    else:
        try:
            record: Record = client.collection("conversations").get_one(conversation_id)
            if getattr(record, "user_id") == user_id:
                return conversation_id
            else:
                raise RuntimeError(f"Conversation {conversation_id} does not belong to user {user_id}")
        except Exception as e:
            raise RuntimeError(f"Error retrieving conversation: {e}")

def get_role(conversation_id: str) -> str | None:
    try:
        client = PocketBaseClient().get_client()
        conversation = client.collection("conversations").get_one(conversation_id)
        user_id = getattr(conversation, "user_id")
        if not user_id:
            return None
        
        user = client.collection("users").get_one(user_id)
        role = getattr(user, "role")
        return role

    except ClientResponseError as e:
        if e.status == 404:
            logger.warning(f"Could not find conversation or user for conversation_id {conversation_id}")
            return None
        logger.error(f"Error getting role for conversation_id {conversation_id}: {e}")
        raise e
    except Exception as e:
        logger.error(f"Error getting role for conversation_id {conversation_id}: {e}")
        return None

def get_user(user_id: str) -> Record | None:
    try:
        client = PocketBaseClient().get_client()
        user = client.collection("users").get_one(user_id)
        return user
    except ClientResponseError as e:
        if e.status == 404:
            logger.warning(f"User with ID {user_id} not found in PocketBase.")
            return None
        logger.error(f"PocketBase error getting user {user_id}: {e}")
        raise e
    except Exception as e:
        logger.error(f"Unexpected error getting user {user_id}: {e}")
        return None