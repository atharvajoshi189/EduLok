import json
import os

# Paths
PROJECT_ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
INPUT_FILE = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'vectors.json')
OUTPUT_FILE = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'vectors_small.json')

def create_small_version():
    print("Loading huge file (might take a moment)...")
    
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            # Ham streaming read use nahi kar rahe kyunki structure list hai
            # lekin testing ke liye hum sirf pehle 1000 characters read karke crash se bachne ki koshish karenge
            # Behtar tarika: Hum maante hain ki data valid JSON hai
            data = json.load(f)
            
        # Sirf pehle 1000 chunks lo (Demo ke liye kafi hai)
        small_data = data[:1000] 
        
        print(f"Original Size: {len(data)}")
        print(f"New Size: {len(small_data)}")

        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(small_data, f, indent=2)
            
        print(f"✅ Success! Small file created at: {OUTPUT_FILE}")
        
    except Exception as e:
        print(f"Error: {e}")
        print("Tip: Agar memory error aaye, to manually ek nayi vectors.json banao jisme kam data ho.")

if __name__ == '__main__':
    create_small_version()