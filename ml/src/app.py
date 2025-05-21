import streamlit as st
import tensorflow as tf
import numpy as np
import json
import os

# Set page config
st.set_page_config(
    page_title="PCOS Prediction",
    page_icon="🏥",
    layout="wide"
)

# Load the TFLite model
@st.cache_resource
def load_model():
    interpreter = tf.lite.Interpreter(model_path='../models/pcos_model.tflite')
    interpreter.allocate_tensors()
    return interpreter

# Load scaler parameters
@st.cache_data
def load_scaler():
    with open('../models/pcos_scaler.json', 'r') as f:
        return json.load(f)

def main():
    st.title("PCOS Prediction System")
    st.write("Enter the following clinical parameters to predict PCOS risk")

    # Load model and scaler
    try:
        interpreter = load_model()
        scaler_params = load_scaler()
        
        # Get input and output tensors
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        # Create input form
        with st.form("prediction_form"):
            st.write("### Clinical Parameters")
            col1, col2, col3 = st.columns(3)
            
            with col1:
                amh = st.number_input("AMH (ng/mL)", 
                                    min_value=0.0, 
                                    max_value=20.0,
                                    help="Anti-Müllerian Hormone level")
            
            with col2:
                beta_hcg_1 = st.number_input("Beta-HCG I (mIU/mL)", 
                                           min_value=0.0,
                                           max_value=200.0,
                                           help="First Beta-HCG measurement")
            
            with col3:
                beta_hcg_2 = st.number_input("Beta-HCG II (mIU/mL)", 
                                           min_value=0.0,
                                           max_value=200.0,
                                           help="Second Beta-HCG measurement")

            submitted = st.form_submit_button("Predict")

            if submitted:
                # Prepare input data
                input_data = np.array([[amh, beta_hcg_1, beta_hcg_2]], dtype=np.float32)
                
                # Scale the input data
                scaled_data = (input_data - np.array(scaler_params['mean'])) / np.array(scaler_params['scale'])
                
                # Set the input tensor
                interpreter.set_tensor(input_details[0]['index'], scaled_data)
                
                # Run inference
                interpreter.invoke()
                
                # Get the output tensor
                output_data = interpreter.get_tensor(output_details[0]['index'])
                
                probability = float(output_data[0][0])
                prediction = "High Risk" if probability >= 0.5 else "Low Risk"
                
                # Display results
                st.write("### Results")
                st.write(f"PCOS Risk Category: **{prediction}**")
                st.progress(probability)
                st.write(f"Probability: {probability:.2%}")
                
                if probability >= 0.5:
                    st.warning("Please consult with a healthcare provider for a thorough evaluation.")
                else:
                    st.success("Your results indicate lower risk, but always consult with healthcare providers for any concerns.")

    except Exception as e:
        st.error(f"Error loading model or making prediction: {str(e)}")
        st.info("Please make sure the model and scaler files are present in the correct location.")

if __name__ == "__main__":
    main()
