import re
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from intents import INTENTS, ENTITY_RULES, RESPONSE_TEMPLATES, CITY_CORRECTIONS
from typing import Dict, List, Any
import requests
from config import BACKEND_URL
import logging
import time
import random
from datetime import datetime

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

        # Human-like behavior settings
        self.thinking_delay = 0.3  # seconds to simulate thinking - reduced for better flow
        self.personality_responses = {
            'greetings': [
                "Hello! I'm your parking assistant in Bangalore. How can I help you find the perfect spot today?",
                "Hi there! Ready to park smart in the city? What can I help you with?",
                "Greetings! I'm here to make parking in Bangalore easier for you. What would you like to know?",
                "Hello! Your friendly parking guide is here. How can I assist you today?"
            ],
            'confirmations': [
                "Got it. Let me handle that for you right away.",
                "Understood. I'll get this sorted out for you.",
                "Perfect. Let me take care of the details.",
                "Alright, I'll make sure everything is set up correctly."
            ],
            'clarifications': [
                "Hmm, I want to make sure I get this right for you. Could you clarify that a bit?",
                "To help you better, could you give me a few more details?",
                "Let me make sure I understand correctly. Could you specify that?",
                "Just to be sure, could you tell me a bit more about what you need?"
            ],
            'apologies': [
                "I apologize for any confusion. Let me help you get this sorted out.",
                "Sorry about that. Let me make sure I understand what you need.",
                "My apologies. Let me get this right for you now."
            ],
            'suggestions': [
                "Based on what you've told me, I think this might work well for you.",
                "From my experience, this option usually works best for most people.",
                "I recommend this choice - it's popular and reliable.",
                "This seems like a good fit for your needs."
            ],
            'empathy': [
                "I understand how frustrating parking can be in the city.",
                "I know finding parking can be stressful - let me help.",
                "Parking in Bangalore can be tricky, but I've got you covered.",
                "I get it - let's find you the best spot quickly."
            ],
            'success': [
                "Great! That's all set up for you.",
                "Perfect! Everything is ready to go.",
                "Excellent! You're all set now.",
                "Wonderful! That should work perfectly for you."
            ]
        }

    def _simulate_thinking(self) -> None:
        """
        Simulate human-like thinking delay.
        """
        time.sleep(self.thinking_delay)

    def _get_personality_response(self, response_type: str) -> str:
        """
        Get a random personality response based on type.
        """
        if response_type in self.personality_responses:
            return random.choice(self.personality_responses[response_type])
        return ""

    def _detect_sentiment(self, text: str) -> str:
        """
        Detect basic sentiment from text using keyword matching.
        Returns 'positive', 'negative', or 'neutral'.
        """
        positive_words = ['good', 'great', 'excellent', 'happy', 'love', 'awesome', 'perfect', 'thanks', 'thank']
        negative_words = ['bad', 'frustrated', 'angry', 'hate', 'terrible', 'annoying', 'stress', 'problem', 'issue']

        text_lower = text.lower()
        if any(word in text_lower for word in negative_words):
            return 'negative'
        elif any(word in text_lower for word in positive_words):
            return 'positive'
        else:
            return 'neutral'

    def _remember_user_preferences(self, session_id: str, entities: dict):
        """
        Remember user preferences for more personalized interactions.
        """
        if 'vehicle_type' in entities:
            self.sessions[session_id]['context']['preferred_vehicle'] = entities['vehicle_type']
        if 'city' in entities:
            self.sessions[session_id]['context']['preferred_city'] = entities['city']

    def _detect_user_frustration(self, text: str) -> bool:
        """
        Detect if user is getting frustrated.
        """
        frustration_indicators = [
            'again', 'still', 'why can\'t', 'not working',
            'frustrated', 'annoying', 'ugh', 'seriously'
        ]
        return any(indicator in text.lower() for indicator in frustration_indicators)

    def _handle_frustrated_user(self, session_id: str, text: str) -> Dict[str, Any]:
        """
        Handle frustrated users with empathy and solutions.
        """
        context = self.sessions[session_id]['context']
        history = self.sessions[session_id]['history']

        # Check if this is repeated frustration
        recent_frustrations = [h for h in history[-3:] if any(word in h['user'].lower() for word in ['again', 'still', 'why can\'t', 'not working', 'frustrated', 'annoying', 'ugh', 'seriously'])]

        if len(recent_frustrations) >= 2:
            # Escalated frustration - offer human assistance
            return {
                'intent': 'unknown',
                'response': "I can see you're having trouble. Let me connect you with a human assistant who can help you directly. Would you like me to arrange that?",
                'action': None,
                'screen': None,
                'params': {},
                'entities': {}
            }
        else:
            # First sign of frustration - show empathy and offer alternatives
            empathy_responses = [
                "I understand this is frustrating. Let me try a different approach to help you.",
                "I'm sorry you're running into issues. Let me see if there's another way I can assist you.",
                "I can tell this isn't working well for you. Let me try something else."
            ]
            return {
                'intent': 'unknown',
                'response': random.choice(empathy_responses),
                'action': None,
                'screen': None,
                'params': {},
                'entities': {}
            }

    def _add_conversational_fillers(self):
        """
        Add human-like conversational fillers occasionally.
        """
        fillers = ["Let me see...", "Hmm...", "Okay...", "Right..."]
        return random.choice(fillers) if random.random() < 0.3 else ""

    def _learn_from_conversation(self, session_id: str, user_input: str, response: str):
        """
        Simple learning mechanism to improve future interactions.
        """
        # Track successful interactions
        if 'thank' in user_input.lower() or 'great' in user_input.lower():
            self.sessions[session_id]['context']['successful_patterns'] = \
                self.sessions[session_id]['context'].get('successful_patterns', [])
            # Store the last successful interaction pattern
            if len(self.sessions[session_id]['history']) >= 2:
                pattern = {
                    'user_input': self.sessions[session_id]['history'][-2]['user'],
                    'response': self.sessions[session_id]['history'][-2]['response']
                }
                self.sessions[session_id]['context']['successful_patterns'].append(pattern)

    def _adjust_personality_based_on_context(self, session_id: str, intent: str) -> str:
        """
        Adjust personality based on context and time of day.
        """
        context = self.sessions[session_id]['context']

        # Time-based greetings
        current_hour = datetime.now().hour
        if intent == 'greet':
            if 5 <= current_hour < 12:
                return random.choice(["Good morning!", "Morning! Ready to find parking?"])
            elif 12 <= current_hour < 17:
                return random.choice(["Good afternoon!", "Afternoon! Need parking help?"])
            else:
                return random.choice(["Good evening!", "Evening! Looking for parking?"])

        # Adjust formality based on user's style
        if context.get('user_formal', True):
            return "formal"
        else:
            return "casual"

    def _resolve_slot_references(self, text: str, session_id: str) -> str:
        """
        Handle natural references like 'the first one', 'that slot', etc.
        """
        context = self.sessions[session_id]['context']
        last_slots = context.get('last_slots', [])

        reference_map = {
            'first': 0, 'second': 1, 'third': 2, 'fourth': 3, 'fifth': 4,
            'last': -1, 'that': -1, 'this': -1, 'the one': -1
        }

        for ref, index in reference_map.items():
            if ref in text.lower():
                if last_slots and abs(index) < len(last_slots):
                    return last_slots[index]['slotId']

        return None

    def _enhance_booking_flow(self, session_id: str, entities: dict) -> str:
        """
        Add more human-like elements to booking flow.
        """
        context = self.sessions[session_id]['context']

        # Check for time conflicts or suggest better times
        if entities.get('start_time'):
            suggested_time = self._suggest_better_time(entities['start_time'])
            if suggested_time != entities['start_time']:
                return f"I see you want {entities['start_time']}. Just so you know, {suggested_time} usually has better availability. Would you like me to check that time instead?"

        # Add reassuring messages for new users
        if context.get('booking_count', 0) == 0:
            return "I'll walk you through your first booking. It's quick and easy!"

        return ""

    def _suggest_better_time(self, time_str: str) -> str:
        """
        Suggest better times based on typical availability patterns.
        """
        # Simple logic: suggest times during off-peak hours
        try:
            dt = datetime.strptime(time_str, '%I:%M%p')
            hour = dt.hour
            if 9 <= hour <= 11 or 17 <= hour <= 19:  # Peak hours
                if hour <= 11:
                    return "8:00 AM"  # Suggest earlier
                else:
                    return "7:00 PM"  # Suggest later
        except:
            pass
        return time_str

    def _should_check_in(self, session_id: str) -> bool:
        """
        Determine if we should check in with the user.
        """
        context = self.sessions[session_id]['context']
        history = self.sessions[session_id]['history']

        # Check if user has been inactive or might need help
        if len(history) > 5 and not any('help' in h['user'].lower() for h in history[-3:]):
            return random.random() < 0.2  # 20% chance to check in

        return False

    def _generate_check_in(self, session_id: str) -> str:
        """
        Generate a friendly check-in message.
        """
        check_ins = [
            "Is there anything else you'd like help with regarding your parking?",
            "Need any other assistance with parking today?",
            "I'm here if you have any other parking questions!",
            "Was that helpful? Is there anything else I can assist with?"
        ]
        return random.choice(check_ins)

    def _detect_ambiguity(self, text: str, entities: dict) -> List[str]:
        """
        Detect ambiguous or missing information in user input.
        Returns list of clarification questions needed.
        """
        clarifications = []

        # Check for vague time references
        if 'time' in text.lower() and not entities.get('start_time') and not entities.get('end_time'):
            if any(word in text.lower() for word in ['evening', 'morning', 'afternoon', 'night']):
                clarifications.append("Could you specify what time exactly? For example, '2:00 PM' or '14:00'.")

        # Check for missing date
        if 'book' in text.lower() and not entities.get('date'):
            clarifications.append("When would you like to book the slot? Please provide a date.")

        # Check for missing location
        if ('slots' in text.lower() or 'parking' in text.lower()) and not entities.get('city') and not entities.get('station'):
            clarifications.append("Which city or parking station are you interested in?")

        # Check for missing vehicle type
        if 'slots' in text.lower() and not entities.get('vehicle_type'):
            clarifications.append("What type of vehicle do you have? (car, bike, etc.)")

        return clarifications

    def _enhance_response_with_personality(self, response: str, intent: str) -> str:
        """
        Add personality and human-like elements to responses.
        """
        # Add thinking simulation
        self._simulate_thinking()

        # For greetings, use personality responses
        if intent == 'unknown' and any(word in response.lower() for word in ['hello', 'hi', 'help']):
            return self._get_personality_response('greetings')

        # Add confirmation language for actions
        if intent in ['book_slot', 'cancel_booking']:
            if 'confirm' in response.lower():
                response = self._get_personality_response('confirmations') + " " + response

        # Add apologetic tone for errors
        if 'failed' in response.lower() or 'error' in response.lower():
            response = self._get_personality_response('apologies') + " " + response

        return response

    def _proactive_questions(self, session_id: str, intent: str, entities: dict) -> str:
        """
        Generate proactive questions to guide users or gather missing info.
        """
        context = self.sessions[session_id]['context']

        # If user just viewed slots, offer to help with booking
        if intent == 'view_slots' and context.get('last_slots'):
            return "I can help you book one of these slots. Which slot number interests you, or would you like me to suggest the best available option?"

        # If user is booking but missing info, be more specific
        if intent == 'book_slot':
            missing = []
            if not entities.get('date'):
                missing.append("date (like 'tomorrow' or '15-12-2024')")
            if not entities.get('start_time'):
                missing.append("start time (like '2:00 PM')")
            if not entities.get('end_time'):
                missing.append("end time (like '5:00 PM')")

            if missing:
                missing_str = ', '.join(missing)
                return f"To book your slot, I'll need the {missing_str}. What would you like to set?"

        # If user seems lost, offer guidance
        if intent == 'unknown':
            return "I'm here to help with parking! I can show you available slots, help you book parking, check your bookings, or find parking stations. What would you like to do?"

        return ""

    def preprocess_text(self, text: str) -> list:
        """
        Preprocess text: tokenize, remove stop words, keep alphanumeric.
        """
        tokens = word_tokenize(text.lower())
        filtered = [w for w in tokens if w not in self.stop_words and w.isalnum()]
        return filtered

    def parse_intent(self, text: str, session_id: str = "") -> dict:
        """
        Parse intent from text using keyword matching on preprocessed tokens.
        Enhanced with session context awareness and better fallback logic.
        """
        self.logger.info(f"Parsing intent for text: {text}")
        preprocessed = self.preprocess_text(text)
        entities = self.extract_entities(text)

        # Debug: Show preprocessing and entities
        self.logger.debug(f"Preprocessed tokens: {preprocessed}")
        self.logger.debug(f"Extracted entities: {entities}")

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

        # Debug: Show initial scores
        self.logger.debug(f"Initial intent scores: {intent_scores}")

        # Context-aware boosting using session information
        if session_id and session_id in self.sessions:
            context = self.sessions[session_id]['context']
            history = self.sessions[session_id]['history']

            # Boost booking-related intents if user was recently discussing slots
            if context.get('last_slots') and any(intent in intent_scores for intent in ['book_slot', 'view_slots']):
                for intent in ['book_slot', 'view_slots']:
                    if intent in intent_scores:
                        intent_scores[intent] += 3
                        self.logger.debug(f"Boosted {intent} due to recent slot context")

            # Boost station-related intents if user was recently viewing stations
            if context.get('last_station') and 'display_stations' in intent_scores:
                intent_scores['display_stations'] += 4
                self.logger.debug("Boosted display_stations due to recent station context")

            # Boost booking intents if user has pending booking
            if context.get('pending_booking') and 'book_slot' in intent_scores:
                intent_scores['book_slot'] += 5
                self.logger.debug("Boosted book_slot due to pending booking")

            # Context from recent conversation
            if history:
                last_response = history[-1]['response'].lower()
                # If last response mentioned slots, boost slot-related intents
                if 'slot' in last_response and any(intent in intent_scores for intent in ['book_slot', 'view_slots', 'view_slots_filtered']):
                    for intent in ['book_slot', 'view_slots', 'view_slots_filtered']:
                        if intent in intent_scores:
                            intent_scores[intent] += 2
                            self.logger.debug(f"Boosted {intent} due to recent slot mention in conversation")

        # Boost score for view_slots_filtered if vehicle_type or city is detected
        if ('vehicle_type' in entities or 'city' in entities) and 'view_slots_filtered' in intent_scores:
            intent_scores['view_slots_filtered'] += 5  # significant bonus to prioritize filtered intent
            self.logger.debug("Boosted view_slots_filtered for entity presence")

        # Boost score for display_stations if "parking stations" or "parking station" is mentioned
        if 'display_stations' in intent_scores and any(word in preprocessed for word in ['parking', 'stations', 'station']):
            intent_scores['display_stations'] += 3  # boost for station-specific queries
            self.logger.debug("Boosted display_stations for station keywords")

        # Boost score for view_slots if "all" is mentioned (prioritize showing all slots over available slots)
        if 'all' in text.lower() and 'view_slots' in intent_scores:
            intent_scores['view_slots'] += 15  # significant bonus to prioritize all slots over available slots
            self.logger.debug("Boosted view_slots for 'all' keyword")

        # Boost score for view_slots if a specific station is mentioned
        if 'station' in entities and entities['station'] not in ['this', 'parking'] and 'view_slots' in intent_scores:
            intent_scores['view_slots'] += 4  # boost for specific station queries
            self.logger.debug("Boosted view_slots for specific station")

        # Penalty for display_stations if "slots" is mentioned (prioritize slot intents)
        if 'slots' in preprocessed and 'display_stations' in intent_scores:
            intent_scores['display_stations'] -= 5  # penalty to avoid showing stations when slots are requested
            self.logger.debug("Penalized display_stations for slots keyword")

        # Boost for view_slots_filtered if "slots" is mentioned
        if 'slots' in preprocessed and 'view_slots_filtered' in intent_scores:
            intent_scores['view_slots_filtered'] += 5  # boost to prioritize slot filtering
            self.logger.debug("Boosted view_slots_filtered for slots keyword")

        # Debug: Show final scores
        self.logger.debug(f"Final intent scores: {intent_scores}")

        if intent_scores:
            # Select intent with highest score
            best_intent = max(intent_scores, key=intent_scores.get)
            intent_data = INTENTS[best_intent]
            self.logger.info(f"Matched intent: {best_intent}, score: {intent_scores[best_intent]}, entities: {entities}")

            # Debug: Show reasoning for selection
            self.logger.debug(f"Selected intent '{best_intent}' with score {intent_scores[best_intent]}")
            self.logger.debug(f"Intent keywords: {intent_data['keywords']}")

            response = RESPONSE_TEMPLATES.get(best_intent, "Action completed.")
            # Format response with entities
            if 'city' in entities:
                response = response.replace("{city_part}", f" in {entities['city']}")
                self.logger.debug(f"Added city to response: {entities['city']}")
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
                self.logger.debug(f"Added filter to response: {filter_part}")
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

        # Enhanced fallback logic for ambiguous cases
        self.logger.info("No intent matched, applying fallback logic")

        # Check for ambiguous patterns that might indicate intent
        fallback_intent = self._determine_fallback_intent(text, preprocessed, entities, session_id)
        if fallback_intent:
            intent_data = INTENTS[fallback_intent]
            self.logger.info(f"Using fallback intent: {fallback_intent}")
            return {
                'intent': fallback_intent,
                'response': RESPONSE_TEMPLATES.get(fallback_intent, "Action completed."),
                'action': intent_data['action'],
                'screen': intent_data['screen'],
                'params': intent_data['params'],
                'entities': entities
            }

        # Default to unknown
        self.logger.info("No intent matched, returning unknown")
        self.logger.debug("No matching intents found, defaulting to unknown")
        return {
            'intent': 'unknown',
            'response': RESPONSE_TEMPLATES['unknown'],
            'action': None,
            'screen': None,
            'params': {},
            'entities': entities
        }

    def _determine_fallback_intent(self, text: str, preprocessed: list, entities: dict, session_id: str = "") -> str:
        """
        Determine fallback intent for ambiguous cases based on context and patterns.
        """
        text_lower = text.lower()

        # Check for booking-related keywords without clear intent
        booking_keywords = ['book', 'reserve', 'schedule', 'rent', 'get']
        if any(word in preprocessed for word in booking_keywords) and any(word in preprocessed for word in ['slot', 'parking', 'space']):
            return 'book_slot'

        # Check for viewing slots
        if any(word in preprocessed for word in ['show', 'see', 'view', 'find', 'available']) and 'slots' in preprocessed:
            return 'view_slots'

        # Check for station queries
        if any(word in preprocessed for word in ['station', 'location', 'place', 'where']) and any(word in preprocessed for word in ['parking', 'park']):
            return 'display_stations'

        # Context-based fallbacks
        if session_id and session_id in self.sessions:
            context = self.sessions[session_id]['context']

            # If user was looking at slots, they might want to book
            if context.get('last_slots') and any(word in preprocessed for word in ['that', 'this', 'it', 'one']):
                return 'book_slot'

            # If user has pending booking, they might be confirming or providing info
            if context.get('pending_booking'):
                return 'book_slot'

        return None

    def extract_entities(self, text: str) -> dict:
        """
        Extract entities using regex rules and apply corrections.
        """
        entities = {}
        # Extract 'this station' reference first
        if re.search(r'this.*station[s]?', text, re.IGNORECASE) or re.search(r'\bthis\b', text, re.IGNORECASE):
            entities['station'] = 'this'
        else:
            # Extract station name
            station_match = re.search(r'(\w+) station', text, re.IGNORECASE)
            if station_match:
                value = station_match.group(1).lower()
                # Avoid setting station to common words like "parking"
                if value not in ['parking']:
                    entities['station'] = value

        # Extract other entities
        for entity, regex in ENTITY_RULES.items():
            match = re.search(regex, text, re.IGNORECASE)
            if match:
                value = match.group(1).lower()
                # Apply corrections for cities
                if entity == 'city' and value in CITY_CORRECTIONS:
                    value = CITY_CORRECTIONS[value]
                # Don't set city if it's the same as station name
                if entity == 'city' and 'station' in entities and value == entities['station']:
                    continue
                entities[entity] = value

        # Extract vehicle type from patterns like "bike slots", "car parking", etc.
        vehicle_patterns = [
            r'\b(bike|car|motorcycle|scooter|truck|van|vehicle)\b.*\b(slots?|parking)\b',
            r'\b(slots?|parking)\b.*\b(bike|car|motorcycle|scooter|truck|van|vehicle)\b',
            r'for (bike|car|motorcycle|scooter|truck|van|vehicle)\b'
        ]
        for pattern in vehicle_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                # Find the vehicle type in the match groups
                for group in match.groups():
                    if group and group.lower() in ['bike', 'car', 'motorcycle', 'scooter', 'truck', 'van', 'vehicle']:
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

        # Fix 1: Integrate sentiment detection early
        sentiment = self._detect_sentiment(text)
        if sentiment == 'negative':
            empathy_msg = self._get_personality_response('empathy')
            # Store empathy context for response enhancement
            self.sessions[session_id]['context']['current_sentiment'] = 'negative'

        # Fix 6: Check for frustration early
        if self._detect_user_frustration(text):
            frustration_response = self._handle_frustrated_user(session_id, text)
            if frustration_response:
                return frustration_response

        # Handle pending booking confirmations and actions first, before parsing intent
        pending_booking = self.sessions[session_id]['context'].get('pending_booking')

        # Handle cancellation at any point
        if text.lower() in ['no', 'cancel', 'nevermind']:
            if pending_booking:
                self.sessions[session_id]['context'].pop('pending_booking', None)
                result = {
                    'intent': 'unknown',
                    'response': "Booking cancelled. Let me know if you need help with anything else.",
                    'action': None,
                    'screen': None,
                    'params': {},
                    'entities': {}
                }
                return result
            else:
                result = {
                    'intent': 'unknown',
                    'response': "Nothing to cancel.",
                    'action': None,
                    'screen': None,
                    'params': {},
                    'entities': {}
                }
                return result

        # Handle booking confirmation
        if text.lower() in ['yes', 'confirm'] and pending_booking and pending_booking.get('awaiting_confirmation'):
            # Move to payment method selection
            result = {
                'intent': 'book_slot',
                'response': f"Booking details: Slot {pending_booking['slot_id']}, Date: {pending_booking['date']}, Time: {pending_booking['start_time']} to {pending_booking['end_time']}. Please choose payment method: 'razorpay' or 'coupon BOOKFREE'.",
                'action': None,
                'screen': None,
                'params': {},
                'entities': pending_booking
            }
            pending_booking['awaiting_confirmation'] = False
            pending_booking['awaiting_payment_method'] = True
            return result

        # Handle payment method selection
        if text.lower() in ['razorpay', 'coupon', 'coupon bookfree'] and pending_booking and pending_booking.get('awaiting_payment_method'):
            if text.lower() == 'razorpay':
                pending_booking['payment_method'] = 'razorpay'
                pending_booking['awaiting_payment_confirmation'] = True
                result = {
                    'intent': 'book_slot',
                    'response': "Please confirm payment with Razorpay (yes/no).",
                    'action': None,
                    'screen': None,
                    'params': {},
                    'entities': {}
                }
            elif text.lower() in ['coupon', 'coupon bookfree']:
                pending_booking['payment_method'] = 'coupon'
                pending_booking['amount_paid'] = 0
                pending_booking['awaiting_payment_confirmation'] = True
                result = {
                    'intent': 'book_slot',
                    'response': "Please confirm using coupon BOOKFREE (yes/no).",
                    'action': None,
                    'screen': None,
                    'params': {},
                    'entities': {}
                }
            return result

        # Handle payment confirmation
        if text.lower() in ['yes', 'confirm'] and pending_booking and pending_booking.get('awaiting_payment_confirmation'):
            # Proceed with booking - directly proxy with book_slot intent
            proxy_result = self.proxy_to_backend_with_token({'intent': 'book_slot', 'entities': pending_booking}, token, session_id)
            if proxy_result['status'] == 'success':
                result = {
                    'intent': 'book_slot',
                    'response': proxy_result['data'],
                    'action': 'book',
                    'screen': None,
                    'params': {},
                    'entities': {}
                }
                # Clear pending booking context
                self.sessions[session_id]['context'].pop('pending_booking', None)
            else:
                result = {
                    'intent': 'book_slot',
                    'response': proxy_result.get('message', "Failed to book slot."),
                    'action': None,
                    'screen': None,
                    'params': {},
                    'entities': {}
                }
            return result

        # Parse intent for new requests
        result = self.parse_intent(text, session_id)

        # 🚨 CRITICAL FIX: Enhanced ambiguity detection for missing location
        if result['intent'] in ['view_slots', 'view_slots_filtered', 'display_stations']:
            if not result['entities'].get('city') and not result['entities'].get('station'):
                # Check if this is a genuine missing location case
                location_keywords = ['in', 'at', 'near', 'around', 'bangalore', 'city']
                has_location_context = any(word in text.lower() for word in location_keywords)

                if not has_location_context:
                    clarifications = self._detect_ambiguity(text, result['entities'])
                    if clarifications:
                        result['intent'] = 'clarification_needed'
                        result['response'] = clarifications[0]
                        result['action'] = None
                        result['screen'] = None
                        return result

        # 🚨 CRITICAL FIX: Integrate user preference memory
        self._remember_user_preferences(session_id, result['entities'])

        # 🚨 CRITICAL FIX: Fill missing entities from user preferences (only for non-ambiguous cases)
        context = self.sessions[session_id]['context']
        if not result['entities'].get('city') and context.get('preferred_city'):
            result['entities']['city'] = context['preferred_city']
        if not result['entities'].get('vehicle_type') and context.get('preferred_vehicle'):
            result['entities']['vehicle_type'] = context['preferred_vehicle']

        # 🚨 CRITICAL FIX: Resolve slot references
        slot_reference = self._resolve_slot_references(text, session_id)
        if slot_reference and not result['entities'].get('slot_id'):
            result['entities']['slot_id'] = slot_reference

        # Handle 'this station' reference
        if 'station' in result['entities'] and result['entities']['station'] == 'this':
            last_station = self.sessions[session_id]['context'].get('last_station')
            if last_station:
                result['entities']['station'] = last_station

        # Check for ambiguities and missing information
        clarifications = self._detect_ambiguity(text, result['entities'])
        if clarifications:
            # If we have clarifications needed, prioritize asking questions
            result['intent'] = 'clarification_needed'
            result['response'] = clarifications[0]  # Ask the first clarification question
            result['action'] = None
            result['screen'] = None
            result['params'] = {}
            # Store the original result for later use
            self.sessions[session_id]['context']['pending_clarification'] = result.copy()
            return result

        # Use history for context (simple example: if unknown and previous was help, suggest again)
        history = self.sessions[session_id]['history']
        if result['intent'] == 'unknown' and history and 'help' in history[-1]['response'].lower():
            result['response'] = "Still need help? I can assist with booking slots, viewing bookings, etc."
        elif result['intent'] == 'unknown':
            # More intelligent unknown handling with proactive suggestions
            proactive_suggestion = self._proactive_questions(session_id, result['intent'], result['entities'])
            if proactive_suggestion:
                result['response'] = proactive_suggestion
            else:
                result['response'] = self._get_personality_response('clarifications') + " I'm here to help with parking! I can show you available slots, help you book parking, check your bookings, or find parking stations. What would you like to do?"

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
                    if stations and stations[0].get('stationName'):
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
                # Filter for available slots only if filter_available is True
                if result.get('params', {}).get('filter_available', False):
                    slots = [slot for slot in slots if slot.get('availability') == 'Free']
                result['data'] = slots
                # Store slots in context for booking reference
                self.sessions[session_id]['context']['last_slots'] = slots
                if slots:
                    # Use last mentioned station if available, else city
                    last_station = self.sessions[session_id]['context'].get('last_station')
                    last_city = self.sessions[session_id]['context'].get('last_city')
                    if last_station:
                        if result.get('params', {}).get('filter_available', False):
                            result['response'] = f"Here are the available slots at {last_station} station:"
                        else:
                            result['response'] = f"Here are all slots at {last_station} station:"
                    elif last_city:
                        if result.get('params', {}).get('filter_available', False):
                            result['response'] = f"Here are the available slots in {last_city}:"
                        else:
                            result['response'] = f"Here are all slots in {last_city}:"
                    else:
                        if result.get('params', {}).get('filter_available', False):
                            result['response'] = "Here are the available slots:"
                        else:
                            result['response'] = "Here are all slots:"
                    result['action'] = 'display'
                    result['screen'] = 'slots'
                else:
                    if result.get('params', {}).get('filter_available', False):
                        result['response'] = "No available slots found."
                    else:
                        result['response'] = "No slots found."
            else:
                result['response'] = "Failed to fetch slots."
        elif result['intent'] == 'view_slots_filtered':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                slots = proxy_result['data']
                # Filter for available slots only
                slots = [slot for slot in slots if slot.get('availability') == 'Free']
                result['data'] = slots
                # Store slots in context for booking reference
                self.sessions[session_id]['context']['last_slots'] = slots
                if slots:
                    result['action'] = 'display'
                    result['screen'] = 'slots'
                else:
                    result['response'] = "No slots available matching your criteria."
            else:
                result['response'] = "Failed to fetch slots."
        elif result['intent'] == 'book_slot':
            entities = result.get('entities', {})
            slot_id = entities.get('slot_id')
            date = entities.get('date')
            start_time = entities.get('start_time')
            end_time = entities.get('end_time')

            # Check if there's a pending booking context
            pending_booking = self.sessions[session_id]['context'].get('pending_booking')

            if pending_booking:
                # Update pending booking with new information
                if date:
                    pending_booking['date'] = date
                if start_time:
                    pending_booking['start_time'] = start_time
                if end_time:
                    pending_booking['end_time'] = end_time

                # Check if we now have all required information
                if pending_booking.get('date') and pending_booking.get('start_time') and pending_booking.get('end_time'):
                    # All info available, ask for payment method
                    result['response'] = f"Booking details: Slot {pending_booking['slot_id']}, Date: {pending_booking['date']}, Time: {pending_booking['start_time']} to {pending_booking['end_time']}. Please choose payment method: 'razorpay' or 'coupon BOOKFREE'."
                    result['action'] = None
                    result['screen'] = None
                    pending_booking['awaiting_payment_method'] = True
                else:
                    # Still missing info
                    missing_info = []
                    if not pending_booking.get('date'):
                        missing_info.append('date')
                    if not pending_booking.get('start_time'):
                        missing_info.append('start time')
                    if not pending_booking.get('end_time'):
                        missing_info.append('end time')

                    missing_str = ', '.join(missing_info)
                    result['response'] = f"To complete your booking, please provide the {missing_str}."
                    result['action'] = None
                    result['screen'] = None
            else:
                # No pending booking, check current entities
                missing_info = []
                if not date:
                    missing_info.append('date')
                if not start_time:
                    missing_info.append('start time')
                if not end_time:
                    missing_info.append('end time')

                if missing_info:
                    # Store partial booking info in session
                    booking_context = {
                        'slot_id': slot_id,
                        'date': date,
                        'start_time': start_time,
                        'end_time': end_time,
                        'awaiting_confirmation': False
                    }
                    self.sessions[session_id]['context']['pending_booking'] = booking_context

                    missing_str = ', '.join(missing_info)
                    result['response'] = f"To complete your booking, please provide the {missing_str}."
                    result['action'] = None
                    result['screen'] = None
                else:
                    # All info available, show confirmation
                    result['response'] = f"Booking details: Slot {slot_id}, Date: {date}, Time: {start_time} to {end_time}. Do you want to confirm this booking? (yes/no)"
                    result['action'] = None
                    result['screen'] = None
                    # Store for confirmation
                    self.sessions[session_id]['context']['pending_booking'] = {
                        'slot_id': slot_id,
                        'date': date,
                        'start_time': start_time,
                        'end_time': end_time,
                        'awaiting_confirmation': True
                    }
        elif result['intent'] == 'emergency':
            proxy_result = self.proxy_to_backend_with_token(result, token, session_id)
            if proxy_result['status'] == 'success':
                result['data'] = proxy_result['data']
                result['response'] = proxy_result['data']
                result['action'] = 'display'
                result['screen'] = 'emergency'
            else:
                result['response'] = "Failed to fetch emergency contacts."

        # 🚨 CRITICAL FIX: Apply personality enhancement to all responses
        result['response'] = self._enhance_response_with_personality(result['response'], result['intent'])

        # 🚨 CRITICAL FIX: Add human-like elements to booking flow
        if result['intent'] == 'book_slot':
            booking_enhancement = self._enhance_booking_flow(session_id, result['entities'])
            if booking_enhancement:
                result['response'] = booking_enhancement + " " + result['response']

        # 🚨 CRITICAL FIX: Add proactive check-ins occasionally
        if self._should_check_in(session_id):
            check_in_msg = self._generate_check_in(session_id)
            result['response'] += f" {check_in_msg}"

        # 🚨 CRITICAL FIX: Learn from successful interactions
        self._learn_from_conversation(session_id, text, result['response'])

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
            elif intent['intent'] == 'book_slot':
                # Get pending booking from session context
                pending_booking = self.sessions.get(session_id, {}).get('context', {}).get('pending_booking', {})

                if not pending_booking or not pending_booking.get('awaiting_payment_method'):
                    return {'status': 'error', 'message': 'No pending booking found'}

                slot_id = pending_booking.get('slot_id')
                date = pending_booking.get('date')
                start_time = pending_booking.get('start_time')
                end_time = pending_booking.get('end_time')
                payment_method = pending_booking.get('payment_method')
                amount_paid = pending_booking.get('amount_paid', 0)

                if not all([slot_id, date, start_time, end_time, payment_method]):
                    return {'status': 'error', 'message': 'Missing booking information'}

                # Check if slot_id is a positional reference (like "1", "2", "slot 1", etc.)
                slot_index = None
                if slot_id.startswith('slot '):
                    try:
                        slot_index = int(slot_id.split()[1]) - 1  # Extract number from "slot X"
                    except (IndexError, ValueError):
                        pass
                else:
                    try:
                        slot_index = int(slot_id) - 1  # Direct number
                    except ValueError:
                        pass

                if slot_index is not None:
                    last_slots = self.sessions.get(session_id, {}).get('context', {}).get('last_slots', [])
                    if 0 <= slot_index < len(last_slots):
                        slot = last_slots[slot_index]
                        slot_object_id = slot['_id']
                        slot_price = slot.get('price', 0)
                        self.logger.info(f"Using slot at position {slot_index + 1}: {slot.get('slotId')}")
                    else:
                        return {'status': 'error', 'message': f'Slot position {slot_id} is out of range. Only {len(last_slots)} slots available.'}
                else:
                    # slot_id is not a positional reference, treat as actual slotId
                    try:
                        # First, find the slot by slotId to get its ObjectId
                        slots_response = requests.get(f"{BACKEND_URL}/api/slots")
                        slots_response.raise_for_status()
                        all_slots = slots_response.json()
                        slot = next((s for s in all_slots if s.get('slotId') == slot_id), None)
                        if not slot:
                            return {'status': 'error', 'message': f'Slot {slot_id} not found'}
                        slot_object_id = slot['_id']
                        slot_price = slot.get('price', 0)
                    except Exception as e:
                        return {'status': 'error', 'message': f'Failed to find slot: {str(e)}'}

                # Fetch user's vehicles to select one for booking
                user_vehicles = self._fetch_user_vehicles(token)
                if not user_vehicles:
                    return {'status': 'error', 'message': 'No vehicles found for user. Please add a vehicle first.'}

                # Select primary vehicle or first vehicle
                selected_vehicle = None
                for vehicle in user_vehicles:
                    if vehicle.get('isPrimary', False):
                        selected_vehicle = vehicle
                        break
                if not selected_vehicle:
                    selected_vehicle = user_vehicles[0]

                vehicle_id = selected_vehicle['_id']
                self.logger.info(f"Selected vehicle for booking: {selected_vehicle.get('number', 'Unknown')}")

                # Parse date and time
                from datetime import datetime, timedelta

                # Parse date (DD-MM-YYYY or DD/MM/YYYY)
                date_parts = date.replace('/', '-').split('-')
                if len(date_parts) == 3:
                    day, month, year = date_parts
                    if len(year) == 2:
                        year = '20' + year
                    booking_date = f'{year}-{month.zfill(2)}-{day.zfill(2)}'
                else:
                    return {'status': 'error', 'message': 'Invalid date format'}

                start_time_24 = self._convert_to_24_hour(start_time)
                end_time_24 = self._convert_to_24_hour(end_time)

                start_datetime = f'{booking_date}T{start_time_24}:00'
                end_datetime = f'{booking_date}T{end_time_24}:00'

                # Calculate duration in hours
                start_dt = datetime.fromisoformat(start_datetime)
                end_dt = datetime.fromisoformat(end_datetime)
                calculated_duration = (end_dt - start_dt).total_seconds() / 3600

                # Validate that end time is after start time
                if calculated_duration <= 0:
                    return {'status': 'error', 'message': 'End time must be after start time'}

                # Calculate amount paid based on payment method
                if payment_method == 'coupon':
                    amount_paid = 0
                elif payment_method == 'razorpay':
                    amount_paid = slot_price * calculated_duration
                else:
                    return {'status': 'error', 'message': 'Invalid payment method'}

                # Create booking data
                booking_data = {
                    'slotId': slot_object_id,
                    'bookingStartTime': start_datetime,
                    'durationHours': calculated_duration,
                    'vehicleId': vehicle_id,
                    'paymentMethod': payment_method,
                    'amountPaid': amount_paid
                }

                # Make request to backend
                response = requests.post(f"{BACKEND_URL}/api/slots/{slot_object_id}/bookings", json=booking_data, headers=headers)
                if response.status_code == 201:
                    data = response.json()
                    if payment_method == 'razorpay':
                        # For Razorpay, return order details for payment
                        return {'status': 'success', 'data': f'Razorpay payment initiated. Order ID: {data.get("orderId", "N/A")}. Please complete the payment to confirm your booking.'}
                    elif payment_method == 'coupon':
                        # For coupon, booking is confirmed immediately
                        return {'status': 'success', 'data': f'Booking confirmed successfully! Your slot is booked from {start_time_24} to {end_time_24} on {booking_date} using coupon BOOKFREE.'}
                    else:
                        return {'status': 'success', 'data': f'Booking created successfully from {start_time_24} to {end_time_24} on {booking_date}.'}
                else:
                    return {'status': 'error', 'message': f'Booking failed: {response.text}'}
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

    def _convert_to_24_hour(self, time_str: str) -> str:
        """
        Convert 12-hour time format to 24-hour format.
        E.g., '1:00pm' -> '13:00'
        """
        try:
            from datetime import datetime
            # Parse the time
            dt = datetime.strptime(time_str, '%I:%M%p')
            # Format to 24-hour
            return dt.strftime('%H:%M')
        except ValueError:
            # If parsing fails, assume it's already in 24-hour or return as is
            return time_str

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

    def _fetch_user_vehicles(self, token: str) -> list:
        """
        Fetch user vehicles using token.
        """
        try:
            headers = {'Authorization': f'Bearer {token}'}
            response = requests.get(f"{BACKEND_URL}/api/user/vehicles", headers=headers)
            response.raise_for_status()
            data = response.json()
            return data.get('vehicles', [])
        except Exception as e:
            self.logger.error(f"Failed to fetch user vehicles: {str(e)}")
            return []

    def _fetch_slot_details(self, slot_id: str) -> dict:
        """
        Fetch slot details by slot ID.
        """
        try:
            response = requests.get(f"{BACKEND_URL}/api/slots/slot/{slot_id}")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            self.logger.error(f"Failed to fetch slot details for {slot_id}: {str(e)}")
            return {}

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
