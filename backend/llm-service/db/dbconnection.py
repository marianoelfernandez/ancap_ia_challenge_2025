from pocketbase import PocketBase
from pocketbase.models import Record
from threading import Lock
from utils.settings import Settings

class PocketBaseClient:
    _instance = None
    _lock = Lock()
    settings = Settings()
    def __new__(cls, url=settings.pocketbase_url):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super().__new__(cls)
                cls._instance.client = PocketBase(url)
        return cls._instance

    def get_client(self):
        return self.client


def save_query(natural_query: str, query: str, response: dict, cost:int, conversation_id:str) -> Record:
    client = PocketBaseClient().get_client()

    data = {
        "natural_query": natural_query,
        "sql_query": query,
        "output": response,
        "cost": 0.0,  # Placeholder for cost, adjust as needed
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
            if record.get("user_id") == user_id:
                return conversation_id
            else:
                raise RuntimeError(f"Conversation {conversation_id} does not belong to user {user_id}")
        except Exception as e:
            raise RuntimeError(f"Error retrieving conversation: {e}")

def get_role(conversation_id: str) -> str | None:
    try:
        client = PocketBaseClient().get_client()
        conversation = client.collection("conversations").get_one(conversation_id)
        user_id = conversation.get("user_id")
        if not user_id:
            return None
        
        user = client.collection("users").get_one(user_id)
        role = user.get("role")
        return role

    except Exception as e:
        print(f"Error obteniendo rol para conversation_id {conversation_id}: {e}")
        return None