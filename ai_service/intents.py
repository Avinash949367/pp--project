# intents.py - Define intents, entity rules, and response templates

INTENTS = {
    "navigate_book_slot": {
        "keywords": ["book", "slot", "parking", "reserve", "park", "rent", "get", "hire", "take"],
        "action": "navigate",
        "screen": "book_slot",
        "params": {}
    },
    "display_stations": {
        "keywords": ["check", "available", "parking", "stations", "station", "location", "in", "see", "show", "list", "view", "find"],
        "action": "display",
        "screen": "stations",
        "params": {}
    },
    "view_slots": {
        "keywords": ["slots", "slot", "available slots", "available slot", "show slots", "show slot", "list slots", "list slot", "view slots", "view slot", "parking slots", "parking slot"],
        "action": "display",
        "screen": "slots",
        "params": {}
    },
    "view_slots_filtered": {
        "keywords": ["slots", "slot", "available slots", "available slot", "show slots", "show slot", "list slots", "list slot", "view slots", "view slot", "parking slots", "parking slot", "find", "search", "get", "parking", "bike", "car", "motorcycle", "scooter", "truck", "vehicle"],
        "action": "display",
        "screen": "slots",
        "params": {}
    },
    "navigate_search_stations": {
        "keywords": ["search", "find", "stations", "location", "nearby", "around", "close"],
        "action": "navigate",
        "screen": "search",
        "params": {}
    },
    "navigate_bookings": {
        "keywords": ["bookings", "my bookings", "reservations", "history", "view bookings", "view", "past", "previous", "show bookings"],
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
    "cancel_booking": {
        "keywords": ["cancel", "delete", "remove", "booking", "reservation"],
        "action": "cancel",
        "screen": "bookings",
        "params": {}
    },
    "edit_profile": {
        "keywords": ["edit", "update", "change", "profile", "account", "personal", "info"],
        "action": "navigate",
        "screen": "profile",
        "params": {}
    },
    "view_payment_history": {
        "keywords": ["payment", "history", "transactions", "paid", "bills", "receipts"],
        "action": "display",
        "screen": "payments",
        "params": {}
    },
    "logout": {
        "keywords": ["logout", "sign out", "exit", "leave"],
        "action": "logout",
        "screen": None,
        "params": {}
    },
    "settings": {
        "keywords": ["settings", "preferences", "options", "config"],
        "action": "navigate",
        "screen": "settings",
        "params": {}
    },
    "feedback": {
        "keywords": ["feedback", "review", "rate", "comment", "suggestion"],
        "action": "navigate",
        "screen": "feedback",
        "params": {}
    },
    "emergency": {
        "keywords": ["emergency", "help", "contact", "support", "urgent"],
        "action": "display",
        "screen": "emergency",
        "params": {}
    },
    "help": {
        "keywords": ["help", "assist", "what can you do", "commands", "options", "guide"],
        "action": None,
        "screen": None,
        "params": {}
    },
    "greet": {
        "keywords": ["hi", "hello", "hey", "greetings", "good morning", "good afternoon", "good evening"],
        "action": None,
        "screen": None,
        "params": {}
    }
}

CITY_CORRECTIONS = {
    'banglore': 'bangalore',
    # Add more common misspellings as needed
}

ENTITY_RULES = {
    'city': r'in (\w+)',
    'time': r'at (\d{1,2}(?::\d{2})? ?(?:am|pm)?)',
    'date': r'on (\d{1,2}/\d{1,2}(?:/\d{2,4})?)',
    'duration': r'for (\d+) hours?',
    'booking_id': r'booking (\d+)',
    'amount': r'amount (\d+)',
    'vehicle': r'vehicle (\w+)',
    'station': r'station (\w+)',
    'vehicle_type': r'(bike|car|motorcycle|scooter|truck|vehicle) slots?'
}

RESPONSE_TEMPLATES = {
    'navigate_book_slot': "Navigating to book a slot{city_part}.",
    'navigate_search_stations': "Searching for stations{city_part}.",
    'display_stations': "Here are the available parking stations{city_part}:",
    'view_slots': "Here are the available slots:",
    'view_slots_filtered': "Here are the available slots{filter_part}:",
    'navigate_bookings': "Showing your bookings.",
    'navigate_profile': "Opening your profile.",
    'navigate_home': "Going to home screen.",
    'cancel_booking': "Cancelling your booking.",
    'edit_profile': "Editing your profile.",
    'view_payment_history': "Viewing your payment history.",
    'logout': "Logging you out.",
    'settings': "Opening settings.",
    'feedback': "Opening feedback form.",
    'emergency': "Displaying emergency contacts.",
    'help': "I can help you with: booking slots, viewing bookings, navigating to profile, searching stations, cancelling bookings, viewing payment history, and more. What would you like to do?",
    'greet': "Hello! How can I assist you with parking today?",
    'unknown': "I'm sorry, I didn't understand that. Could you please rephrase or provide more details? Try saying 'help' for available commands."
}
