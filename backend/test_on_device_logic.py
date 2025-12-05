import json
import os
import numpy as np
import tensorflow as tf
import re

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, '..', 'assets', 'ai')

WORD_MAP_PATH = os.path.join(ASSETS_DIR, 'word_map.json')
VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors.json')
MODEL_PATH = os.path.join(ASSETS_DIR, 'LaBSE.tflite')

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

print("--- 🚀 Starting Beta Test (Simulation) ---")

# 1. Load Assets
print("1. Loading Assets...")
try:
    word_map = load_json(WORD_MAP_PATH)
    vectors_data = load_json(VECTORS_PATH)
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    print(f"   ✅ Loaded Word Map ({len(word_map)} words)")
    print(f"   ✅ Loaded Knowledge Base ({len(vectors_data)} chunks)")
    print("   ✅ Loaded LaBSE Model")
except Exception as e:
    print(f"   ❌ Error loading assets: {e}")
    exit()

# 2. Tokenization Logic
def tokenize(text):
    tokens = [101] # [CLS]
    clean_text = re.sub(r'[^a-z0-9\s]', '', text.lower())
    words = clean_text.split()
    for word in words:
        if word in word_map:
            tokens.extend(word_map[word])
        else:
            tokens.append(100) # [UNK]
    tokens.append(102) # [SEP]
    max_len = 128
    if len(tokens) > max_len:
        tokens = tokens[:max_len]
    else:
        tokens.extend([0] * (max_len - len(tokens)))
    return tokens

# 3. Inference Logic
def get_embedding(text, file=None):
    input_ids = tokenize(text)
    attention_mask = [1 if t != 0 else 0 for t in input_ids]
    input_ids_tensor = np.array([input_ids], dtype=np.int32)
    mask_tensor = np.array([attention_mask], dtype=np.int32)
    segment_ids_tensor = np.zeros((1, 128), dtype=np.int32)
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    if file and not hasattr(get_embedding, "printed_details"):
        file.write("\n--- Model Input Details ---\n")
        for d in input_details:
            file.write(f"Name: {d['name']}, Index: {d['index']}, Shape: {d['shape']}\n")
        get_embedding.printed_details = True

    for detail in input_details:
        name = detail['name']
        idx = detail['index']
        if 'input_ids' in name or 'ids' in name and 'segment' not in name:
            interpreter.set_tensor(idx, input_ids_tensor)
        elif 'mask' in name:
            interpreter.set_tensor(idx, mask_tensor)
        elif 'segment' in name:
            interpreter.set_tensor(idx, segment_ids_tensor)
            
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    return output[0]

# 4. Similarity Logic
def cosine_similarity(v1, v2):
    dot = np.dot(v1, v2)
    norm1 = np.linalg.norm(v1)
    norm2 = np.linalg.norm(v2)
    if norm1 == 0 or norm2 == 0: return 0.0
    return dot / (norm1 * norm2)

def calculate_hybrid_score(query_vec, doc_vec, query_text, doc_text):
    cosine = cosine_similarity(query_vec, doc_vec)
    
    # Simple Keyword Boosting
    boost = 0.0
    query_words = query_text.lower().split()
    doc_lower = doc_text.lower()
    
    important_words = [w for w in query_words if len(w) > 3 and w not in ["what", "where", "when", "which", "this", "that"]]
    
    for word in important_words:
        if word in doc_lower:
            boost += 0.05 # 5% boost per matching word
            
    return cosine + boost

# 5. Search Function
def search(query, file):
    file.write(f"\n❓ Query: {query}\n")
    print(f"Searching: {query}")
    
    tokens = tokenize(query)
    file.write(f"   Tokens: {tokens}\n")
    
    query_vec = get_embedding(query, file)
    file.write(f"   Vector First 5: {query_vec[:5]}\n")
    
    best_score = -1
    best_text = ""
    
    for item in vectors_data:
        doc_vec = np.array(item['vector'])
        score = calculate_hybrid_score(query_vec, doc_vec, query, item['text'])
        
        # DEBUG: Check specific doc
        if "democracy" in item['text'].lower() and "government" in item['text'].lower():
             # file.write(f"   DEBUG: Found 'democracy' doc. Score: {score}\n")
             pass

        if score > best_score:
            best_score = score
            best_text = item['text']
            
    file.write(f"   🎯 Best Match (Score: {best_score:.4f}):\n")
    file.write(f"   \"{best_text}\"\n")
    file.write("-" * 40 + "\n")
    return best_text

# --- Run Tests ---
queries = [
    "what is the formula of force",
    "what is gravity?",
    "what is democracy?"
]

with open('backend/beta_test_results.txt', 'w', encoding='utf-8') as f:
    f.write("--- Beta Test Results ---\n")
    for q in queries:
        search(q, f)

print("\n--- ✅ Beta Test Complete ---")
