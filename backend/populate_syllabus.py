import os
import json
import requests
import re
import time

# Configuration
TEXT_DIR = r"c:\Projects\eduthon\backend\data_prep\processed-text"
JSON_PATH = r"c:\Projects\eduthon\assets\ai\smart_syllabus.json"
API_URL = "http://127.0.0.1:8000/chat"

# Subject Mapping
SUBJECT_MAP = {
    "SCI": "Science",
    "MATH": "Math",
    "ENG": "English",
    "HIN": "Hindi",
    "CIV": "Social Science", # Civics
    "GEO": "Social Science", # Geography
    "HIS": "Social Science", # History
    "ECO": "Social Science"  # Economics
}

def parse_filename(filename):
    # Example: 07_CBSE_CIV_02.txt
    match = re.match(r"(\d+)_CBSE_([A-Z]+)_(\d+)\.txt", filename)
    if match:
        class_num = int(match.group(1))
        subject_code = match.group(2)
        chapter_num = int(match.group(3))
        return class_num, subject_code, chapter_num
    return None

def call_llm(prompt, subject):
    try:
        response = requests.post(API_URL, json={"query": prompt, "subject": subject})
        if response.status_code == 200:
            return response.json().get("answer", "")
        else:
            print(f"Error calling LLM: {response.status_code}")
            return ""
    except Exception as e:
        print(f"Exception calling LLM: {e}")
        return ""

def generate_smart_content(text, subject):
    # 1. Summary
    summary_prompt = f"Summarize the following chapter text in 50 words or less. Keep it simple for a student:\n\n{text[:2000]}"
    summary = call_llm(summary_prompt, subject)

    # 2. Keywords
    keywords_prompt = f"Extract 5 key terms from this text as a comma-separated list:\n\n{text[:2000]}"
    keywords_raw = call_llm(keywords_prompt, subject)
    keywords = [k.strip() for k in keywords_raw.split(',')]

    # 3. Quiz (Simplified for speed)
    quiz_prompt = f"Generate 1 multiple choice question based on this text. Format: Question | OptionA, OptionB, OptionC, OptionD | CorrectOption\n\n{text[:2000]}"
    quiz_raw = call_llm(quiz_prompt, subject)
    quiz = []
    try:
        parts = quiz_raw.split('|')
        if len(parts) == 3:
            quiz.append({
                "question": parts[0].strip(),
                "options": [opt.strip() for opt in parts[1].split(',')],
                "correct_answer": parts[2].strip()
            })
    except:
        pass

    return {
        "summary": summary,
        "keywords": keywords,
        "quiz": quiz
    }

def main():
    print("Loading existing syllabus...")
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        syllabus = json.load(f)

    files = os.listdir(TEXT_DIR)
    files.sort()

    print(f"Found {len(files)} files to process.")

    for filename in files:
        if not filename.endswith(".txt"):
            continue

        parsed = parse_filename(filename)
        if not parsed:
            continue

        class_num, subject_code, chapter_num = parsed
        subject_name = SUBJECT_MAP.get(subject_code, "General")
        class_key = f"Class {class_num}"

        print(f"Processing: {filename} -> {class_key} - {subject_name} - Ch {chapter_num}")

        # Ensure Class exists
        if class_key not in syllabus:
            syllabus[class_key] = {"subjects": []}

        # Ensure Subject exists
        subject_entry = next((s for s in syllabus[class_key]["subjects"] if s["name"] == subject_name), None)
        if not subject_entry:
            subject_entry = {
                "name": subject_name,
                "icon": "book", # Default icon
                "color": "0xFF2196F3", # Default color
                "chapters": []
            }
            syllabus[class_key]["subjects"].append(subject_entry)

        # Check if chapter already exists (skip if notes are already populated to save time)
        chapter_id = f"c{class_num}_{subject_code.lower()}_{chapter_num}"
        existing_chapter = next((c for c in subject_entry["chapters"] if c["id"] == chapter_id), None)
        
        # Read text
        with open(os.path.join(TEXT_DIR, filename), 'r', encoding='utf-8') as f:
            text = f.read()

        # Generate Content
        smart_data = generate_smart_content(text, subject_name)

        if existing_chapter:
            existing_chapter["smart_content"] = smart_data
            existing_chapter["notes"] = text[:500] + "..." # Store snippet as notes for now
        else:
            new_chapter = {
                "id": chapter_id,
                "title": f"Chapter {chapter_num}", # We don't have titles in filename, could extract from text
                "desc": "Generated Chapter",
                "videoId": "", # No video for now
                "notes": text[:1000], # Store first 1000 chars as notes
                "smart_content": smart_data
            }
            subject_entry["chapters"].append(new_chapter)

        # Save periodically
        if chapter_num % 5 == 0:
             with open(JSON_PATH, 'w', encoding='utf-8') as f:
                json.dump(syllabus, f, indent=2)
             print("Saved progress.")

    # Final Save
    with open(JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(syllabus, f, indent=2)
    print("Done! Syllabus populated.")

if __name__ == "__main__":
    main()
