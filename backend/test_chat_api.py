import requests
import json

url = "http://127.0.0.1:8000/chat"
headers = {"Content-Type": "application/json"}

questions = [
    {"query": "What is Gravity?", "subject": "Science"},
    {"query": "Who was the first Mughal emperor?", "subject": "History"},
    {"query": "Formula for area of circle?", "subject": "Maths"}
]

print("--- Testing Chat Endpoint ---")
try:
    for q in questions:
        print(f"\nAsking: {q['query']} (Subject: {q['subject']})")
        response = requests.post(url, headers=headers, json=q)
        if response.status_code == 200:
            print(f"Answer: {response.json()['answer'][:200]}...") # Print first 200 chars
        else:
            print(f"Error: {response.status_code} - {response.text}")
except Exception as e:
    print(f"Test Failed: {e}")
    print("Make sure the backend is running: uvicorn backend.main:app --reload")
