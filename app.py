"""
PCOS Risk Assessment App - Simplified Version for Deployment
"""

import streamlit as st
import pandas as pd
import numpy as np
import joblib
import os
import sys
import subprocess
import importlib
from PIL import Image
import logging
import requests
import tempfile
import io

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Function to install packages if they aren't already installed
def install_package(package):
    try:
        importlib.import_module(package)
    except ImportError:
        st.info(f"Installing {package}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        st.success(f"{package} installed successfully!")

# Function to download from Google Drive
def download_from_gdrive(file_id, output_path):
    try:
        # First try to install and use gdown
        install_package("gdown")
        import gdown
        url = f'https://drive.google.com/uc?id={file_id}'
        gdown.download(url, output_path, quiet=False)
        return os.path.exists(output_path)
    except Exception as e:
        st.write(f"Error with gdown: {e}")
        
        # Fallback method - direct requests download
        try:
            st.write("Trying direct download...")
            url = f"https://drive.google.com/uc?id={file_id}&export=download"
            session = requests.Session()
            response = session.get(url, stream=True)
            
            # Handle download confirmation "cookies" for large files
            for key, value in response.cookies.items():
                if key.startswith('download_warning'):
                    url = f"{url}&confirm={value}"
                    response = session.get(url, stream=True)
            
            with open(output_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            
            return os.path.exists(output_path)
        except Exception as e2:
            st.write(f"Direct download failed: {e2}")
            return False

def main():
    st.set_page_config(
        page_title="PCOS Risk Assessment",
        page_icon="🩺",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    st.title("PCOS Risk Assessment Tool")
    st.markdown("This tool helps assess the risk of Polycystic Ovary Syndrome (PCOS) and ovarian cysts based on your symptoms and health markers.")
    
    # Try to download the model from Google Drive if it doesn't exist locally
    model_dir = os.path.join("ml", "models")
    model_path = os.path.join(model_dir, "pcos_model.joblib")
    model_exists = os.path.exists(model_path)
    model = None
    
    st.info("Welcome to the PCOS Risk Assessment tool.")
    
    # Google Drive file ID from the shared link
    file_id = "1jL-UIq7lyGDMduNMbZHLKW-TytPgI2MS"
    
    if not model_exists:
        st.warning("Model file not found locally. Attempting to download from Google Drive.")
        
        # Create models directory if it doesn't exist
        os.makedirs(model_dir, exist_ok=True)
        
        # Try to download the model
        download_success = download_from_gdrive(file_id, model_path)
        
        if download_success:
            st.success("Model successfully downloaded!")
            try:
                model = joblib.load(model_path)
                st.success("Model loaded successfully!")
            except Exception as e:
                st.error(f"Error loading model: {str(e)}")
                model = None
        else:
            st.warning("Could not download the model. Using simplified risk assessment.")
    else:
        # Model exists, try to load it
        try:
            model = joblib.load(model_path)
            st.success("Model loaded successfully!")
        except Exception as e:
            st.error(f"Error loading model: {str(e)}")
            model = None
    
    # Display directory structure for debugging if model was not loaded
    if model is None:
        with st.expander("Troubleshooting Information"):
            st.write("Current directory:", os.getcwd())
            st.write("Directory contents:", os.listdir())
            if os.path.exists("ml"):
                st.write("ML directory contents:", os.listdir("ml"))
                if os.path.exists(model_dir):
                    st.write("Models directory contents:", os.listdir(model_dir))
    
    # Simple form for demonstration
    with st.form("demo_form"):
        st.subheader("Basic Information")
        col1, col2 = st.columns(2)
        
        with col1:
            age = st.number_input("Age (years)", min_value=15, max_value=50, value=25)
            weight = st.number_input("Weight (kg)", min_value=30.0, max_value=150.0, value=60.0)
            height = st.number_input("Height (cm)", min_value=140.0, max_value=200.0, value=160.0)
            
        with col2:
            bmi = st.number_input("BMI", min_value=15.0, max_value=45.0, value=weight / ((height/100)**2))
            pulse_rate = st.number_input("Pulse Rate (bpm)", min_value=60.0, max_value=120.0, value=75.0)
            respiratory_rate = st.number_input("Respiratory Rate", min_value=12.0, max_value=25.0, value=16.0)
            
        st.subheader("Symptom Information")
        col3, col4 = st.columns(2)
        
        with col3:
            weight_gain = st.checkbox("Weight Gain")
            hair_growth = st.checkbox("Excessive Hair Growth")
            skin_darkening = st.checkbox("Skin Darkening")
            
        with col4:
            hair_loss = st.checkbox("Hair Loss")
            pimples = st.checkbox("Pimples")
            fast_food = st.checkbox("Regular Fast Food")
            
        submit_button = st.form_submit_button("Assess Risk")
        
        if submit_button:
            if model is not None:
                try:
                    # Use the trained model for prediction
                    st.info("Using trained PCOS prediction model...")
                    
                    # Convert inputs to the format expected by the model
                    blood_group_num = 1  # Default to A+
                    
                    # Extract only the features needed for the model in the correct order
                    # This order has been simplified from the original model for deployment
                    features = [
                        age,
                        weight,
                        height, 
                        bmi,
                        1 if weight_gain else 0,  # Weight gain
                        1 if hair_growth else 0,  # Hair growth
                        1 if skin_darkening else 0,  # Skin darkening
                        1 if hair_loss else 0,  # Hair loss
                        1 if pimples else 0,  # Pimples
                        1 if fast_food else 0,  # Fast food
                        0 if fast_food else 1,  # Regular exercise (inverse of fast food as approximation)
                        blood_group_num  # Blood group (default to 1)
                    ]
                    
                    # Make prediction using the model
                    try:
                        prediction_result = model.predict_proba([features])[0][1]
                        risk_score = prediction_result * 100  # Convert to percentage
                    except Exception as e:
                        st.error(f"Error during prediction: {str(e)}")
                        # Fall back to simplified calculation
                        risk_factors = [weight_gain, hair_growth, skin_darkening, hair_loss, pimples, fast_food, bmi > 25]
                        risk_count = sum(1 for factor in risk_factors if factor)
                        risk_score = (risk_count / len(risk_factors)) * 100
                except Exception as e:
                    st.error(f"Error using model: {str(e)}")
                    # Fall back to simplified calculation
                    risk_factors = [weight_gain, hair_growth, skin_darkening, hair_loss, pimples, fast_food, bmi > 25]
                    risk_count = sum(1 for factor in risk_factors if factor)
                    risk_score = (risk_count / len(risk_factors)) * 100
            else:
                st.info("Using simplified risk assessment method.")
                # Simple demo risk calculation
                risk_factors = [weight_gain, hair_growth, skin_darkening, hair_loss, pimples, fast_food, bmi > 25]
                risk_count = sum(1 for factor in risk_factors if factor)
                risk_score = (risk_count / len(risk_factors)) * 100
            
            # Display risk level
            if risk_score < 30:
                risk_level = "Low"
                st.success(f"Your estimated risk level is: {risk_level} ({risk_score:.1f}%)")
            elif risk_score < 70:
                risk_level = "Moderate"
                st.warning(f"Your estimated risk level is: {risk_level} ({risk_score:.1f}%)")
            else:
                risk_level = "High"
                st.error(f"Your estimated risk level is: {risk_level} ({risk_score:.1f}%)")
                
            # Display some recommendations
            st.subheader("General Recommendations")
            st.markdown("""
            - 👩‍⚕️ Consult with a healthcare provider for a proper diagnosis
            - 📊 Monitor your symptoms regularly
            - 🥗 Maintain a balanced diet
            - 🏃‍♀️ Regular exercise is recommended
            - 😌 Practice stress management techniques
            """)
    
    st.markdown("---")
    st.info("This is a part of the Ovarian Cyst Support App project")
    st.write("ℹ️ Note: This is a simplified version for demonstration purposes.")

if __name__ == "__main__":
    main()
