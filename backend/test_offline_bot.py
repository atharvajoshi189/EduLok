import json
import numpy as np
import tensorflow as tf # Assuming tensorflow is installed, or we can use tflite_runtime
import sentencepiece as spm
import os

# Paths
ASSETS_DIR = r'c:\Projects\eduthon\assets\ai'
MODEL_PATH = os.path.join(ASSETS_DIR, 'LaBSE.tflite')
SP_MODEL_PATH = os.path.join(ASSETS_DIR, 'sentencepiece.model')
VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors.json')

def load_data():
    print("Loading vectors.json...")
    with open(VECTORS_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f"Loaded {len(data)} chunks.")
    return data

def load_model():
    print("Loading LaBSE.tflite...")
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    return interpreter

def load_tokenizer():
    print("Loading SentencePiece model...")
    sp = spm.SentencePieceProcessor()
    sp.load(SP_MODEL_PATH)
    return sp

def get_embedding(text, interpreter, sp):
    # Tokenize
    input_ids = sp.encode_as_ids(text)
    
    # Pad/Truncate to 128
    seq_len = 128
    if len(input_ids) > seq_len:
        input_ids = input_ids[:seq_len]
    else:
        input_ids = input_ids + [0] * (seq_len - len(input_ids))
    
    # Inputs
    input_ids = np.array([input_ids], dtype=np.int32)
    input_mask = np.ones((1, seq_len), dtype=np.int32)
    segment_ids = np.zeros((1, seq_len), dtype=np.int32)
    
    # Get Input/Output Details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Set Tensors
    # Note: Index mapping depends on model export. 
    # Usually: 0=ids, 1=mask, 2=segment (check shapes to be sure)
    # We'll try to match by shape or name if possible, but standard BERT is usually consistent.
    # Let's assume standard order or try to map.
    
    for i, detail in enumerate(input_details):
        if detail['shape'][-1] == 128: # All are 128 usually
            pass
            
    # Hardcoded indices based on common TFLite BERT exports
    # Often inputs are sorted by index. 
    # Let's try setting by index 0, 1, 2.
    interpreter.set_tensor(input_details[0]['index'], input_ids)
    interpreter.set_tensor(input_details[1]['index'], input_mask)
    interpreter.set_tensor(input_details[2]['index'], segment_ids)
    
    interpreter.invoke()
    
    output = interpreter.get_tensor(output_details[0]['index'])
    return output[0]

def cosine_similarity(v1, v2):
    dot_product = np.dot(v1, v2)
    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)
    return dot_product / (norm_v1 * norm_v2)

def search(query, data, interpreter, sp):
    print(f"\nQuery: {query}")
    query_vec = get_embedding(query, interpreter, sp)
    
    best_score = -1
    best_match = None
    
    for item in data:
        # Check if vector exists
        if 'vector' in item:
            vec = item['vector']
        elif 'embedding' in item:
            vec = item['embedding']
        else:
            continue
            
        score = cosine_similarity(query_vec, vec)
        if score > best_score:
            best_score = score
            best_match = item
            
    if best_match:
        print(f"Best Match (Score: {best_score:.4f}):")
        print(f"Text: {best_match.get('text', '')[:200]}...") # Print first 200 chars
        print(f"Source: {best_match.get('metadata', {}).get('source', 'Unknown')}")
    else:
        print("No match found.")

def main():
    try:
        data = load_data()
        interpreter = load_model()
        sp = load_tokenizer()
        
        questions = [
            "What is gravity?",
            "Explain Newton's first law",
            "What is the powerhouse of the cell?",
            "Who discovered the electron?",
            "Define photosynthesis",
            "What is the speed of light?"
        ]
        
        for q in questions:
            search(q, data, interpreter, sp)
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
