import tensorflow as tf
import numpy as np
import os
from transformers import TFAutoModel, AutoTokenizer

# Configuration
MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
OUTPUT_DIR = "assets/ai"
TFLITE_MODEL_PATH = os.path.join(OUTPUT_DIR, "model_quant.tflite")
VOCAB_PATH = os.path.join(OUTPUT_DIR, "vocab.txt")

def representative_dataset():
    for _ in range(100):
        input_ids = tf.random.uniform((1, 128), minval=0, maxval=30522, dtype=tf.int32)
        attention_mask = tf.ones((1, 128), dtype=tf.int32)
        yield [input_ids, attention_mask] # List for concrete function args

def export_model():
    print(f"Loading model: {MODEL_NAME}...")
    
    # Save Vocab
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    vocab_file = tokenizer.save_vocabulary(OUTPUT_DIR)
    if isinstance(vocab_file, tuple):
        vocab_path = vocab_file[0]
    else:
        vocab_path = vocab_file
    
    if os.path.basename(vocab_path) != "vocab.txt":
        new_path = os.path.join(OUTPUT_DIR, "vocab.txt")
        if os.path.exists(new_path):
            os.remove(new_path)
        os.rename(vocab_path, new_path)
        print(f"Saved vocab to {new_path}")

    # Load Transformer
    transformer = TFAutoModel.from_pretrained(MODEL_NAME, from_pt=True)

    # Define Concrete Function
    @tf.function(input_signature=[
        tf.TensorSpec([1, 128], tf.int32, name='input_ids'),
        tf.TensorSpec([1, 128], tf.int32, name='attention_mask')
    ])
    def serve(input_ids, attention_mask):
        outputs = transformer(input_ids=input_ids, attention_mask=attention_mask)
        
        token_embeddings = outputs.last_hidden_state
        input_mask_expanded = tf.cast(tf.expand_dims(attention_mask, -1), tf.float32)
        
        sum_embeddings = tf.reduce_sum(token_embeddings * input_mask_expanded, 1)
        sum_mask = tf.clip_by_value(tf.reduce_sum(input_mask_expanded, 1), 1e-9, 1e30)
        
        embeddings = sum_embeddings / sum_mask
        embeddings = tf.nn.l2_normalize(embeddings, axis=1)
        return embeddings

    # Convert
    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_concrete_functions([serve.get_concrete_function()], transformer)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS, tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    
    tflite_model = converter.convert()
    
    with open(TFLITE_MODEL_PATH, "wb") as f:
        f.write(tflite_model)
        
    print(f"Saved TFLite model to {TFLITE_MODEL_PATH}")
    print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")

def validate_model():
    print("\nValidating model...")
    from sentence_transformers import SentenceTransformer
    from sklearn.metrics.pairwise import cosine_similarity
    
    # 1. PyTorch Output
    pt_model = SentenceTransformer(MODEL_NAME)
    test_text = "This is a test sentence for validation."
    pt_embedding = pt_model.encode([test_text])[0]
    
    # 2. TFLite Output
    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    inputs = tokenizer(test_text, max_length=128, padding='max_length', truncation=True, return_tensors="tf")
    
    # Set inputs based on index (0: input_ids, 1: attention_mask usually for concrete func)
    # But let's check names if possible, or just assume order from signature
    
    # Concrete function args are positional.
    interpreter.set_tensor(input_details[0]['index'], inputs['input_ids'])
    interpreter.set_tensor(input_details[1]['index'], inputs['attention_mask'])
            
    interpreter.invoke()
    tflite_embedding = interpreter.get_tensor(output_details[0]['index'])[0]
    
    # 3. Compare
    similarity = cosine_similarity([pt_embedding], [tflite_embedding])[0][0]
    print(f"Cosine Similarity: {similarity:.4f}")
    
    if similarity > 0.95:
        print("SUCCESS: Model validation passed!")
    else:
        print("WARNING: Model validation failed (similarity < 0.95)")

if __name__ == "__main__":
    export_model()
    validate_model()
