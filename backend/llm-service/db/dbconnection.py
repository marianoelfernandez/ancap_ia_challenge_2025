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


def save_query(natural_query: str, query: str, response: str, cost:int, conversation_id:str) -> Record:
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
    
def generate_conversation_id(user_id: str, title: str = "Conversation") -> str:
    """
    Creates a new conversation record in PocketBase and returns its ID.
    
    Args:
        user_id (str): The ID of the user who owns the conversation.
        title (str): Optional title for the conversation.
    Returns:
        str: The ID of the newly created conversation.
    """
    client: PocketBase = PocketBaseClient().get_client()

    try:
        record: Record = client.collection("conversations").create({
            "user_id": user_id,
            "conversation": title
        })
        return record.id
    except Exception as e:
        raise RuntimeError(f"Error creating conversation: {e}")


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
    