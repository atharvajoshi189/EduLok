import tensorflow as tf
import tensorflow_hub as hub
import os
import shutil

print("Starting Tokenizer Download...")

# --- Settings ---
PREPROCESS_URL = "https://tfhub.dev/google/LaBSE/2"
OUTPUT_DIR = os.path.join("backend", "data_prep")
TEMP_MODEL_PATH = os.path.join(OUTPUT_DIR, "temp_preprocessor")
TOKENIZER_FILE_NAME = "sentencepiece.model"
FINAL_TOKENIZER_PATH = os.path.join(OUTPUT_DIR, TOKENIZER_FILE_NAME)


# --- Step 1: Model Download ---
try:
    if os.path.exists(TEMP_MODEL_PATH):
        shutil.rmtree(TEMP_MODEL_PATH)
        
    print(f"Downloading Preprocessor model from: {PREPROCESS_URL}")
    # Model ko download karke temporary folder mein save karna
    preprocessor = hub.KerasLayer(PREPROCESS_URL)
    
    # Model ko disk par save karna
    tf.saved_model.save(preprocessor, TEMP_MODEL_PATH)

except Exception as e:
    print(f"FATAL ERROR: Could not download Preprocessor. Check network/disk space. Details: {e}")
    exit()

# --- Step 2: Tokenizer File Find Aur Copy Karna ---
try:
    # SavedModel folder ke andar 'assets' folder mein file dhoondhna
    source_path = os.path.join(TEMP_MODEL_PATH, "assets", TOKENIZER_FILE_NAME)
    
    if os.path.exists(source_path):
        # File ko dhoondh liya, ab usey sahi jagah copy karna
        shutil.copyfile(source_path, FINAL_TOKENIZER_PATH)
        print(f"SUCCESS: '{TOKENIZER_FILE_NAME}' copied to {OUTPUT_DIR}")
    else:
        print(f"ERROR: Tokenizer file not found inside the downloaded model at {source_path}")
        
except Exception as e:
    print(f"ERROR: Failed during file copy. Details: {e}")
    
# --- Step 3: Temporary Folder Ko Delete Karna ---
try:
    shutil.rmtree(TEMP_MODEL_PATH)
    print("Cleanup complete.")
except Exception:
    pass

print("\nTokenizer setup complete. You can now run the vectorization script.")