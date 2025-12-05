import os
import json
import re

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROCESSED_TEXT_DIR = os.path.join(BASE_DIR, 'processed-text')
OUTPUT_FILE = os.path.join(BASE_DIR, '..', '..', 'assets', 'ai', 'knowledge_base.json')

def parse_filename(filename):
    """
    Parses filename like '07_CBSE_SCI_01.txt'
    Returns: {'class': '7', 'board': 'CBSE', 'subject': 'Science', 'chapter': '1'}
    """
    name_without_ext = os.path.splitext(filename)[0]
    parts = name_without_ext.split('_')
    
    if len(parts) < 4:
        return None
        
    class_num = parts[0]
    board = parts[1]
    subject_code = parts[2]
    chapter_num = parts[3]
    
    # Map Subject Codes
    subject_map = {
        'SCI': 'Science',
        'MATH': 'Maths',
        'HIN': 'Hindi',
        'ENG': 'English',
        'SOC': 'Social Science',
        'CIV': 'Civics',
        'GEO': 'Geography',
        'HIS': 'History',
        'ECO': 'Economics'
    }
    
    subject = subject_map.get(subject_code, subject_code)
    
    return {
        'class': class_num,
        'board': board,
        'subject': subject,
        'chapter': chapter_num,
        'source_file': filename
    }

def create_knowledge_base():
    print("--- Starting Knowledge Base Creation ---")
    
    if not os.path.exists(PROCESSED_TEXT_DIR):
        print(f"Error: Directory not found: {PROCESSED_TEXT_DIR}")
        return

    knowledge_base = []
    
    files = [f for f in os.listdir(PROCESSED_TEXT_DIR) if f.endswith('.txt')]
    print(f"Found {len(files)} text files.")
    
    for filename in files:
        metadata = parse_filename(filename)
        if not metadata:
            print(f"Skipping invalid filename: {filename}")
            continue
            
        file_path = os.path.join(PROCESSED_TEXT_DIR, filename)
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Chunking (Simple paragraph based or fixed size)
            # For now, let's just store the whole chapter text but maybe split if too large?
            # Better to split into smaller chunks for vector search.
            
            chunk_size = 1000
            overlap = 100
            
            text_len = len(content)
            start = 0
            chunk_id = 0
            
            while start < text_len:
                end = min(start + chunk_size, text_len)
                chunk_text = content[start:end]
                
                # Create a chunk entry
                entry = {
                    'id': f"{filename}_{chunk_id}",
                    'text': chunk_text,
                    'metadata': metadata
                }
                knowledge_base.append(entry)
                
                start += (chunk_size - overlap)
                chunk_id += 1
                
        except Exception as e:
            print(f"Error reading {filename}: {e}")

    # Ensure output directory exists
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(knowledge_base, f, indent=2)
        
    print(f"✅ Success! Created {len(knowledge_base)} chunks in {OUTPUT_FILE}")

if __name__ == "__main__":
    create_knowledge_base()
