import tensorflow as tf

interpreter = tf.lite.Interpreter(model_path='assets/ai/LaBSE_encoder.tflite')
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
print(input_details[0])
