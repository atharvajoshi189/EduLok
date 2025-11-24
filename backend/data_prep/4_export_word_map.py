import sentencepiece as spm
import json
import os
import re

# --- Settings ---
PROJECT_ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
CORPUS_FILE_PATH = os.path.join(PROJECT_ROOT, 'corpus.txt')
SENTENCEPIECE_MODEL_PATH = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'sentencepiece.model')
WORD_MAP_OUTPUT_PATH = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'word_map.json')

def clean_text(text):
    # Simple cleaning to match what we'll do in Flutter
    text = text.lower()
    # Keep only alphanumeric and spaces
    text = re.sub(r'[^a-z0-9\s]', '', text)
    return text

def export_word_map():
    print("--- Exporting Word Map for Offline Tokenization ---")
    
    # 1. Load Tokenizer
    sp = spm.SentencePieceProcessor()
    sp.Load(SENTENCEPIECE_MODEL_PATH)
    
    # 2. Read Corpus
    try:
        with open(CORPUS_FILE_PATH, 'r', encoding='utf-8') as f:
            full_text = f.read()
    except Exception as e:
        print(f"[FATAL] Could not read corpus: {e}")
        return

    # 3. Extract Unique Words
    cleaned_text = clean_text(full_text)
    unique_words = set(cleaned_text.split())
    print(f"[INFO] Found {len(unique_words)} unique words in corpus.")

    # 4. Generate Map
    word_map = {}
    
    # Add special tokens manually if needed, but usually we just need word -> ids
    # [CLS] = 101, [SEP] = 102 (Standard BERT/LaBSE)
    # But SentencePiece might differ. Let's trust the SP model.
    
    for word in unique_words:
        ids = sp.EncodeAsIds(word)
        word_map[word] = ids
        
    # Add common query words that might not be in corpus
    common_words = ['what', 'is', 'explain', 'define', 'how', 'why', 'describe', 'tell', 'me', 'about']
    for word in common_words:
        if word not in word_map:
            word_map[word] = sp.EncodeAsIds(word)

    # 5. Save to JSON
    with open(WORD_MAP_OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(word_map, f)
        
    print(f"✅ Success! Word map saved to: {WORD_MAP_OUTPUT_PATH}")
    print(f"Map size: {len(word_map)} words.")

if __name__ == '__main__':
    export_word_map()
