# park-pro-website

## Project Structure
- `backend/`: Node.js API server (stations, bookings, etc.) - Handles all database operations
- `park-pro-application/`: Flutter mobile app
- `ai_service/`: Python AI assistant service (FastAPI) - Uses Node.js backend for all database operations via HTTP proxy
- `frontend/`: Web frontend (HTML/CSS/JS)

## Running the Services
1. **Backend (Node.js)**: `cd backend && npm install && npm start` (runs on port 5000)
2. **AI Service (Python)**: `cd ai_service && python -m venv venv && venv\Scripts\activate.bat && pip install -r requirements.txt && python run.py` (runs on port 8000)
3. **Flutter App**: `cd park-pro-application && flutter pub get && flutter run`

### Setup Notes
- Copy `ai_service/.env.example` to `ai_service/.env` and add your OpenAI API key.
- Ensure Node.js backend is running before starting AI service (for proxying).
- For development, run services in separate terminals.

## AI Service Expansion Guide
The AI service is designed for easy expansion. To add new intents/entities:

1. **Add Intents**: Edit `ai_service/intents.py` - Add to INTENTS dict with keywords, action, screen, params.
2. **Add Entities**: Add regex to ENTITY_RULES in `intents.py`.
3. **Add Responses**: Add to RESPONSE_TEMPLATES.
4. **Backend Proxy**: Add cases in `ai_model.py` proxy_to_backend() for new intents.
5. **Test**: Use curl to test new intents via /chat and /process_intent.

Future: Upgrade to ML classifier (scikit-learn) for better accuracy.
