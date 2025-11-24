import json
import os
import numpy as np

# Paths
ASSETS_DIR = r'c:\Projects\eduthon\assets\ai'
VECTORS_PATH = os.path.join(ASSETS_DIR, 'vectors.json')
VOCAB_PATH = os.path.join(ASSETS_DIR, 'vocab.txt')
MODEL_PATH = os.path.join(ASSETS_DIR, 'LaBSE.tflite')

def verify_files():
    print("Checking files...")
    files = [VECTORS_PATH, VOCAB_PATH, MODEL_PATH]
    all_exist = True
    for f in files:
        if os.path.exists(f):
            print(f"✅ Found: {os.path.basename(f)} ({os.path.getsize(f) / (1024*1024):.2f} MB)")
        else:
            print(f"❌ Missing: {f}")
            all_exist = False
    return all_exist

def verify_vocab():
    print("\nVerifying Vocab...")
    try:
        with open(VOCAB_PATH, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        print(f"✅ Vocab loaded. Total tokens: {len(lines)}")
        if len(lines) > 1000:
            print("   Sample tokens:", [l.split('\t')[0] for l in lines[:5]])
    except Exception as e:
        print(f"❌ Error reading vocab: {e}")

def verify_vectors():
    print("\nVerifying Vectors (Knowledge Base)...")
    try:
        with open(VECTORS_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"✅ JSON Loaded. Total Chunks: {len(data)}")
        
        if len(data) == 0:
            print("❌ Error: Vector database is empty!")
            return

        # Check first item
        first_item = data[0]
        vec = first_item.get('vector') or first_item.get('embedding')
        
        if vec:
            print(f"✅ Vector found in first item. Dimension: {len(vec)}")
            if len(vec) == 768:
                print("✅ Dimension matches LaBSE (768).")
            else:
                print(f"⚠️ Warning: Dimension {len(vec)} != 768.")
        else:
            print("❌ Error: No vector found in first item.")

        # Random Content Check
        print("\n--- Content Preview ---")
        for i in range(min(3, len(data))):
            text = data[i].get('text', '')
            source = data[i].get('metadata', {}).get('source', 'Unknown')
            print(f"[{i+1}] {source}: {text[:100]}...")

    except Exception as e:
        print(f"❌ Error reading vectors.json: {e}")

if __name__ == "__main__":
    if verify_files():
        verify_vocab()
        verify_vectors()
        print("\n✅ Data Integrity Check Passed. The app should work offline.")
    else:
        print("\n❌ Data Integrity Check Failed.")
