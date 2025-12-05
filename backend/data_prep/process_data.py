import os
import json
import re
from sentence_transformers import SentenceTransformer

# Configuration
INPUT_DIR = "backend/data_prep/processed-text"
OUTPUT_FILE = "assets/data/initial_data.json"
MODEL_NAME = "all-MiniLM-L6-v2"
CHUNK_SIZE = 150  # Approx words

def load_model():
    print(f"Loading model: {MODEL_NAME}...")
    return SentenceTransformer(MODEL_NAME)

def parse_filename(filename):
    # Expected format: Class_Subject_Chapter.txt
    # Example: 9_Science_Gravitation.txt
    name = os.path.splitext(filename)[0]
    parts = name.split('_')
    if len(parts) >= 3:
        return {
            "classNum": parts[0],
            "subject": parts[1],
            "chapter": "_".join(parts[2:]) # Handle chapters with underscores
        }
    return {
        "classNum": "Unknown",
        "subject": "Unknown",
        "chapter": name
    }

def chunk_text(text, chunk_size=CHUNK_SIZE):
    words = text.split()
    chunks = []
    current_chunk = []
    current_count = 0
    
    # Simple chunking by word count, respecting paragraphs could be added by splitting by \n\n first
    # For now, let's just do word count with overlap or sentence boundary?
    # The requirement says "respecting paragraph breaks".
    
    paragraphs = text.split('\n\n')
    for para in paragraphs:
        para_words = para.split()
        if not para_words:
            continue
            
        if current_count + len(para_words) <= chunk_size:
            current_chunk.extend(para_words)
            current_count += len(para_words)
        else:
            # If current chunk is not empty, save it
            if current_chunk:
                chunks.append(" ".join(current_chunk))
            
            # If paragraph itself is larger than chunk_size, split it
            if len(para_words) > chunk_size:
                for i in range(0, len(para_words), chunk_size):
                    chunk = para_words[i:i+chunk_size]
                    chunks.append(" ".join(chunk))
                current_chunk = []
                current_count = 0
            else:
                current_chunk = list(para_words)
                current_count = len(para_words)
    
    if current_chunk:
        chunks.append(" ".join(current_chunk))
        
    return chunks

def process_files():
    model = load_model()
    data = []
    
    if not os.path.exists(INPUT_DIR):
        print(f"Input directory {INPUT_DIR} does not exist. Creating it...")
        os.makedirs(INPUT_DIR)
        return

    files = [f for f in os.listdir(INPUT_DIR) if f.endswith(".txt")]
    print(f"Found {len(files)} files.")

    for filename in files:
        print(f"Processing {filename}...")
        filepath = os.path.join(INPUT_DIR, filename)
        metadata = parse_filename(filename)
        
        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()
            
        chunks = chunk_text(text)
        print(f"  - Generated {len(chunks)} chunks.")
        
        # Batch encode
        embeddings = model.encode(chunks)
        
        for i, chunk in enumerate(chunks):
            entry = {
                "classNum": metadata["classNum"],
                "subject": metadata["subject"],
                "chapter": metadata["chapter"],
                "text": chunk,
                "vector": embeddings[i].tolist()
            }
            data.append(entry)

    # Save to JSON
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    
    print(f"Saved {len(data)} chunks to {OUTPUT_FILE}")

if __name__ == "__main__":
    process_files()
