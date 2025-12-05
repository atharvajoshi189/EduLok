import json
import os
import numpy as np
import tensorflow as tf
import re
import threading
from gpt4all import GPT4All

# --- Configuration ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, '..', 'assets', 'ai')

VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors.json')
WORD_MAP_PATH = os.path.join(ASSETS_DIR, 'word_map.json')
LABSE_MODEL_PATH = os.path.join(ASSETS_DIR, 'LaBSE.tflite')

# GPT4All Model
GPT_MODEL_NAME = "orca-mini-3b-gguf2-q4_0.gguf" 

# Globals
_knowledge_base = []
_word_map = {}
_labse_interpreter = None
_gpt_model = None
_model_lock = threading.Lock()

def initialize():
    global _knowledge_base, _word_map, _labse_interpreter, _gpt_model
    
    print("--- Initializing Chat Service (Local Server) ---")
    
    # 1. Load Knowledge Base (Vectors)
    if os.path.exists(VECTORS_PATH):
        with open(VECTORS_PATH, 'r', encoding='utf-8') as f:
            _knowledge_base = json.load(f)
        print(f"✅ Loaded Knowledge Base: {len(_knowledge_base)} chunks")
    else:
        print("❌ Knowledge Base (vectors.json) not found!")
        _knowledge_base = []

    # 2. Load Word Map
    if os.path.exists(WORD_MAP_PATH):
        with open(WORD_MAP_PATH, 'r', encoding='utf-8') as f:
            _word_map = json.load(f)
        print(f"✅ Loaded Word Map: {len(_word_map)} words")
    else:
        print("❌ Word Map not found!")

    # 3. Load LaBSE
    print("⏳ Loading LaBSE Model...")
    try:
        _labse_interpreter = tf.lite.Interpreter(model_path=LABSE_MODEL_PATH)
        _labse_interpreter.allocate_tensors()
        print("✅ LaBSE Loaded")
    except Exception as e:
        print(f"❌ Error loading LaBSE: {e}")

    # 4. Load GPT4All
    print("⏳ Loading GPT4All Model...")
    try:
        _gpt_model = GPT4All(GPT_MODEL_NAME, allow_download=True) 
        print("✅ GPT4All Loaded")
    except Exception as e:
        print(f"❌ Error loading GPT4All: {e}")

# --- Tokenization Logic (Matches Mobile App) ---
def _tokenize(text):
    tokens = [101] # [CLS]
    
    # Normalize: lowercase and remove non-alphanumeric (keeping spaces)
    clean_text = re.sub(r'[^a-z0-9\s]', '', text.lower())
    words = clean_text.split()
    
    for word in words:
        if word in _word_map:
            # word_map[word] is a list of IDs
            tokens.extend(_word_map[word])
        else:
            tokens.append(100) # [UNK]
            
    tokens.append(102) # [SEP]
    
    # Pad/Truncate to 128
    max_len = 128
    if len(tokens) > max_len:
        tokens = tokens[:max_len]
    else:
        tokens.extend([0] * (max_len - len(tokens)))
        
    return tokens

def _get_embedding(text):
    if not _labse_interpreter: return np.zeros(768)

    input_ids = _tokenize(text)
    attention_mask = [1 if t != 0 else 0 for t in input_ids]
    
    input_ids_tensor = np.array([input_ids], dtype=np.int32)
    mask_tensor = np.array([attention_mask], dtype=np.int32)
    segment_ids_tensor = np.zeros((1, 128), dtype=np.int32)
    
    input_details = _labse_interpreter.get_input_details()
    output_details = _labse_interpreter.get_output_details()
    
    for detail in input_details:
        name = detail['name']
        idx = detail['index']
        if 'input_ids' in name or 'ids' in name and 'segment' not in name:
            _labse_interpreter.set_tensor(idx, input_ids_tensor)
        elif 'mask' in name:
            _labse_interpreter.set_tensor(idx, mask_tensor)
        elif 'segment' in name:
            _labse_interpreter.set_tensor(idx, segment_ids_tensor)
            
    _labse_interpreter.invoke()
    output = _labse_interpreter.get_tensor(output_details[0]['index'])
    return output[0]

def _cosine_similarity(v1, v2):
    dot = np.dot(v1, v2)
    norm1 = np.linalg.norm(v1)
    norm2 = np.linalg.norm(v2)
    if norm1 == 0 or norm2 == 0: return 0.0
    return dot / (norm1 * norm2)

def get_response(query, subject_filter=None):
    if not _gpt_model:
        return "Error: AI Model not loaded."

    print(f"Query: {query}")
    
    # 1. Embed Query
    query_vec = _get_embedding(query)
    
    # 2. Search
    best_score = -1
    best_text = ""
    best_meta = {}
    
    # Hybrid Search Logic (Same as Mobile)
    query_words = query.lower().split()
    important_words = [w for w in query_words if len(w) > 3 and w not in ["what", "where", "when", "which", "this", "that"]]

    for item in _knowledge_base:
        doc_vec = np.array(item['vector'])
        cosine = _cosine_similarity(query_vec, doc_vec)
        
        # Keyword Boost
        boost = 0.0
        doc_lower = item['text'].lower()
        for word in important_words:
            if word in doc_lower:
                boost += 0.05
        
        score = cosine + boost
        
        if score > best_score:
            best_score = score
            best_text = item['text']
            best_meta = item.get('metadata', {})
            
    print(f"Best Match Score: {best_score}")
    
    # 3. Generate
    context = f"Context:\n{best_text}\n"
    
    # Optimized Prompt for Speed & Accuracy
    prompt = f"""
    Context: {context}
    Question: {query}
    Answer (Short & Simple):
    """
    
    with _model_lock:
        # Reduced max_tokens to 100 for speed, but enough for a good answer
        response = _gpt_model.generate(prompt, max_tokens=100)
    
    return response
