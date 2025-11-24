import tensorflow as tf
import numpy as np
import json
import os
import sentencepiece as spm
import time

# --- Settings ---
MAX_SEQ_LENGTH = 128    # Yahi seq length rakhna, jo TFLite model conversion ke time set kiya tha
CHUNK_SIZE = 500        # Har chunk mein max 500 characters
CHUNK_OVERLAP = 50      # Overlap between chunks

# Paths
PROJECT_ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
CORPUS_FILE_PATH = os.path.join(PROJECT_ROOT, 'corpus.txt')
SENTENCEPIECE_MODEL_PATH = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'sentencepiece.model')
TFLITE_MODEL_PATH = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'LaBSE.tflite')
VECTORS_FILE_PATH = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'vectors.json')

def chunk_text(text, chunk_size, overlap):
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end]
        chunks.append(chunk)
        start += (chunk_size - overlap)
        if end >= len(text):
            break
    return chunks

def initialize_model():
    # Load SentencePiece Tokenizer
    tokenizer = spm.SentencePieceProcessor()
    tokenizer.Load(SENTENCEPIECE_MODEL_PATH)

    # Load TFLite Model
    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
    interpreter.allocate_tensors()

    # --- Get input details (input_ids & attention_mask) ---
    input_indices = {}
    for detail in interpreter.get_input_details():
        if 'input_ids' in detail['name']:
            input_indices['input_ids'] = detail['index']
        elif 'attention_mask' in detail['name']:
            input_indices['attention_mask'] = detail['index']
    return tokenizer, interpreter, input_indices

def encode_chunk(chunk, tokenizer, interpreter, input_indices):
    # Tokenization
    input_ids = tokenizer.EncodeAsIds(chunk)
    # Truncate
    if len(input_ids) > MAX_SEQ_LENGTH:
        input_ids = input_ids[:MAX_SEQ_LENGTH]
    # Pad
    padding_len = MAX_SEQ_LENGTH - len(input_ids)
    input_ids += [0] * padding_len
    attention_mask = [1] * (MAX_SEQ_LENGTH - padding_len) + [0] * padding_len  # Or [1]*len(input_ids)+[0]*padding_len

    input_ids_tensor = np.array([input_ids], dtype=np.int32)
    attention_mask_tensor = np.array([attention_mask], dtype=np.int32)

    interpreter.set_tensor(input_indices['input_ids'], input_ids_tensor)
    if 'attention_mask' in input_indices:
        interpreter.set_tensor(input_indices['attention_mask'], attention_mask_tensor)

    interpreter.invoke()
    output_details = interpreter.get_output_details()
    embedding = interpreter.get_tensor(output_details[0]['index'])[0]
    return embedding.tolist()

def process_corpus():
    print("--- Starting AI Vector Database Creation ---")
    start_time = time.time()
    tokenizer, interpreter, input_indices = initialize_model()

    try:
        with open(CORPUS_FILE_PATH, 'r', encoding='utf-8') as f:
            full_text = f.read()
    except Exception as e:
        print(f"[FATAL ERROR] Could not read corpus: {e}")
        return

    print(f"[INFO] Corpus size: {len(full_text)} chars.")
    chunks = chunk_text(full_text, CHUNK_SIZE, CHUNK_OVERLAP)
    print(f"[INFO] Total chunks: {len(chunks)}")

    all_vectors = []
    for i, chunk in enumerate(chunks):
        if i % 100 == 0:
            print(f"[PROGRESS] {i}/{len(chunks)} chunks processed...")
        try:
            vec = encode_chunk(chunk, tokenizer, interpreter, input_indices)
            # Vector length should be 768 for LaBSE!
            if len(vec) == 768:
                all_vectors.append({
                    "text": chunk,
                    "vector": vec
                })
            else:
                print(f"[WARN] Chunk {i}: skipped invalid vector size ({len(vec)})")
        except Exception as e:
            print(f"[ERROR] Chunk {i}: {e}")
            continue

    # Save
    with open(VECTORS_FILE_PATH, 'w', encoding='utf-8') as f:
        json.dump(all_vectors, f, indent=2)
    end_time = time.time()
    print(f"\n✨ Success! {len(all_vectors)} vectors saved: {VECTORS_FILE_PATH}")
    print(f"Total time: {end_time - start_time:.2f} sec.")

if __name__ == '__main__':
    process_corpus()
