import json
import os
import numpy as np
import tensorflow as tf
import re

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, '..', 'assets', 'ai')
VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors.json')
# VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors_small.json')
WORD_MAP_PATH = os.path.join(ASSETS_DIR, 'word_map.json')
MODEL_PATH = os.path.join(ASSETS_DIR, 'LaBSE.tflite')

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

# Re-use logic from test script
word_map = load_json(WORD_MAP_PATH)
interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()

def tokenize(text):
    tokens = [101]
    clean_text = re.sub(r'[^a-z0-9\s]', '', text.lower())
    words = clean_text.split()
    for word in words:
        if word in word_map:
            tokens.extend(word_map[word])
        else:
            tokens.append(100)
    tokens.append(102)
    max_len = 128
    if len(tokens) > max_len:
        tokens = tokens[:max_len]
    else:
        tokens.extend([0] * (max_len - len(tokens)))
    return tokens

def get_embedding(text):
    input_ids = tokenize(text)
    attention_mask = [1 if t != 0 else 0 for t in input_ids]
    input_ids_tensor = np.array([input_ids], dtype=np.int32)
    mask_tensor = np.array([attention_mask], dtype=np.int32)
    segment_ids_tensor = np.zeros((1, 128), dtype=np.int32)
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
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

def cosine_similarity(v1, v2):
    dot = np.dot(v1, v2)
    norm1 = np.linalg.norm(v1)
    norm2 = np.linalg.norm(v2)
    if norm1 == 0 or norm2 == 0: return 0.0
    return dot / (norm1 * norm2)

def check_vectors():
    print(f"Loading {VECTORS_PATH}...")
    with open(VECTORS_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Loaded {len(data)} items.")
    
    # 1. Check for duplicates
    print("Checking first 5 vectors for duplicates...")
    for i in range(5):
        if i+1 >= len(data): break
        v1 = np.array(data[i]['vector'])
        v2 = np.array(data[i+1]['vector'])
        dist = np.linalg.norm(v1 - v2)
        print(f"Dist {i}-{i+1}: {dist}")
        if dist < 0.001:
            print("❌ CRITICAL: Vectors are identical!")

    # 2. Check distance to query
    query = "what is gravity?"
    print(f"Generating embedding for: '{query}'")
    query_vec = get_embedding(query)
    
    print("Checking distance to query for first 3 items...")
    for i in range(3):
        doc_vec = np.array(data[i]['vector'])
        score = cosine_similarity(query_vec, doc_vec)
        print(f"Item {i} Similarity: {score}")
        if score > 0.99:
            print("❌ CRITICAL: Vector is identical to query!")

if __name__ == "__main__":
    check_vectors()
