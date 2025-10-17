from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from ai_handler import AIHandler

app = FastAPI(title="Park-Pro AI Service", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost:\d+",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize AI Handler
ai_handler = AIHandler()

class ProcessRequest(BaseModel):
    text: str

class ChatRequest(BaseModel):
    text: str
    session_id: str
    token: str = ""

class ProcessIntentRequest(BaseModel):
    intent: dict

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "AI Service is running"}

@app.post("/process")
def process_text(request: ProcessRequest):
    result = ai_handler.process_text(request.text)
    return result

@app.post("/chat")
def chat(request: ChatRequest):
    result = ai_handler.process_text(request.text, request.session_id, request.token)
    return result

@app.post("/process_intent")
def process_intent(request: ProcessIntentRequest):
    result = ai_handler.model.proxy_to_backend(request.intent)
    return result
