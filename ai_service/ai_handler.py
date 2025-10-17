from typing import Dict, Any
from ai_model import AIModel

class AIHandler:
    def __init__(self):
        self.model = AIModel()

    def process_text(self, text: str, session_id: str = "default", token: str = "") -> Dict[str, Any]:
        """
        Process user input text using the AI model with session context.
        """
        return self.model.get_ai_response(session_id, text, token)
