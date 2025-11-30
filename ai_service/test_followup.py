#!/usr/bin/env python3
"""
Test script specifically for follow-up question generation functionality
"""

from ai_model import AIModel
import json

def test_followup_questions():
    """Test follow-up question generation for various intents"""
    ai = AIModel()

    # Test cases focusing on follow-up question generation
    test_cases = [
        ("Show stations in Bangalore", "display_stations", "Should add follow-up after showing stations"),
        ("Show available car slots", "view_slots", "Should add follow-up after showing slots"),
        ("Book a slot", "book_slot", "Should add follow-up after booking guidance"),
        ("Show my bookings", "view_bookings", "Should add follow-up after showing bookings"),
        ("Add to favorites", "add_favorite", "Should add follow-up after adding favorite"),
        ("Show favorites", "view_favorites", "Should add follow-up after showing favorites"),
        ("Hello", "greet", "Should NOT add follow-up for greeting"),
        ("Thanks", "unknown", "Should NOT add follow-up for thanks"),
        ("Why can't you understand?", "unknown", "Should NOT add follow-up for frustration"),
    ]

    session_id = "followup_test_session"

    print("FOLLOW-UP QUESTION GENERATION TEST RESULTS")
    print("=" * 60)
    print(f"Session ID: {session_id}")
    print("=" * 60)

    results = []

    for i, (user_input, expected_intent, description) in enumerate(test_cases, 1):
        print(f"\n[{i}] Test: {description}")
        print(f"Input: '{user_input}'")
        print(f"Expected Intent: {expected_intent}")

        try:
            response = ai.get_ai_response(session_id, user_input)
            resp_text = response.get('response', '')
            intent = response.get('intent', 'N/A')

            print(f"Actual Intent: {intent}")
            print(f"Response: {resp_text[:150]}{'...' if len(resp_text) > 150 else ''}")

            # Check if follow-up question is present
            has_followup = any(phrase in resp_text.lower() for phrase in [
                "was that helpful?", "is there anything else", "can i help with",
                "need any other assistance", "anything else you'd like",
                "i'm here if you have any other", "let me know if you need"
            ])

            # Determine if follow-up should be present based on intent
            should_have_followup = intent in [
                'display_stations', 'view_slots', 'view_slots_filtered',
                'book_slot', 'view_bookings', 'add_favorite', 'view_favorites'
            ]

            status = "PASS" if (has_followup == should_have_followup) else "FAIL"

            print(f"Has Follow-up: {has_followup}")
            print(f"Should Have Follow-up: {should_have_followup}")
            print(f"Status: {status}")

            result = {
                'test_number': i,
                'description': description,
                'input': user_input,
                'expected_intent': expected_intent,
                'actual_intent': intent,
                'response': resp_text,
                'has_followup': has_followup,
                'should_have_followup': should_have_followup,
                'status': status
            }

        except Exception as e:
            print(f"Error: {str(e)}")
            result = {
                'test_number': i,
                'description': description,
                'input': user_input,
                'error': str(e),
                'status': 'ERROR'
            }

        results.append(result)
        print("-" * 50)

    # Summary
    passed = sum(1 for r in results if r['status'] == 'PASS')
    failed = sum(1 for r in results if r['status'] == 'FAIL')
    errors = sum(1 for r in results if r['status'] == 'ERROR')

    print(f"\n{'='*60}")
    print("FOLLOW-UP TEST SUMMARY")
    print(f"Total Tests: {len(results)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Errors: {errors}")
    print(f"{'='*60}")

    # Save results
    with open('followup_test_output.txt', 'w', encoding='utf-8') as f:
        f.write("FOLLOW-UP QUESTION GENERATION TEST RESULTS\n")
        f.write("=" * 60 + "\n\n")

        for result in results:
            f.write(f"[{result['test_number']}] {result['description']}\n")
            f.write(f"Input: '{result['input']}'\n")
            f.write(f"Expected Intent: {result['expected_intent']}\n")
            if 'error' in result:
                f.write(f"Status: {result['status']} - Error: {result['error']}\n")
            else:
                f.write(f"Actual Intent: {result['actual_intent']}\n")
                f.write(f"Has Follow-up: {result['has_followup']}\n")
                f.write(f"Should Have Follow-up: {result['should_have_followup']}\n")
                f.write(f"Status: {result['status']}\n")
                f.write(f"Response: {result['response']}\n")
            f.write("-" * 50 + "\n")

        f.write(f"\nSUMMARY: {passed} passed, {failed} failed, {errors} errors\n")

    print("Detailed results saved to 'followup_test_output.txt'")

if __name__ == "__main__":
    test_followup_questions()
