import json
import os
import numpy as np
import tensorflow as tf
import re
import time

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, '..', 'assets', 'ai')

WORD_MAP_PATH = os.path.join(ASSETS_DIR, 'word_map.json')
KNOWLEDGE_BASE_PATH = os.path.join(ASSETS_DIR, 'knowledge_base.json')
OUTPUT_VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors.json')
MODEL_PATH = os.path.join(ASSETS_DIR, 'LaBSE.tflite')

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

print("--- 🔄 Regenerating Vectors for Mobile ---")

# 1. Load Assets
print("1. Loading Assets...")
try:
    word_map = load_json(WORD_MAP_PATH)
    knowledge_base = load_json(KNOWLEDGE_BASE_PATH)
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    print(f"   ✅ Loaded Word Map ({len(word_map)} words)")
    print(f"   ✅ Loaded Knowledge Base ({len(knowledge_base)} chunks)")
except Exception as e:
    print(f"   ❌ Error loading assets: {e}")
    exit()

# 2. Tokenization Logic (MUST MATCH MOBILE APP)
def tokenize(text):
    tokens = [101] # [CLS]
    # Normalize: lowercase and remove non-alphanumeric
    clean_text = re.sub(r'[^a-z0-9\s]', '', text.lower())
    words = clean_text.split()
    
    for word in words:
        if word in word_map:
            tokens.extend(word_map[word])
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

# 3. Inference Logic
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
    return output[0].tolist() # Convert to list for JSON

# 4. Processing Loop
new_vectors = []
start_time = time.time()

print("2. Generating Embeddings (This may take a while)...")
for i, item in enumerate(knowledge_base):
    text = item['text']
    try:
        vector = get_embedding(text)
        
        new_vectors.append({
            'text': text,
            'metadata': item.get('metadata', {}),
            'vector': vector
        })
    except Exception as e:
        print(f"   ❌ Error processing chunk {i}: {e}")

    if (i + 1) % 50 == 0:
        print(f"   Processed {i + 1}/{len(knowledge_base)} chunks...")
        # Save intermediate progress to avoid total loss
        with open(OUTPUT_VECTORS_PATH, 'w', encoding='utf-8') as f:
            json.dump(new_vectors, f)

# 5. Final Save
print("3. Saving final vectors.json...")
with open(OUTPUT_VECTORS_PATH, 'w', encoding='utf-8') as f:
    json.dump(new_vectors, f)

duration = time.time() - start_time
print(f"✅ Done! Regenerated {len(new_vectors)} vectors in {duration:.2f}s.")
