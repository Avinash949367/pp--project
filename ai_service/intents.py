# intents.py - Define intents, entity rules, and response templates

INTENTS = {
    "navigate_book_slot": {
        "keywords": ["book", "slot", "parking", "reserve", "park", "rent", "get", "hire", "take"],
        "action": "navigate",
        "screen": "book_slot",
        "params": {}
    },
    "navigate_search_stations": {
        "keywords": ["search", "find", "stations", "location", "nearby", "around", "close"],
        "action": "navigate",
        "screen": "search",
        "params": {}
    },
    "navigate_bookings": {
        "keywords": ["bookings", "my bookings", "reservations", "history", "view bookings", "past", "previous", "show bookings"],
        "action": "display",
        "screen": "bookings",
        "params": {}
    },
    "navigate_profile": {
        "keywords": ["profile", "account", "settings", "user", "my profile", "edit", "personal"],
        "action": "navigate",
        "screen": "profile",
        "params": {}
    },
    "navigate_home": {
        "keywords": ["home", "main", "dashboard", "start", "welcome"],
        "action": "navigate",
        "screen": "home",
        "params": {}
    },
    "help": {
        "keywords": ["help", "assist", "what can you do", "commands", "options", "guide"],
        "action": None,
        "screen": None,
        "params": {}
    }
}

ENTITY_RULES = {
    'city': r'in (\w+)',
    'time': r'at (\d{1,2}(?::\d{2})? ?(?:am|pm)?)',
    'date': r'on (\d{1,2}/\d{1,2}(?:/\d{2,4})?)',
    'duration': r'for (\d+) hours?'
}

RESPONSE_TEMPLATES = {
    'navigate_book_slot': "Navigating to book a slot{city_part}.",
    'navigate_search_stations': "Searching for stations{city_part}.",
    'navigate_bookings': "Showing your bookings.",
    'navigate_profile': "Opening your profile.",
    'navigate_home': "Going to home screen.",
    'help': "I can help you with: booking slots, viewing bookings, navigating to profile, searching stations, and more. What would you like to do?",
    'unknown': "I'm sorry, I didn't understand that. Try saying 'help' for available commands."
}
