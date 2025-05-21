import tensorflow as tf
import numpy as np
import json

def test_model():
    """Test the trained model with sample data."""
    # Load the TFLite model
    interpreter = tf.lite.Interpreter(model_path='../models/pcos_model.tflite')
    interpreter.allocate_tensors()
    
    # Get input and output tensors
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Load scaler parameters
    with open('../models/pcos_scaler.json', 'r') as f:
        scaler_params = json.load(f)
    
    # Sample test data
    test_data = np.array([
        [5.0, 10.0, 15.0],  # Sample 1
        [2.5, 5.0, 7.5],    # Sample 2
        [7.5, 15.0, 22.5]   # Sample 3
    ])
    
    print("Testing model with sample data...")
    
    for i, sample in enumerate(test_data):
        # Scale the input data
        scaled_data = (sample - np.array(scaler_params['mean'])) / np.array(scaler_params['scale'])
        scaled_data = scaled_data.reshape(1, -1).astype(np.float32)
        
        # Set the input tensor
        interpreter.set_tensor(input_details[0]['index'], scaled_data)
        
        # Run inference
        interpreter.invoke()
        
        # Get the output tensor
        output_data = interpreter.get_tensor(output_details[0]['index'])
        probability = float(output_data[0][0])
        
        print(f"\nSample {i+1}:")
        print(f"Input values: AMH={sample[0]}, Beta-HCG I={sample[1]}, Beta-HCG II={sample[2]}")
        print(f"Prediction probability: {probability:.2f}")
        print(f"Predicted class: {'PCOS' if probability >= 0.5 else 'No PCOS'}")

if __name__ == '__main__':
    test_model()
