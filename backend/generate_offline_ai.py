import json
import os
import re
import random

# CONFIGURATION
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)

INPUT_FILE = os.path.join(PROJECT_ROOT, 'assets', 'content', 'master_syllabus.json')
OUTPUT_FILE = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'smart_syllabus.json')

def clean_text(text):
    """Removes Markdown symbols to make text readable."""
    text = re.sub(r'\*\*(.*?)\*\*', r'\1', text) # Remove bold
    text = re.sub(r'#+\s', '', text)             # Remove headers
    return text.strip()

def extract_smart_features(chapter_notes):
    """
    Analyzes Markdown notes to generate Quiz and Summary.
    Logic: 
    1. bold words (**word**) are treated as Keywords/Answers.
    2. Sentences containing bold words become Questions.
    """
    if not chapter_notes:
        return None

    # 1. Extract Keywords (Anything inside **bold**)
    # distinct keywords found in this chapter
    keywords = list(set(re.findall(r'\*\*(.*?)\*\*', chapter_notes)))
    
    # 2. Generate Summary (Take the 'Chapter Overview' section or first 300 chars)
    summary = "Summary not available."
    if "## 🧠 Chapter Overview" in chapter_notes:
        parts = chapter_notes.split("## 🧠 Chapter Overview")
        if len(parts) > 1:
            # Get text until the next header '##' or end
            summary_raw = parts[1].split("##")[0] 
            summary = clean_text(summary_raw).strip()
    else:
        summary = clean_text(chapter_notes)[:300] + "..."

    # 3. Generate Quiz Questions
    quiz_data = []
    lines = chapter_notes.split('\n')
    
    for line in lines:
        # We only want lines that look like facts (contain a bold keyword)
        # and aren't too short or headers
        if not line.startswith('#') and len(line) > 30:
            for word in keywords:
                # Check if this specific keyword is in this line (as a whole word)
                if f"**{word}**" in line:
                    # Create the question
                    clean_line = clean_text(line)
                    question = clean_line.replace(word, "_______")
                    
                    # Create Options (1 Correct + 3 Wrong)
                    options = [word]
                    # Pick 3 random distractors from OTHER keywords in the list
                    distractors = [k for k in keywords if k != word]
                    if len(distractors) >= 3:
                        options.extend(random.sample(distractors, 3))
                    else:
                        # Fallback if not enough keywords: add dummy ones
                        options.extend(["None", "All of these", "Variable"][:3-len(distractors)] + distractors)
                    
                    random.shuffle(options)
                    
                    quiz_data.append({
                        "question": question,
                        "correct_answer": word,
                        "options": options
                    })
                    break # Only make one question per line to avoid duplicates

    return {
        "keywords": keywords,
        "summary": summary,
        "quiz": quiz_data[:10] # Limit to 10 questions per chapter
    }

def process_syllabus():
    print("🧠 Starting AI Processing...")
    
    # Load your existing syllabus
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Traverse the JSON Tree (Class -> Subject -> Chapter)
    for class_name, class_data in data.items():
        if "subjects" in class_data:
            for subject in class_data["subjects"]:
                print(f"  Processing {class_name} - {subject['name']}...")
                for chapter in subject["chapters"]:
                    
                    # EXTRACT INTELLIGENCE
                    notes = chapter.get("notes", "")
                    smart_content = extract_smart_features(notes)
                    
                    if smart_content:
                        # Inject back into the JSON object
                        chapter["smart_content"] = smart_content
                        print(f"    ✅ Generated {len(smart_content['quiz'])} questions for: {chapter['title']}")
                    else:
                        print(f"    ⚠️ No notes found for: {chapter['title']}")

    # Save the "Smart" JSON
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    print(f"\n🚀 DONE! Smart Syllabus saved to: {OUTPUT_FILE}")

if __name__ == "__main__":
    process_syllabus()