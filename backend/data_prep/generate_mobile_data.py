import json
import re

# This represents your raw chapter content
raw_data = [
    {"id": 1, "text": "Mitochondria is known as the powerhouse of the cell. It produces energy in the form of ATP."}
]

output_data = []

for item in raw_data:
    text = item['text']
    
    # 1. Generate Keywords (Simple Logic: finding capitalized words or long words)
    # In a real scenario, use spaCy or NLTK here since this runs on your PC
    words = re.findall(r'\b\w{6,}\b', text) # Find words longer than 6 chars
    keywords = list(set(words)) 
    
    # 2. Generate Summary (First sentence rule for low-end simplicity)
    summary = text.split('.')[0] + "."

    output_data.append({
        "chapter_id": item['id'],
        "content": text,
        "keywords": keywords, # Saved for Quiz Generation
        "summary": summary    # Saved for Summary View
    })

# Save this file to your Flutter Assets folder directly
with open('../../assets/ai/smart_content.json', 'w') as f:
    json.dump(output_data, f)

print("✅ smart_content.json generated in Flutter assets folder!")