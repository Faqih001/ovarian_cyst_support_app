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
st.title("PCOS Risk Assessment")
st.write("This service provides PCOS risk assessment predictions based on various health indicators.")

# Create input form
with st.form("prediction_form"):
    # Basic Information
    st.subheader("Basic Information")
    col1, col2 = st.columns(2)
    with col1:
        age = st.number_input("Age", min_value=0, max_value=100, value=25, step=1)
        weight = st.number_input("Weight", min_value=30, max_value=200, value=65, help="Weight in kg")
        height = st.number_input("Height", min_value=100, max_value=250, value=165, help="Height in cm")
    with col2:
        bmi = weight / ((height/100) ** 2)
        st.write(f"BMI: {bmi:.2f}")
        blood_group = st.selectbox("Blood Group", ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"])

    # Vital Signs
    st.subheader("Vital Signs")
    col1, col2 = st.columns(2)
    with col1:
        pulse_rate = st.number_input("Pulse Rate", min_value=40, max_value=200, value=80, help="Beats per minute")
        respiratory_rate = st.number_input("Respiratory Rate", min_value=8, max_value=40, value=16, help="Breaths per minute")
        hemoglobin = st.number_input("Hemoglobin", min_value=4.0, max_value=20.0, value=12.0, help="g/dL")
    with col2:
        bp_systolic = st.number_input("BP Systolic", min_value=70, max_value=200, value=120, help="mmHg")
        bp_diastolic = st.number_input("BP Diastolic", min_value=40, max_value=130, value=80, help="mmHg")

    # Menstrual History
    st.subheader("Menstrual History")
    cycle_regularity = st.checkbox("Regular Cycle")
    cycle_length = st.number_input("Cycle Length", min_value=20, max_value=45, value=28, help="days")

    # Physical Measurements
    st.subheader("Physical Measurements")
    col1, col2 = st.columns(2)
    with col1:
        waist = st.number_input("Waist", min_value=20, max_value=200, value=32, help="inches")
        hip = st.number_input("Hip", min_value=25, max_value=200, value=40, help="inches")
    waist_hip_ratio = waist / hip if hip != 0 else 0
    st.write(f"Waist-Hip Ratio: {waist_hip_ratio:.2f}")

    # Hormonal Tests
    st.subheader("Hormonal Tests")
    col1, col2 = st.columns(2)
    with col1:
        fsh = st.number_input("FSH", value=6.0, help="mIU/mL")
        lh = st.number_input("LH", value=5.0, help="mIU/mL")
        tsh = st.number_input("TSH", value=2.5, help="mIU/L")
        amh = st.number_input("AMH", value=4.2, help="ng/mL")
    with col2:
        prl = st.number_input("Prolactin", value=15.0, help="ng/mL")
        vit_d3 = st.number_input("Vitamin D3", value=30.0, help="ng/mL")
        prg = st.number_input("Progesterone", value=10.0, help="ng/mL")

    # Ultrasound Findings
    st.subheader("Ultrasound Findings")
    col1, col2 = st.columns(2)
    with col1:
        follicle_l = st.number_input("Left Ovary Follicle Count", min_value=0, max_value=30, value=8)
        follicle_r = st.number_input("Right Ovary Follicle Count", min_value=0, max_value=30, value=8)
    with col2:
        avg_f_size_l = st.number_input("Left Follicle Size", value=15.0, help="mm")
        avg_f_size_r = st.number_input("Right Follicle Size", value=15.0, help="mm")
    endometrium = st.number_input("Endometrium Thickness", value=8.0, help="mm")

    # Additional Information
    st.subheader("Additional Information")
    col1, col2 = st.columns(2)
    with col1:
        marriage_status = st.number_input("Marriage Status", min_value=0, max_value=50, value=0, help="years")
        abortions = st.number_input("Number of Abortions", min_value=0, max_value=10, value=0)
    with col2:
        rbs = st.number_input("Random Blood Sugar", value=85.0, help="mg/dL")

    # Symptoms & Lifestyle
    st.subheader("Symptoms & Lifestyle")
    col1, col2 = st.columns(2)
    with col1:
        pregnant = st.checkbox("Pregnant")
        weight_gain = st.checkbox("Weight Gain")
        hair_growth = st.checkbox("Hair Growth")
        skin_darkening = st.checkbox("Skin Darkening")
    with col2:
        hair_loss = st.checkbox("Hair Loss")
        pimples = st.checkbox("Pimples")
        fast_food = st.checkbox("Fast Food")
        regular_exercise = st.checkbox("Regular Exercise")

    submitted = st.form_submit_button("Calculate Risk")

    if submitted and model is not None:
        try:
            # Convert boolean fields to integers
            boolean_fields = {
                "pregnant": pregnant,
                "weight_gain": weight_gain,
                "hair_growth": hair_growth,
                "skin_darkening": skin_darkening,
                "hair_loss": hair_loss,
                "pimples": pimples,
                "fast_food": fast_food,
                "regular_exercise": regular_exercise,
            }
            boolean_ints = {k: 1 if v else 0 for k, v in boolean_fields.items()}

            # Blood group to numeric
            blood_groups = {
                "A+": 1, "A-": 2, "B+": 3, "B-": 4,
                "O+": 5, "O-": 6, "AB+": 7, "AB-": 8
            }
            blood_group_num = blood_groups.get(blood_group, 1)

            # Prepare input data
            input_data = {
                "age": age,
                "weight": weight,
                "height": height,
                "bmi": bmi,
                "blood_group": blood_group_num,
                "pulse_rate": pulse_rate,
                "rr": respiratory_rate,
                "hb": hemoglobin,
                "cycle_ri": 1 if cycle_regularity else 0,
                "cycle_length": cycle_length,
                "marriage_status": marriage_status,
                "pregnant": boolean_ints["pregnant"],
                "no_of_abortions": abortions,
                "waist_hip_ratio": waist_hip_ratio,
                "tsh": tsh,
                "amh": amh,
                "prl": prl,
                "vit_d3": vit_d3,
                "prg": prg,
                "rbs": rbs,
                "weight_gain": boolean_ints["weight_gain"],
                "hair_growth": boolean_ints["hair_growth"],
                "skin_darkening": boolean_ints["skin_darkening"],
                "hair_loss": boolean_ints["hair_loss"],
                "pimples": boolean_ints["pimples"],
                "fast_food": boolean_ints["fast_food"],
                "regular_exercise": boolean_ints["regular_exercise"],
                "bp_systolic": bp_systolic,
                "bp_diastolic": bp_diastolic,
                "follicle_l": follicle_l,
                "follicle_r": follicle_r,
                "avg_f_size_l": avg_f_size_l,
                "avg_f_size_r": avg_f_size_r,
                "endometrium": endometrium,
                "fsh": fsh,
                "lh": lh,
                "fsh_lh_ratio": fsh/lh if lh > 0 else 1.2,
            }

            # Make prediction
            input_df = pd.DataFrame([input_data])
            risk_probability = float(model.predict_proba(input_df)[0][1])
            feature_importance = dict(zip(input_df.columns, model.feature_importances_))

            # Show results
            st.success(f"Risk Score: {risk_probability:.2%}")
            
            # Determine stage and recommendations
            if risk_probability < 0.3:
                st.info("Stage: Low Risk")
                recommendations = [
                    "Continue regular health check-ups",
                    "Maintain a healthy lifestyle",
                    "Track your menstrual cycle"
                ]
            elif risk_probability < 0.7:
                st.warning("Stage: Moderate Risk")
                recommendations = [
                    "Schedule a consultation with a gynecologist",
                    "Consider hormonal tests",
                    "Monitor symptoms closely",
                    "Improve diet and exercise routine"
                ]
            else:
                st.error("Stage: High Risk")
                recommendations = [
                    "Seek immediate medical attention",
                    "Complete hormonal panel testing recommended",
                    "Regular monitoring of ovarian cysts",
                    "Consider medical treatment options",
                    "Make lifestyle modifications"
                ]

            # Show recommendations
            st.subheader("Recommendations")
            for rec in recommendations:
                st.write(f"• {rec}")

            # Show top contributing factors
            st.subheader("Top Contributing Factors")
            sorted_features = dict(sorted(feature_importance.items(), key=lambda x: x[1], reverse=True)[:5])
            for feature, importance in sorted_features.items():
                st.write(f"• {feature}: {importance:.1%}")

        except Exception as e:
            st.error(f"Error making prediction: {str(e)}")

# Footer
st.markdown("---")
st.markdown("*This is a part of the Ovarian Cyst Support App*")
