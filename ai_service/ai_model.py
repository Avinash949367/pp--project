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
        self.sessions: Dict[str, Dict[str, Any]] = {}  # session_id -> {'history': list, 'context': dict}

    def preprocess_text(self, text: str) -> list:
        """
        Preprocess text: tokenize, remove stop words, keep alphanumeric.
        """
        tokens = word_tokenize(text.lower())
        filtered = [w for w in tokens if w not in self.stop_words and w.isalnum()]
        return filtered

    def parse_intent(self, text: str) -> dict:
        """
        Parse intent from text using keyword matching on preprocessed tokens.
        """
        self.logger.info(f"Parsing intent for text: {text}")
        preprocessed = self.preprocess_text(text)
        entities = self.extract_entities(text)
        # Calculate match scores for better intent selection
        intent_scores = {}
        for intent_name, intent_data in INTENTS.items():
            score = 0
            for keyword in intent_data['keywords']:
                words = keyword.split()
                if all(word in preprocessed for word in words):
                    score += len(words)
            if score > 0:
                intent_scores[intent_name] = score

        # Boost score for view_slots_filtered if vehicle_type is detected
        if 'vehicle_type' in entities and 'view_slots_filtered' in intent_scores:
            intent_scores['view_slots_filtered'] += 5  # significant bonus to prioritize filtered intent
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

            # Handle filter part for view_slots_filtered
            if best_intent == 'view_slots_filtered':
                filter_parts = []
                if 'city' in entities:
                    filter_parts.append(f" in {entities['city']}")
                if 'vehicle_type' in entities:
                    filter_parts.append(f" for {entities['vehicle_type']}")
                filter_part = ''.join(filter_parts) if filter_parts else ""
                response = response.replace("{filter_part}", filter_part)
            else:
                response = response.replace("{filter_part}", "")

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
        # Extract 'this station' reference first
        if re.search(r'this.*station[s]?', text, re.IGNORECASE) or re.search(r'\bthis\b', text, re.IGNORECASE):
            entities['station'] = 'this'
        else:
            # Extract station name
            station_match = re.search(r'(\w+) station', text, re.IGNORECASE)
            if station_match:
                entities['station'] = station_match.group(1).lower()

        # Extract vehicle type from patterns like "bike slots", "car parking", etc.
        vehicle_patterns = [
            r'\b(bike|car|motorcycle|scooter|truck|vehicle)\b.*\b(slots?|parking)\b',
            r'\b(slots?|parking)\b.*\b(bike|car|motorcycle|scooter|truck|vehicle)\b'
        ]
        for pattern in vehicle_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                # Find the vehicle type in the match groups
                for group in match.groups():
                    if group and group.lower() in ['bike', 'car', 'motorcycle', 'scooter', 'truck', 'vehicle']:
                        entities['vehicle_type'] = group.lower()
                        break
                break

        return entities



    def get_ai_response(self, session_id: str, text: str, token: str = "") -> Dict[str, Any]:
        """
        Orchestrate parsing, response generation, and session history update.
        """
        self.logger.info(f"Getting AI response for session {session_id}: {text}")
        # Initialize session if not exists
        if session_id not in self.sessions:
            self.sessions[session_id] = {'history': [], 'context': {}}

        # Parse intent
        result = self.parse_intent(text)

        # Handle 'this station' reference
        if 'station' in result['entities'] and result['entities']['station'] == 'this':
            last_station = self.sessions[session_id]['context'].get('last_station')
            if last_station:
                result['entities']['station'] = last_station

        # Use history for context (simple example: if unknown and previous was help, suggest again)
        history = self.sessions[session_id]['history']
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
                    city = result['entities'].get('city')
                    if city:
                        self.sessions[session_id]['context']['last_city'] = city
                    # Store the first station as last_station for context
                    if stations:
                        self.sessions[session_id]['context']['last_station'] = stations[0]['stationName'].lower()
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
        elif result['intent'] == 'view_slots':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                slots = proxy_result['data']
                result['data'] = slots
                if slots:
                    # Use last mentioned station if available, else city
                    last_station = self.sessions[session_id]['context'].get('last_station')
                    last_city = self.sessions[session_id]['context'].get('last_city')
                    if last_station:
                        result['response'] = f"Here are the available slots at {last_station} station:"
                    elif last_city:
                        result['response'] = f"Here are the available slots in {last_city}:"
                    else:
                        result['response'] = "Here are the available slots:"
                    result['action'] = 'display'
                    result['screen'] = 'slots'
                else:
                    result['response'] = "No slots available."
            else:
                result['response'] = "Failed to fetch slots."
        elif result['intent'] == 'view_slots_filtered':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                slots = proxy_result['data']
                result['data'] = slots
                if slots:
                    result['action'] = 'display'
                    result['screen'] = 'slots'
                else:
                    result['response'] = "No slots available matching your criteria."
            else:
                result['response'] = "Failed to fetch slots."
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
        self.sessions[session_id]['history'].append({'user': text, 'response': result['response']})
        # Keep last 10
        self.sessions[session_id]['history'] = self.sessions[session_id]['history'][-10:]

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
            elif intent['intent'] == 'view_slots':
                # Fetch slots for a specific station
                entities = intent.get('entities', {})
                station_id = entities.get('station', 'ST001')  # Default to ST001 if not specified

                # Handle 'this' station reference
                if station_id == 'this':
                    last_station = self.sessions.get(session_id, {}).get('context', {}).get('last_station')
                    if last_station:
                        # Find station by name
                        response = requests.get(f"{BACKEND_URL}/api/stations")
                        response.raise_for_status()
                        all_stations = response.json()
                        station = next((s for s in all_stations if s.get('stationName') and isinstance(s['stationName'], str) and s['stationName'].lower() == last_station.lower()), None)
                        if station:
                            station_id = station['stationId']
                        else:
                            return {'status': 'error', 'message': f'Last station {last_station} not found'}
                    else:
                        return {'status': 'error', 'message': 'No previous station context available'}

                # If station is mentioned by name, find its ID
                elif station_id != 'ST001' and not station_id.startswith('ST'):
                    response = requests.get(f"{BACKEND_URL}/api/stations")
                    response.raise_for_status()
                    all_stations = response.json()
                    station = next((s for s in all_stations if s.get('stationName') and isinstance(s['stationName'], str) and s['stationName'].lower().startswith(station_id.split()[0])), None)
                    if station:
                        station_id = station['stationId']
                    else:
                        return {'status': 'error', 'message': f'Station {station_id} not found'}

                # Fetch slots using the station ID
                slots_response = requests.get(f"{BACKEND_URL}/api/slots/station/{station_id}")
                slots_response.raise_for_status()
                slots = slots_response.json()
                self.logger.info(f"Successfully fetched {len(slots)} slots for station {station_id}")
                return {'status': 'success', 'data': slots}
            elif intent['intent'] == 'view_slots_filtered':
                # Fetch filtered slots based on city and vehicle type
                entities = intent.get('entities', {})
                city = entities.get('city')
                vehicle_type = entities.get('vehicle_type')

                # Fetch stations by city if specified
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

                if not stations:
                    return {'status': 'success', 'data': []}

                # For each station, fetch slots and filter by vehicle_type if specified
                all_filtered_slots = []
                for station in stations:
                    station_id = station.get('stationId')
                    if station_id:
                        try:
                            slots_response = requests.get(f"{BACKEND_URL}/api/slots/station/{station_id}")
                            slots_response.raise_for_status()
                            slots = slots_response.json()
                            # Filter by vehicle_type if specified
                            if vehicle_type:
                                slots = [slot for slot in slots if slot.get('type', '').lower() == vehicle_type.lower()]
                            # Add station info to slots for context
                            for slot in slots:
                                slot['stationName'] = station.get('stationName', 'Unknown')
                                slot['stationAddress'] = station.get('address', 'Unknown')
                            all_filtered_slots.extend(slots)
                        except Exception as e:
                            self.logger.warning(f"Failed to fetch slots for station {station_id}: {e}")

                self.logger.info(f"Successfully fetched {len(all_filtered_slots)} filtered slots")
                return {'status': 'success', 'data': all_filtered_slots}
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
