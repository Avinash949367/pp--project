import re
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from intents import INTENTS, ENTITY_RULES, RESPONSE_TEMPLATES, CITY_CORRECTIONS
from typing import Dict, List, Any
import requests
from config import BACKEND_URL
import logging

class AIModel:
    def __init__(self):
        # Set up logging first
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        try:
            nltk.download('punkt', quiet=True)
        except Exception as e:
            self.logger.warning(f"NLTK punkt download failed (may already exist): {e}")
        try:
            nltk.download('stopwords', quiet=True)
        except Exception as e:
            self.logger.warning(f"NLTK stopwords download failed (may already exist): {e}")
        self.stop_words = set(stopwords.words('english'))
        self.sessions: Dict[str, List[Dict[str, str]]] = {}  # session_id -> list of {'user': text, 'response': response}

    def preprocess_text(self, text: str) -> list:
        """
        Preprocess text: tokenize, remove stop words, keep alphanumeric.
        """
        tokens = word_tokenize(text.lower())
        filtered = [w for w in tokens if w not in self.stop_words and w.isalnum()]
        return filtered

    def parse_intent(self, text: str) -> dict:
        """
        Parse intent from text using preprocessed tokens and keyword matching.
        """
        self.logger.info(f"Parsing intent for text: {text}")
        preprocessed = self.preprocess_text(text)
        entities = self.extract_entities(text)
        # Calculate match scores for better intent selection
        intent_scores = {}
        for intent_name, intent_data in INTENTS.items():
            score = sum(1 for keyword in intent_data['keywords'] if keyword in preprocessed)
            if score > 0:
                intent_scores[intent_name] = score
        if intent_scores:
            # Select intent with highest score
            best_intent = max(intent_scores, key=intent_scores.get)
            intent_data = INTENTS[best_intent]
            self.logger.info(f"Matched intent: {best_intent}, score: {intent_scores[best_intent]}, entities: {entities}")
            response = RESPONSE_TEMPLATES.get(best_intent, "Action completed.")
            # Format response with entities
            if 'city' in entities:
                response = response.replace("{city_part}", f" in {entities['city']}")
            else:
                response = response.replace("{city_part}", "")
            return {
                'intent': best_intent,
                'response': response,
                'action': intent_data['action'],
                'screen': intent_data['screen'],
                'params': intent_data['params'],
                'entities': entities
            }
        # Fallback to unknown
        self.logger.info("No intent matched, returning unknown")
        return {
            'intent': 'unknown',
            'response': RESPONSE_TEMPLATES['unknown'],
            'action': None,
            'screen': None,
            'params': {},
            'entities': entities
        }

    def extract_entities(self, text: str) -> dict:
        """
        Extract entities using regex rules and apply corrections.
        """
        entities = {}
        for entity, regex in ENTITY_RULES.items():
            match = re.search(regex, text, re.IGNORECASE)
            if match:
                value = match.group(1).lower()
                # Apply corrections for cities
                if entity == 'city' and value in CITY_CORRECTIONS:
                    value = CITY_CORRECTIONS[value]
                entities[entity] = value
        return entities



    def get_ai_response(self, session_id: str, text: str, token: str = "") -> Dict[str, Any]:
        """
        Orchestrate parsing, response generation, and session history update.
        """
        self.logger.info(f"Getting AI response for session {session_id}: {text}")
        # Initialize session if not exists
        if session_id not in self.sessions:
            self.sessions[session_id] = []

        # Parse intent
        result = self.parse_intent(text)

        # Use history for context (simple example: if unknown and previous was help, suggest again)
        history = self.sessions[session_id]
        if result['intent'] == 'unknown' and history and 'help' in history[-1]['response'].lower():
            result['response'] = "Still need help? I can assist with booking slots, viewing bookings, etc."

        # If intent is navigate_bookings or display_stations, fetch actual data
        if result['intent'] == 'navigate_bookings' and token:
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                bookings = proxy_result['data']
                result['data'] = bookings
                if bookings:
                    result['response'] = "Here are your bookings:"
                    result['action'] = 'display'
                    result['screen'] = 'bookings'
                else:
                    result['response'] = "You have no bookings yet."
            else:
                result['response'] = "Failed to fetch bookings. Please try again."
        elif result['intent'] == 'display_stations':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                stations = proxy_result['data']
                result['data'] = stations
                if stations:
                    result['response'] = f"Here are the available parking stations in {result['entities'].get('city', 'your area')}:"
                    result['action'] = 'display'
                    result['screen'] = 'stations'
                else:
                    result['response'] = f"No parking stations found in {result['entities'].get('city', 'your area')}."
            else:
                result['response'] = "Failed to fetch stations. Please try again."
        elif result['intent'] == 'cancel_booking':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                result['response'] = proxy_result['data']
            else:
                result['response'] = "Failed to cancel booking."
        elif result['intent'] == 'view_payment_history':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                result['data'] = proxy_result['data']
                result['response'] = "Here is your payment history:"
                result['action'] = 'display'
                result['screen'] = 'payments'
            else:
                result['response'] = "Failed to fetch payment history."
        elif result['intent'] == 'emergency':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                result['data'] = proxy_result['data']
                result['response'] = proxy_result['data']
                result['action'] = 'display'
                result['screen'] = 'emergency'
            else:
                result['response'] = "Failed to fetch emergency contacts."

        # Add to history
        self.sessions[session_id].append({'user': text, 'response': result['response']})
        # Keep last 10
        self.sessions[session_id] = self.sessions[session_id][-10:]

        self.logger.info(f"Response for session {session_id}: {result}")
        return result

    def login_and_get_token(self, email: str, password: str) -> str:
        """
        Login to backend and get JWT token.
        """
        try:
            response = requests.post(f"{BACKEND_URL}/api/auth/login", json={"email": email, "password": password})
            response.raise_for_status()
            data = response.json()
            return data.get('token')
        except Exception as e:
            self.logger.error(f"Login failed: {str(e)}")
            return None

    def proxy_to_backend_with_token(self, intent: Dict[str, Any], token: str, session_id: str = "") -> Dict[str, Any]:
        """
        Proxy request to backend based on intent using provided token.
        """
        self.logger.info(f"Proxying to backend for intent: {intent['intent']} with token")
        try:
            headers = {'Authorization': f'Bearer {token}'}
            if intent['intent'] == 'navigate_search_stations':
                # Fetch stations
                response = requests.get(f"{BACKEND_URL}/api/stations")
                response.raise_for_status()
                data = response.json()
                self.logger.info("Successfully fetched stations")
                return {'status': 'success', 'data': data}
            elif intent['intent'] == 'display_stations':
                # Fetch stations by city if entity present
                city = intent.get('entities', {}).get('city')
                if city:
                    response = requests.get(f"{BACKEND_URL}/api/stations/search/{city}")
                    response.raise_for_status()
                    data = response.json()
                    stations = data.get('stations', [])
                else:
                    # Fetch all stations if no city
                    response = requests.get(f"{BACKEND_URL}/api/stations")
                    response.raise_for_status()
                    stations = response.json()
                self.logger.info(f"Successfully fetched {len(stations)} stations")
                return {'status': 'success', 'data': stations}
            elif intent['intent'] == 'navigate_bookings':
                # Fetch user ID by email (session_id is userEmail)
                user_id = self._fetch_user_id_by_email(session_id)
                if not user_id:
                    return {'status': 'error', 'message': 'User not found'}
                # Fetch bookings by user ID
                response = requests.get(f"{BACKEND_URL}/api/slots/slotbookings/{user_id}")
                response.raise_for_status()
                data = response.json()
                self.logger.info("Successfully fetched bookings")
                bookings_data = data if isinstance(data, list) else []
                return {'status': 'success', 'data': bookings_data}
            elif intent['intent'] == 'cancel_booking':
                # Implement cancel booking logic - placeholder
                return {'status': 'success', 'data': 'Booking cancelled successfully.'}
            elif intent['intent'] == 'view_payment_history':
                # Implement view payment history logic - placeholder
                return {'status': 'success', 'data': 'Payment history fetched.'}
            elif intent['intent'] == 'emergency':
                # Implement emergency contacts logic - placeholder
                return {'status': 'success', 'data': 'Emergency contacts: Police - 100, Ambulance - 108.'}
            # Add more as needed
            else:
                self.logger.warning(f"No proxy for intent: {intent['intent']}")
                return {'status': 'error', 'message': 'No backend proxy for this intent'}
        except requests.RequestException as e:
            self.logger.error(f"Backend request failed: {str(e)}")
            return {'status': 'error', 'message': f'Backend request failed: {str(e)}'}
        except Exception as e:
            self.logger.error(f"Unexpected error: {str(e)}")
            return {'status': 'error', 'message': f'Unexpected error: {str(e)}'}

    def _fetch_user_id_by_email(self, email: str) -> str:
        """
        Fetch user ID by email.
        """
        try:
            response = requests.get(f"{BACKEND_URL}/api/users/email/{email}")
            response.raise_for_status()
            data = response.json()
            return data.get('_id', '')
        except Exception as e:
            self.logger.error(f"Failed to fetch user ID for email {email}: {str(e)}")
            return ''

    def proxy_to_backend(self, intent: Dict[str, Any]) -> Dict[str, Any]:
        """
        Proxy request to backend based on intent.
        """
        self.logger.info(f"Proxying to backend for intent: {intent['intent']}")
        try:
            if intent['intent'] == 'navigate_search_stations':
                # Fetch stations
                response = requests.get(f"{BACKEND_URL}/api/stations")
                response.raise_for_status()
                data = response.json()
                self.logger.info("Successfully fetched stations")
                return {'status': 'success', 'data': data}
            elif intent['intent'] == 'navigate_bookings':
                # Login with provided credentials
                token = self.login_and_get_token("avinash46479@gmail.com", "949367@Sv")
                if not token:
                    return {'status': 'error', 'message': 'Authentication failed'}
                # Fetch user bookings
                headers = {'Authorization': f'Bearer {token}'}
                response = requests.get(f"{BACKEND_URL}/api/user/bookings", headers=headers)
                response.raise_for_status()
                data = response.json()
                self.logger.info("Successfully fetched bookings")
                bookings_data = data.get('bookings', [])
                if not isinstance(bookings_data, list):
                    bookings_data = []
                return {'status': 'success', 'data': bookings_data}
            elif intent['intent'] == 'cancel_booking':
                # Implement cancel booking logic
                return {'status': 'success', 'data': 'Booking cancelled successfully.'}
            elif intent['intent'] == 'view_payment_history':
                # Implement view payment history logic
                return {'status': 'success', 'data': 'Payment history fetched.'}
            elif intent['intent'] == 'emergency':
                # Implement emergency contacts logic
                return {'status': 'success', 'data': 'Emergency contacts: Police - 100, Ambulance - 108.'}
            # Add more as needed
            else:
                self.logger.warning(f"No proxy for intent: {intent['intent']}")
                return {'status': 'error', 'message': 'No backend proxy for this intent'}
        except requests.RequestException as e:
            self.logger.error(f"Backend request failed: {str(e)}")
            return {'status': 'error', 'message': f'Backend request failed: {str(e)}'}
        except Exception as e:
            self.logger.error(f"Unexpected error: {str(e)}")
            return {'status': 'error', 'message': f'Unexpected error: {str(e)}'}
