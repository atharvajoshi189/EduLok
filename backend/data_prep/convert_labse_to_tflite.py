import tensorflow as tf
from transformers import TFAutoModel, AutoTokenizer
import os

# --- Config ---
MODEL_NAME = "sentence-transformers/LaBSE"
MAX_SEQ_LENGTH = 128

PROJECT_ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
OUTPUT_TFLITE_PATH = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'LaBSE_encoder.tflite')
OUTPUT_SAVEDMODEL_PATH = os.path.join(PROJECT_ROOT, 'assets', 'ai', 'labse_savedmodel')

print("--- Downloading Huggingface Model ---")
model = TFAutoModel.from_pretrained(MODEL_NAME, from_pt=True)
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

# --- Keras Model Wrapper (with fixed input shape) ---
input_ids = tf.keras.Input(shape=(MAX_SEQ_LENGTH,), dtype=tf.int32, name="input_ids")
attention_mask = tf.keras.Input(shape=(MAX_SEQ_LENGTH,), dtype=tf.int32, name="attention_mask")
outputs = model(input_ids=input_ids, attention_mask=attention_mask)
# For LaBSE, use [CLS] embedding: outputs.last_hidden_state[:,0,:]
cls_token = tf.keras.layers.Lambda(lambda x: x[:,0,:])(outputs.last_hidden_state)
keras_model = tf.keras.Model(inputs=[input_ids, attention_mask], outputs=cls_token)

print("--- Saving as TensorFlow SavedModel ---")
keras_model.save(OUTPUT_SAVEDMODEL_PATH, overwrite=True, include_optimizer=False)

print("--- Converting to TFLite ---")
converter = tf.lite.TFLiteConverter.from_saved_model(OUTPUT_SAVEDMODEL_PATH)
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open(OUTPUT_TFLITE_PATH, 'wb') as f:
    f.write(tflite_model)

print(f"\n✅ Success! TFLite model saved at: {OUTPUT_TFLITE_PATH}")
print(f"\n⚡ Input shape: [1, {MAX_SEQ_LENGTH}] (input_ids + attention_mask)")
print("Done.")

# Tokenizer info
print("Tokenizer files downloaded in Huggingface cache. Use sentencepiece.model as per LaBSE docs.")
