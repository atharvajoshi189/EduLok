import json
import os
import numpy as np

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VECTORS_PATH = os.path.join(BASE_DIR, '..', 'assets', 'ai', 'vectors.json')

def analyze():
    print(f"Loading {VECTORS_PATH}...")
    with open(VECTORS_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Loaded {len(data)} items.")
    
    norms = []
    for item in data:
        v = np.array(item['vector'])
        norms.append(np.linalg.norm(v))
        
    norms = np.array(norms)
    print(f"Min Norm: {np.min(norms)}")
    print(f"Max Norm: {np.max(norms)}")
    print(f"Avg Norm: {np.mean(norms)}")
    
    # Check for zero vectors
    zeros = np.sum(norms == 0)
    print(f"Zero Vectors: {zeros}")
    
    # Check for NaNs
    nans = np.sum(np.isnan(norms))
    print(f"NaN Norms: {nans}")

if __name__ == "__main__":
    analyze()
