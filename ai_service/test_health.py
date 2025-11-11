import requests

try:
    response = requests.get('http://localhost:8000/health', timeout=5)
    print('Health check response:', response.status_code)
    if response.status_code == 200:
        print('Response:', response.json())
    else:
        print('Failed with status:', response.status_code)
except Exception as e:
    print('Health check failed:', str(e))
