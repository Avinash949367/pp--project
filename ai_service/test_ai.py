#!/usr/bin/env python3

from ai_model import AIModel

def test_intent_recognition():
    ai = AIModel()

    # Test cases
    test_cases = [
        {
            "input": "show me bike slots in Bangalore",
            "expected_intent": "view_slots_filtered",
            "expected_entities": {"city": "bangalore", "vehicle_type": "bike"}
        },
        {
            "input": "find car parking in Mumbai",
            "expected_intent": "view_slots_filtered",
            "expected_entities": {"city": "mumbai", "vehicle_type": "car"}
        },
        {
            "input": "show slots",
            "expected_intent": "view_slots",    
            "expected_entities": {}
        },
        {
            "input": "show me available slots",
            "expected_intent": "view_slots",
            "expected_entities": {}
        }
    ]

    print("Testing AI Intent Recognition and Entity Extraction")
    print("=" * 50)

    for i, case in enumerate(test_cases, 1):
        print(f"\nTest Case {i}: '{case['input']}'")
        result = ai.parse_intent(case['input'])
        entities = result['entities']

        # Check intent
        intent_match = result['intent'] == case['expected_intent']
        print(f"Expected Intent: {case['expected_intent']}")
        print(f"Actual Intent: {result['intent']}")
        print(f"Intent Match: {'✓' if intent_match else '✗'}")

        # Check entities
        entity_match = True
        for key, value in case['expected_entities'].items():
            if key not in entities or entities[key] != value:
                entity_match = False
                break

        print(f"Expected Entities: {case['expected_entities']}")
        print(f"Actual Entities: {entities}")
        print(f"Entity Match: {'✓' if entity_match else '✗'}")

        overall = intent_match and entity_match
        print(f"Overall: {'PASS' if overall else 'FAIL'}")

    print("\n" + "=" * 50)
    print("Testing completed.")

if __name__ == "__main__":
    test_intent_recognition()
