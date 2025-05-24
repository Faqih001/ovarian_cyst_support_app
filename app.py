"""
PCOS Risk Assessment App - Simplified Version for Deployment
"""

import streamlit as st
import pandas as pd
import numpy as np
import joblib
import os
from PIL import Image
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    st.set_page_config(
        page_title="PCOS Risk Assessment",
        page_icon="🩺",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    st.title("PCOS Risk Assessment Tool")
    st.markdown("This tool helps assess the risk of Polycystic Ovary Syndrome (PCOS) and ovarian cysts based on your symptoms and health markers.")
    
    # Check for model file
    model_path = os.path.join("ml", "models", "pcos_model.joblib")
    model_exists = os.path.exists(model_path)
    
    st.info("This is a simplified version of the PCOS Risk Assessment tool.")
    
    if not model_exists:
        st.warning(f"Model file not found at {model_path}")
        st.error("The model is currently unavailable. Please try again later or contact support.")
        
        # Display directory structure for debugging
        with st.expander("Troubleshooting Information"):
            st.write("Current directory:", os.getcwd())
            st.write("Directory contents:", os.listdir())
            if os.path.exists("ml"):
                st.write("ML directory contents:", os.listdir("ml"))
                if os.path.exists(os.path.join("ml", "models")):
                    st.write("Models directory contents:", os.listdir(os.path.join("ml", "models")))
    
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
            st.info("This is a demonstration version. The full prediction model is available in the deployed application.")
            
            # Simple demo risk calculation
            risk_factors = [weight_gain, hair_growth, skin_darkening, hair_loss, pimples, fast_food, bmi > 25]
            risk_count = sum(1 for factor in risk_factors if factor)
            risk_score = (risk_count / len(risk_factors)) * 100
            
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
