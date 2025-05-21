import streamlit as st
import pandas as pd
import joblib
from pydantic import BaseModel

# Load the model
@st.cache_resource
def load_model():
    return joblib.load("models/pcos_model.joblib")

try:
    model = load_model()
except Exception as e:
    st.error(f"Error loading model: {str(e)}")
    model = None

# Title and description
st.title("PCOS Risk Assessment API")
st.write("This service provides PCOS risk assessment predictions.")

# Create input form
st.header("Enter Health Information")

with st.form("prediction_form"):
    # Basic Information
    st.subheader("Basic Information")
    col1, col2 = st.columns(2)
    with col1:
        age = st.number_input("Age", min_value=0, max_value=100, value=25)
        weight = st.number_input("Weight (kg)", min_value=30, max_value=200, value=65)
    with col2:
        height = st.number_input("Height (cm)", min_value=100, max_value=250, value=165)
        bmi = weight / ((height/100) ** 2)

    # Vital Signs
    st.subheader("Vital Signs")
    col1, col2 = st.columns(2)
    with col1:
        pulse_rate = st.number_input("Pulse Rate (bpm)", min_value=40, max_value=200, value=80)
        bp_systolic = st.number_input("BP Systolic", min_value=70, max_value=200, value=120)
    with col2:
        rr = st.number_input("Respiratory Rate", min_value=10, max_value=40, value=20)
        bp_diastolic = st.number_input("BP Diastolic", min_value=40, max_value=130, value=80)

    # Other measurements
    st.subheader("Clinical Measurements")
    col1, col2 = st.columns(2)
    with col1:
        waist = st.number_input("Waist (inches)", min_value=20, max_value=80, value=32)
        hip = st.number_input("Hip (inches)", min_value=25, max_value=100, value=40)
    waist_hip_ratio = waist / hip if hip != 0 else 0

    # Symptoms
    st.subheader("Symptoms")
    col1, col2 = st.columns(2)
    with col1:
        weight_gain = st.checkbox("Weight Gain")
        hair_growth = st.checkbox("Hair Growth")
        skin_darkening = st.checkbox("Skin Darkening")
    with col2:
        hair_loss = st.checkbox("Hair Loss")
        pimples = st.checkbox("Pimples")
        fast_food = st.checkbox("Fast Food")

    # Submit button
    submitted = st.form_submit_button("Calculate Risk")

    if submitted and model is not None:
        try:
            # Prepare input data
            input_data = {
                "age": age,
                "weight": weight,
                "height": height,
                "bmi": bmi,
                "blood_group": 1,  # default to A+
                "pulse_rate": pulse_rate,
                "rr": rr,
                "bp_systolic": bp_systolic,
                "bp_diastolic": bp_diastolic,
                "waist_hip_ratio": waist_hip_ratio,
                "weight_gain": int(weight_gain),
                "hair_growth": int(hair_growth),
                "skin_darkening": int(skin_darkening),
                "hair_loss": int(hair_loss),
                "pimples": int(pimples),
                "fast_food": int(fast_food),
                "regular_exercise": 0,
                "cycle_ri": 1,
                "cycle_length": 28,
                "marriage_status": 0,
                "pregnant": 0,
                "no_of_abortions": 0,
                "tsh": 2.5,
                "amh": 4.2,
                "prl": 15,
                "vit_d3": 30,
                "prg": 10,
                "rbs": 85,
                "follicle_l": 8,
                "follicle_r": 8,
                "avg_f_size_l": 15,
                "avg_f_size_r": 15,
                "endometrium": 8
            }

            # Create DataFrame
            input_df = pd.DataFrame([input_data])
            
            # Make prediction
            risk_probability = float(model.predict_proba(input_df)[0][1])
            
            # Show results
            st.success(f"Risk Score: {risk_probability:.2%}")
            
            if risk_probability < 0.3:
                st.info("Low Risk")
            elif risk_probability < 0.7:
                st.warning("Moderate Risk")
            else:
                st.error("High Risk")
                
            # Show recommendations
            st.subheader("Recommendations")
            if risk_probability < 0.3:
                recommendations = [
                    "Continue regular health check-ups",
                    "Maintain a healthy lifestyle",
                    "Track your menstrual cycle"
                ]
            elif risk_probability < 0.7:
                recommendations = [
                    "Schedule a consultation with a gynecologist",
                    "Consider hormonal tests",
                    "Monitor symptoms closely",
                    "Improve diet and exercise routine"
                ]
            else:
                recommendations = [
                    "Seek immediate medical attention",
                    "Complete hormonal panel testing recommended",
                    "Regular monitoring of ovarian cysts",
                    "Consider medical treatment options",
                    "Make lifestyle modifications"
                ]
                
            for rec in recommendations:
                st.write(f"• {rec}")
                
        except Exception as e:
            st.error(f"Error making prediction: {str(e)}")

# Footer
st.markdown("---")
st.markdown("*This is a part of the Ovarian Cyst Support App*")
