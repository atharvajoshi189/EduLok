import json
import os
import random

# Paths
PROJECT_ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
OUTPUT_FILE = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'vectors.json')

def create_dummy_vectors():
    print("Creating dummy vectors for testing...")
    
    dummy_data = [
        {
            "text": "Gravity is a force of attraction that exists between any two masses, any two bodies, any two particles. Gravity is not just the attraction between objects and the Earth.",
            "vector": [random.random() for _ in range(768)]
        },
        {
            "text": "The formula for force is defined by Newton's Second Law: Force equals mass times acceleration (F = ma). The SI unit of force is the Newton (N).",
            "vector": [random.random() for _ in range(768)]
        },
        {
            "text": "Photosynthesis is the process used by plants, algae and certain bacteria to harness energy from sunlight and turn it into chemical energy.",
            "vector": [random.random() for _ in range(768)]
        },
        {
            "text": "The mitochondria is the powerhouse of the cell. It generates most of the chemical energy needed to power the cell's biochemical reactions.",
            "vector": [random.random() for _ in range(768)]
        },
        {
            "text": "Newton's laws of motion are three physical laws that, together, laid the foundation for classical mechanics. They describe the relationship between a body and the forces acting upon it.",
            "vector": [random.random() for _ in range(768)]
        },
        {
            "text": "The atom is the smallest unit of ordinary matter that forms a chemical element. Every solid, liquid, gas, and plasma is composed of neutral or ionized atoms.",
            "vector": [random.random() for _ in range(768)]
        },
        {
            "text": "The speed of light in a vacuum is approximately 299,792,458 meters per second.",
            "vector": [random.random() for _ in range(768)]
        },
        {
            "text": "DNA, or deoxyribonucleic acid, is the molecule that carries genetic information for the development and functioning of an organism.",
            "vector": [random.random() for _ in range(768)]
        }
    ]

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(dummy_data, f, indent=2)
        
    print(f"✅ Success! Dummy vectors saved to: {OUTPUT_FILE}")

if __name__ == '__main__':
    create_dummy_vectors()
