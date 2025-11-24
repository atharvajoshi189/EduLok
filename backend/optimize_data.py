import json

# Files ke path (Apne hisab se change kar lena agar alag ho)
input_file = './assets/ai/vectors.json'       # Jo abhi tumhare paas hai
output_file = './assets/ai/clean_knowledge.json' # Jo hum banayenge

print("⏳ Reading huge file...")
try:
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"✅ Loaded! Total Chunks: {len(data)}")

    # Minify (Spaces hatana)
    print("🚀 Compressing for Mobile...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"🎉 Success! '{output_file}' ban gayi. Isse Flutter assets mein use karo.")

except Exception as e:
    print(f"❌ Error: {e}")