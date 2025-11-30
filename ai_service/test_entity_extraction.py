from ai_model import AIModel

# Use the extract_entities method from AIModel
ai_model = AIModel()
extract_entities = ai_model.extract_entities

# Test the function with working input
test_text1 = "from 10am to 11pm"
result1 = extract_entities(test_text1)
print(f"Input: {test_text1}")
print(f"Extracted entities: {result1}")

# Test the problematic input
test_text2 = "10 am to 11 am"
result2 = extract_entities(test_text2)
print(f"\nInput: {test_text2}")
print(f"Extracted entities: {result2}")

# Test individual regex on problematic input
start_time_regex = ENTITY_RULES['start_time']
end_time_regex = ENTITY_RULES['end_time']

print(f"\nTesting regex on '{test_text2}':")
start_match = re.search(start_time_regex, test_text2, re.IGNORECASE)
end_match = re.search(end_time_regex, test_text2, re.IGNORECASE)

print(f"Start time regex match: {start_match}")
if start_match:
    print(f"Start time captured: {start_match.group(1)}")

print(f"End time regex match: {end_match}")
if end_match:
    print(f"End time captured: {end_match.group(1)}")

# Test another problematic input
test_text3 = "10am to 11pm"
result3 = extract_entities(test_text3)
print(f"\nInput: {test_text3}")
print(f"Extracted entities: {result3}")
