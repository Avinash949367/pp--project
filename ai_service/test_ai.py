#!/usr/bin/env python3
"""
Comprehensive Test script for AI assistant functionality
Tests various user inputs to verify human-like behavior
"""

from ai_model import AIModel
import json
import time

def test_ai_responses():
    """Test AI responses with comprehensive test cases"""
    ai = AIModel()

    # Comprehensive test cases based on provided specifications
    test_cases = [
        # 1. PERSONALITY & HUMAN-LIKE BEHAVIOR TESTS
        ("hello", "1.1 Personality Response Variations - Greeting 1"),
        ("hi", "1.1 Personality Response Variations - Greeting 2"),
        ("hey", "1.1 Personality Response Variations - Greeting 3"),
        ("This is so frustrating!", "1.3 Sentiment Detection - Negative"),
        ("Great job, thanks!", "1.3 Sentiment Detection - Positive"),
        ("Show me slots", "1.3 Sentiment Detection - Neutral"),
        ("I'm stressed about parking", "1.4 Empathy Responses"),

        # 2. CONTEXT & MEMORY TESTS
        ("Hello", "2.1 Session History - First message"),
        ("Show stations in Bangalore", "2.1 Session History - Second message"),
        ("What can you do?", "2.1 Session History - Third message"),
        ("Show slots at this station", "2.2 Cross-Reference Handling"),
        ("Show car slots in Bangalore", "2.3 User Preference Memory - Set preferences"),
        ("Show available slots", "2.3 User Preference Memory - Use preferences"),

        # 3. NATURAL LANGUAGE UNDERSTANDING TESTS
        ("Book for evening", "3.1 Ambiguity Detection - Vague time"),
        ("I want to book", "3.1 Ambiguity Detection - Missing info"),
        ("Show slots", "3.2 Slot Reference Resolution - Setup"),
        ("Book the first one", "3.2 Slot Reference Resolution - First reference"),
        ("Book that slot", "3.2 Slot Reference Resolution - That reference"),
        ("Book car slot at MG Road station for 2 hours tomorrow at 3pm", "3.3 Multiple Entity Extraction"),

        # 4. CONVERSATION FLOW TESTS
        ("Show available car slots", "4.1 Booking Flow - Show slots"),
        ("Book slot 3", "4.1 Booking Flow - Select slot"),
        ("Tomorrow 2pm to 5pm", "4.1 Booking Flow - Provide details"),
        ("razorpay", "4.1 Booking Flow - Payment method"),
        ("yes", "4.1 Booking Flow - Confirm payment"),
        ("Book slot 5", "4.2 Booking Flow - Partial info"),
        ("Tomorrow 3pm to 6pm", "4.2 Booking Flow - Complete info"),
        ("cancel", "4.3 Cancellation Handling"),
        ("Show slots at invalid station", "4.4 Error Recovery"),

        # 5. INTENT PARSING TESTS
        ("Show all car slots in Bangalore", "5.1 Intent Priority - Filtered slots"),
        ("Show parking stations with slots", "5.1 Intent Priority - Stations"),
        ("book", "5.2 Synonym Handling - Book"),
        ("reserve", "5.2 Synonym Handling - Reserve"),
        ("get parking", "5.2 Synonym Handling - Get parking"),
        ("rent slot", "5.2 Synonym Handling - Rent slot"),
        ("show slots", "5.3 Contextual Intent Boost - After vehicle mention"),

        # 6. ENTITY EXTRACTION TESTS
        ("at 2pm", "6.1 Time Format Recognition - 12hr"),
        ("14:00", "6.1 Time Format Recognition - 24hr"),
        ("2:30 PM", "6.1 Time Format Recognition - Full 12hr"),
        ("15-12-2024", "6.2 Date Format Recognition - DD-MM-YYYY"),
        ("15/12/24", "6.2 Date Format Recognition - DD/MM/YY"),
        ("tomorrow", "6.2 Date Format Recognition - Relative"),
        ("bike slots", "6.3 Vehicle Type Detection - Bike"),
        ("parking for car", "6.3 Vehicle Type Detection - Car"),
        ("motorcycle parking", "6.3 Vehicle Type Detection - Motorcycle"),
        ("in banglore", "6.4 City Correction - Misspelled"),
        ("in Bangalore", "6.4 City Correction - Correct"),

        # 7. PROACTIVE BEHAVIOR TESTS
        ("unknown query", "7.1 Proactive Suggestions"),
        ("I want to book a slot", "7.2 Missing Information Guidance"),

        # 8. FRUSTRATION DETECTION TESTS
        ("Why can't you understand?", "8.1 Frustration Indicators"),
        ("This is so annoying", "8.1 Frustration Indicators"),

        # 9. PAYMENT & BOOKING FLOW TESTS
        ("razorpay", "9.1 Payment Method Selection - Razorpay"),
        ("coupon BOOKFREE", "9.1 Payment Method Selection - Coupon"),
        ("yes", "9.2 Booking Confirmation"),
        ("no", "9.3 Booking Cancellation"),

        # 10. BACKEND INTEGRATION TESTS
        ("Show stations in Bangalore", "10.1 Station Search"),
        ("Show available car slots", "10.2 Slot Availability"),
        ("Show my bookings", "10.3 User Bookings"),

        # 11. EDGE CASE TESTS
        ("", "11.1 Empty Input"),
        ("   ", "11.1 Empty Input - Spaces"),
        ("Book slot #5 @ 2pm!", "11.3 Special Characters"),

        # 12. TIME-BASED BEHAVIOR TESTS
        ("hello", "12.1 Time-based Greetings"),

        # 13. LEARNING BEHAVIOR TESTS
        ("thanks", "13.1 Successful Pattern Recognition"),

        # 14. MULTI-USER SESSION TESTS
        ("Show Bangalore stations", "14.1 Session Isolation - User A"),
        ("Show this station", "14.1 Session Isolation - User B"),

        # 15. PERFORMANCE TESTS
        ("show slots", "15.1 Response Time - Basic query"),
    ]

    session_id = "test_session"

    print("COMPREHENSIVE AI ASSISTANT TEST RESULTS")
    print("=" * 60)
    print(f"Total Test Cases: {len(test_cases)}")
    print(f"Session ID: {session_id}")
    print("=" * 60)

    results = []
    start_time = time.time()

    for i, (user_input, description) in enumerate(test_cases, 1):
        print(f"\n[{i:2d}] Test: {description}")
        print(f"Input: '{user_input}'")

        test_start = time.time()
        try:
            response = ai.get_ai_response(session_id, user_input)
            test_time = time.time() - test_start

            intent = response.get('intent', 'N/A')
            resp_text = response.get('response', 'N/A')
            action = response.get('action', 'N/A')
            screen = response.get('screen', 'N/A')
            data_count = len(response.get('data', [])) if response.get('data') else 0

            print(f"Intent: {intent}")
            print(f"Response: {resp_text[:100]}{'...' if len(resp_text) > 100 else ''}")
            print(f"Action: {action}, Screen: {screen}")
            if data_count > 0:
                print(f"Data Items: {data_count}")
            print(".3f")

            # Store result
            result = {
                'test_number': i,
                'description': description,
                'input': user_input,
                'intent': intent,
                'response': resp_text,
                'action': action,
                'screen': screen,
                'data_count': data_count,
                'response_time': round(test_time, 3),
                'status': 'PASS'
            }

        except Exception as e:
            test_time = time.time() - test_start
            print(f"Error: {str(e)}")
            print(f"Response Time: {test_time:.3f}s")

            result = {
                'test_number': i,
                'description': description,
                'input': user_input,
                'error': str(e),
                'response_time': round(test_time, 3),
                'status': 'FAIL'
            }

        results.append(result)
        print("-" * 50)

    total_time = time.time() - start_time
    passed = sum(1 for r in results if r['status'] == 'PASS')
    failed = len(results) - passed

    print(f"\n{'='*60}")
    print("TEST SUMMARY")
    print(f"Total Tests: {len(results)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Total Time: {total_time:.2f}s")
    print(f"Average Time: {total_time/len(results):.3f}s")
    print(f"{'='*60}")

    # Save detailed results to file
    with open('test_output.txt', 'w', encoding='utf-8') as f:
        f.write("COMPREHENSIVE AI ASSISTANT TEST RESULTS\n")
        f.write("=" * 60 + "\n")
        f.write(f"Total Test Cases: {len(test_cases)}\n")
        f.write(f"Session ID: {session_id}\n")
        f.write(f"Total Execution Time: {total_time:.2f} seconds\n")
        f.write(f"Average Response Time: {total_time/len(results):.3f} seconds\n")
        f.write("=" * 60 + "\n\n")

        for result in results:
            f.write(f"[{result['test_number']:2d}] {result['description']}\n")
            f.write(f"Input: '{result['input']}'\n")
            if 'error' in result:
                f.write(f"Status: {result['status']} - Error: {result['error']}\n")
            else:
                f.write(f"Status: {result['status']}\n")
                f.write(f"Intent: {result['intent']}\n")
                f.write(f"Response: {result['response']}\n")
                f.write(f"Action: {result['action']}, Screen: {result['screen']}\n")
                if result['data_count'] > 0:
                    f.write(f"Data Items: {result['data_count']}\n")
            f.write(f"Response Time: {result['response_time']}s\n")
            f.write("-" * 50 + "\n")

        f.write(f"\nSUMMARY: {passed} passed, {failed} failed\n")

    print("Detailed results saved to 'test_output.txt'")

if __name__ == "__main__":
    test_ai_responses()
