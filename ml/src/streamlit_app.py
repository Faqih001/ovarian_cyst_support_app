import streamlit as st
import joblib
import os
import numpy as np
import pandas as pd

def load_model_and_scaler():
    """Load the trained model and scaler."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    models_dir = os.path.join(script_dir, "..", "models")
    
    model = joblib.load(os.path.join(models_dir, 'pcos_model.joblib'))
    scaler = joblib.load(os.path.join(models_dir, 'scaler.joblib'))
    
    with open(os.path.join(models_dir, 'feature_names.txt'), 'r') as f:
        feature_names = f.read().splitlines()
    
    return model, scaler, feature_names

def main():
    st.set_page_config(
        page_title="PCOS Risk Assessment",
        page_icon="🏥",
        layout="wide"
    )
    
    st.title("PCOS Risk Assessment")
    st.markdown("""
    This application helps assess the risk of Polycystic Ovary Syndrome (PCOS) based on various symptoms and lifestyle factors.
    Please answer all questions accurately for the best results.
    """)
    
    try:
        model, scaler, feature_names = load_model_and_scaler()
        
        with st.form("prediction_form"):
            st.subheader("Patient Information")
            
            col1, col2 = st.columns(2)
            
            with col1:
                pregnant = st.selectbox("Are you pregnant?", ["No", "Yes"])
                weight_gain = st.selectbox("Have you experienced weight gain?", ["No", "Yes"])
                hair_growth = st.selectbox("Do you have excessive hair growth?", ["No", "Yes"])
                skin_darkening = st.selectbox("Have you noticed skin darkening?", ["No", "Yes"])
                
            with col2:
                hair_loss = st.selectbox("Are you experiencing hair loss?", ["No", "Yes"])
                pimples = st.selectbox("Do you have pimples?", ["No", "Yes"])
                fast_food = st.selectbox("Do you frequently eat fast food?", ["No", "Yes"])
                regular_exercise = st.selectbox("Do you exercise regularly?", ["No", "Yes"])
                
            blood_group = st.selectbox("Blood Group", ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"])
            
            submitted = st.form_submit_button("Predict PCOS Risk")
            
            if submitted:
                # Convert inputs to model format
                blood_group_map = {'A+': 0, 'A-': 1, 'B+': 2, 'B-': 3, 'O+': 4, 'O-': 5, 'AB+': 6, 'AB-': 7}
                
                input_data = {
                    "Pregnant(Y/N)": 1 if pregnant == "Yes" else 0,
                    "Weight gain(Y/N)": 1 if weight_gain == "Yes" else 0,
                    "hair growth(Y/N)": 1 if hair_growth == "Yes" else 0,
                    "Skin darkening (Y/N)": 1 if skin_darkening == "Yes" else 0,
                    "Hair loss(Y/N)": 1 if hair_loss == "Yes" else 0,
                    "Pimples(Y/N)": 1 if pimples == "Yes" else 0,
                    "Fast food (Y/N)": 1 if fast_food == "Yes" else 0,
                    "Reg.Exercise(Y/N)": 1 if regular_exercise == "Yes" else 0,
                    "Blood Group": blood_group_map[blood_group]
                }
                
                # Create feature vector
                X = pd.DataFrame([input_data])[feature_names]
                
                # Scale features
                X_scaled = scaler.transform(X)
                
                # Get prediction and probability
                prediction = model.predict(X_scaled)[0]
                probability = model.predict_proba(X_scaled)[0][1]
                
                # Display results
                st.subheader("Results")
                
                if prediction == 1:
                    st.warning("⚠️ High Risk of PCOS")
                    risk_text = "High Risk"
                else:
                    st.success("✅ Low Risk of PCOS")
                    risk_text = "Low Risk"
                
                # Show probability gauge
                st.markdown(f"### Risk Assessment: {risk_text}")
                st.progress(probability)
                st.write(f"Probability: {probability:.1%}")
                
                # Display risk factors
                st.subheader("Risk Factor Analysis")
                feature_importance = model.feature_importances_
                risk_factors = pd.DataFrame({
                    'Factor': feature_names,
                    'Importance': feature_importance,
                    'Your Value': [input_data[f] for f in feature_names]
                })
                risk_factors = risk_factors.sort_values('Importance', ascending=False)
                
                st.write("Top contributing factors to your risk assessment:")
                st.dataframe(risk_factors)
                
                # Add recommendations
                st.subheader("Recommendations")
                if prediction == 1:
                    st.markdown("""
                    Based on your responses, here are some recommendations:
                    1. 👩‍⚕️ **Consult a Healthcare Provider**: Schedule an appointment with a gynecologist for a proper evaluation
                    2. 📝 **Keep a Symptom Diary**: Track your symptoms and their frequency
                    3. 💪 **Lifestyle Changes**:
                        - Maintain a balanced diet
                        - Exercise regularly
                        - Manage stress levels
                    4. 🏥 **Further Testing**: Your healthcare provider may recommend:
                        - Hormonal tests
                        - Ultrasound
                        - Blood sugar levels
                    """)
                else:
                    st.markdown("""
                    While your risk appears low, it's still important to:
                    1. 🏃‍♀️ Maintain a healthy lifestyle
                    2. 📅 Have regular check-ups
                    3. 🚨 Monitor any changes in symptoms
                    """)
                
                # Add disclaimer
                st.info("""
                **Disclaimer**: This tool provides a risk assessment based on the information you've provided. 
                It is not a diagnosis. Always consult with healthcare professionals for medical advice and diagnosis.
                """)
    
    except Exception as e:
        st.error(f"An error occurred: {str(e)}")
        st.info("""
        If you're seeing this error, please make sure:
        1. The model files are in the correct location
        2. You have all required dependencies installed
        3. You're running the app from the correct directory
        """)

if __name__ == "__main__":
    main()
