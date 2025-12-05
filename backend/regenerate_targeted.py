import json
import os
import numpy as np
import tensorflow as tf
import re
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, '..', 'assets', 'ai')
WORD_MAP_PATH = os.path.join(ASSETS_DIR, 'word_map.json')
KNOWLEDGE_BASE_PATH = os.path.join(ASSETS_DIR, 'knowledge_base.json')
OUTPUT_VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors.json')
MODEL_PATH = os.path.join(ASSETS_DIR, 'LaBSE.tflite')

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

word_map = load_json(WORD_MAP_PATH)
knowledge_base = load_json(KNOWLEDGE_BASE_PATH)
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
    return output[0].tolist()

KEYWORDS = ["gravity", "force", "democracy", "newton", "constitution", "preamble", "election", "motion", "laws"]

print(f"Regenerating vectors for keywords: {KEYWORDS}")
new_vectors = []
count = 0

for i, item in enumerate(knowledge_base):
    text = item['text'].lower()
    # Check if any keyword is in text
    if any(k in text for k in KEYWORDS):
        vector = get_embedding(item['text'])
        new_vectors.append({
            'text': item['text'],
            'metadata': item.get('metadata', {}),
            'vector': vector
        })
        count += 1
        if count % 50 == 0: print(f"Found {count} matches...")

print(f"✅ Done! Regenerated {len(new_vectors)} targeted vectors.")
with open(OUTPUT_VECTORS_PATH, 'w', encoding='utf-8') as f:
    json.dump(new_vectors, f)
