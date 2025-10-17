import os
from dotenv import load_dotenv

load_dotenv()

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:5000")
CORS_ORIGINS = [
    "http://localhost:3000",  # Frontend
    "http://localhost:8080",  # Alternative
    "http://localhost:5000",  # Backend
]
