import tensorflow as tf
import tensorflow_hub as hub
import os
import shutil

print("TensorFlow and Hub loaded. Starting LaBSE Encoder conversion.")

# --- Settings ---
# Hum sirf ENCODER model ko load karenge
ENCODER_URL = "https://tfhub.dev/google/LaBSE/2"
SAVED_MODEL_DIR = os.path.join("backend", "data_prep", "temp_lbse_encoder_model") # Temporary dir
TFLITE_MODEL_PATH = os.path.join("..", "assets", "ai", "LaBSE_encoder.tflite")

# --- STEP 1: Model Definition (Token IDs as Input) ---
# Input: token IDs (jo ki 768 length ka tensor hoga of int32)
input_layer = tf.keras.layers.Input(shape=(None,), dtype=tf.int32, name='input_word_ids')

# Encoder: Encoder model ko load karo
encoder = hub.KerasLayer(ENCODER_URL)


# Output: pooled_output (768-dim vector)
output = encoder(
    # Model ko teen zaroori inputs chahiye, jismein se hum sirf word_ids de rahe hain
    {'input_word_ids': input_layer,
     'input_mask': tf.ones_like(input_layer, dtype=tf.int32),
     'input_type_ids': tf.zeros_like(input_layer, dtype=tf.int32)
    }
)['pooled_output']

# Final model (Jo sirf Token IDs ko vector mein badlega)
model = tf.keras.Model(input_layer, output)

print("Combined model created. Saving temporary model...")

# --- STEP 2: Model ko locally save karna ---
os.makedirs(SAVED_MODEL_DIR, exist_ok=True)
model.save(SAVED_MODEL_DIR)

print("Temporary model saved. Starting TFLite conversion...")

# --- STEP 3: Local SavedModel ko convert karna ---
converter = tf.lite.TFLiteConverter.from_saved_model(SAVED_MODEL_DIR)

# Optimizations: Model ko 16-bit float mein chhota karna (size & speed ke liye)
converter.target_spec.supported_types = [tf.float16]

print("Converter setup. Converting model to TFLite...")
tflite_model = converter.convert()

print("Conversion successful. Saving model...")

# --- STEP 4: TFLite file ko save karna ---
os.makedirs(os.path.dirname(TFLITE_MODEL_PATH), exist_ok=True)
with open(TFLITE_MODEL_PATH, "wb") as f:
    f.write(tflite_model)
    
print(f"SUCCESS! AI Model saved to: {TFLITE_MODEL_PATH}")

# Cleanup
try:
    shutil.rmtree(SAVED_MODEL_DIR)
except Exception:
    pass
print("Phase A is complete.")