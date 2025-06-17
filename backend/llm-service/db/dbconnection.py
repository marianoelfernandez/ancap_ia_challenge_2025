from pocketbase import PocketBase
from pocketbase.models import Record
from pocketbase.errors import ClientResponseError
from pocketbase.models.utils.list_result import ListResult
from threading import Lock
from utils.settings import Settings
from typing import cast
from langchain.memory import ConversationBufferMemory
from langchain.schema import HumanMessage, AIMessage
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


def save_query(natural_query: str, query: str, response: dict, cost:int, conversation_id:str, queried_tables: list[str]) -> Record:
    client = PocketBaseClient().get_client()

    data = {
        "natural_query": natural_query,
        "sql_query": query,
        "output": response,
        "cost": cost,
        "conversation_id": conversation_id,
        "queried_tables": queried_tables
    }

    try:
        record = client.collection("queries").create(data)
        return record
    except Exception as e:
        raise RuntimeError(f"Error saving query to PocketBase: {e}")
    
def check_or_generate_conversation_id(
    user_id: str, 
    conversation_id: str | None, 
    title: str = "Conversation sin titulo"
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
    
def build_memory_of_conversation(conversation_id: str) -> ConversationBufferMemory:
    """
    Builds a memory of the conversation by retrieving messages from PocketBase.

    Args:
        conversation_id (str): ID of the conversation to retrieve messages for.

    Returns:
        ConversationBufferMemory: Memory object containing the conversation history.
    """
    client = PocketBaseClient().get_client()
    try:
        messages = client.collection("queries").get_list(
            1,10,{
            "filter":f"conversation_id='{conversation_id}'",
            "sort":"-created"
            }
        )
        return parse_memory(messages)
    except Exception as e:
        logger.error(f"Error building memory for conversation {conversation_id}: {e}")
        return ConversationBufferMemory(return_messages=True, memory_key="chat_history")
    
def parse_memory(chat_history_list: ListResult[Record]) -> ConversationBufferMemory:
    messages = []
    for entry in chat_history_list.items:  # Access the items property of ListResult
        query = getattr(entry, "natural_query")
        output = getattr(entry, "output")
        messages.append(HumanMessage(content=query))
        messages.append(AIMessage(content=output))
    memory = ConversationBufferMemory(return_messages=True, memory_key="chat_history")
    memory.chat_memory.messages = messages
    return memory