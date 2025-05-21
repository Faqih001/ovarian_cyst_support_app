"""
PCOS Risk Assessment Web Application using Streamlit.
This module provides a web interface for predicting PCOS risk.
"""

from io import BytesIO
import streamlit as st
import pandas as pd
import numpy as np
import requests
import joblib
from catboost import CatBoostClassifier

@st.cache_resource
def load_model():
    """
    Load the model from Google Drive.
    Retu                st.markdown("#### Ongoing Monitoring & Support 📈")
                st.write("- 🏥 Regular medical monitoring:")
                st.write("  • 🔍 Weekly ultrasound checks")
                st.write("  • 🩺 Pain level assessment")
                st.write("  • 🌡️ Temperature monitoring")
                st.write("  • 💉 Blood test follow-ups")
                
                st.markdown("#### Fertility Considerations 👶")
                st.write("- 🤰 If planning pregnancy:")
                st.write("  • Fertility preservation options")
                st.write("  • Egg freezing consultation")
                st.write("  • Reproductive planning")
                
                st.markdown("#### Support Resources 🤝")
                st.write("- 💞 Emotional support:")
                st.write("  • 👥 Support groups")
                st.write("  • 🧠 Counseling services")
                st.write("  • 📱 Patient advocacy resources")
                st.write("- 📚 Educational materials")
                st.write("- 🆘 Emergency contact numbers")Scikit-learn model or None if loading fails
    """
    try:
        model_url = "https://drive.google.com/uc?export=download&id=1jL-UIq7lyGDMduNMbZHLKW-TytPgI2MS"
        
        if "model" not in st.session_state:
            st.session_state.model = None
            try:
                response = requests.get(model_url)
                model_bytes = BytesIO(response.content)
                st.session_state.model = joblib.load(model_bytes)
                return st.session_state.model
            except Exception as e:
                st.error(f"Error downloading model: {str(e)}")
                return None
        return st.session_state.model
    except Exception as e:
        st.error(f"Error loading model: {str(e)}")
        return None

def predict_probability(model, features):
    """
    Make prediction using scikit-learn model.
    Args:
        model: Scikit-learn model
        features: List of input features
    Returns:
        Probability of PCOS risk
    """
    try:
        # Convert features to numpy array
        X = np.array(features).reshape(1, -1)
        # Get probability prediction
        probabilities = model.predict_proba(X)
        return float(probabilities[0][1])
    except Exception as e:
        st.error(f"Error in prediction: {str(e)}")
        return None

def fallback_predict(input_data):
    """
    Simple rule-based prediction when model is not available.
    Args:
        input_data: Dictionary of input features
    Returns:
        Risk probability between 0 and 1
    """
    risk_factors = 0
    risk_factors += input_data["bmi"] > 25
    risk_factors += input_data["waist_hip_ratio"] > 0.85
    risk_factors += input_data["cycle_regularity"] == 0  # Irregular cycle
    risk_factors += input_data["weight_gain"] == 1
    risk_factors += input_data["skin_darkening"] == 1
    risk_factors += input_data["hair_growth"] == 1
    risk_factors += input_data["pimples"] == 1
    
    return min(0.9, risk_factors / 10)

# Initialize the model
model = load_model()

# Streamlit UI
st.title('PCOS Risk Assessment')
st.write('Enter your health information for PCOS risk assessment.')

with st.form("prediction_form"):
    # Basic Information
    st.subheader("Basic Information")
    col1, col2 = st.columns(2)
    with col1:
        age = st.number_input("Age (years)", min_value=15, max_value=50, value=25)
        weight = st.number_input("Weight (kg)", min_value=30.0, max_value=150.0, value=60.0)
        height = st.number_input("Height (cm)", min_value=140.0, max_value=200.0, value=160.0)
    with col2:
        bmi = weight / ((height/100) ** 2)
        st.number_input("BMI", value=bmi, disabled=True)
        blood_group = st.selectbox("Blood Group", 
            ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'])

    # Vital Signs
    st.subheader("Vital Signs")
    col1, col2 = st.columns(2)
    with col1:
        pulse_rate = st.number_input("Pulse Rate (bpm)", min_value=40, max_value=200)
        rr = st.number_input("Respiratory Rate (breaths/min)", min_value=8, max_value=40)
        bp_systolic = st.number_input("BP Systolic (mmHg)", min_value=70, max_value=200)
    with col2:
        hb = st.number_input("Hemoglobin (g/dl)", min_value=5.0, max_value=20.0)
        bp_diastolic = st.number_input("BP Diastolic (mmHg)", min_value=40, max_value=130)

    # Menstrual History
    st.subheader("Menstrual History")
    col1, col2 = st.columns(2)
    with col1:
        cycle_regularity = st.checkbox("Regular Menstrual Cycle", value=True)
        cycle_length = st.number_input("Cycle Length (days)", min_value=20, max_value=40, value=28)

    # Physical Measurements
    st.subheader("Physical Measurements")
    col1, col2 = st.columns(2)
    with col1:
        waist = st.number_input("Waist (inch)", min_value=20.0, max_value=60.0)
        hip = st.number_input("Hip (inch)", min_value=25.0, max_value=80.0)
    with col2:
        if waist > 0 and hip > 0:
            waist_hip_ratio = waist / hip
            st.number_input("Waist-Hip Ratio", value=waist_hip_ratio, disabled=True)

    # Hormonal Tests
    st.subheader("Hormonal Tests")
    col1, col2 = st.columns(2)
    with col1:
        fsh = st.number_input("FSH (mIU/mL)", min_value=0.0, max_value=200.0)
        lh = st.number_input("LH (mIU/mL)", min_value=0.0, max_value=200.0)
        tsh = st.number_input("TSH (mIU/L)", min_value=0.0, max_value=50.0)
        amh = st.number_input("AMH (ng/mL)", min_value=0.0, max_value=20.0)
        prl = st.number_input("Prolactin (ng/mL)", min_value=0.0, max_value=200.0)
    with col2:
        vit_d3 = st.number_input("Vitamin D3 (ng/mL)", min_value=0.0, max_value=100.0)
        prg = st.number_input("Progesterone (ng/mL)", min_value=0.0, max_value=50.0)
        beta_hcg1 = st.number_input("Beta HCG-1 (mIU/mL)", min_value=0.0, max_value=1000.0)
        beta_hcg2 = st.number_input("Beta HCG-2 (mIU/mL)", min_value=0.0, max_value=1000.0)

    # Ultrasound Findings
    st.subheader("Ultrasound Findings")
    col1, col2 = st.columns(2)
    with col1:
        follicle_l = st.number_input("Left Ovary Follicle Count", min_value=0, max_value=30)
        follicle_r = st.number_input("Right Ovary Follicle Count", min_value=0, max_value=30)
        avg_f_size_l = st.number_input("Left Follicle Size (mm)", min_value=0.0, max_value=30.0)
    with col2:
        avg_f_size_r = st.number_input("Right Follicle Size (mm)", min_value=0.0, max_value=30.0)
        endometrium = st.number_input("Endometrium Thickness (mm)", min_value=0.0, max_value=30.0)

    # Additional Information
    st.subheader("Additional Information")
    col1, col2 = st.columns(2)
    with col1:
        marriage_status = st.number_input("Marriage Status (years)", min_value=0, max_value=40)
        abortions = st.number_input("Number of Abortions", min_value=0, max_value=10)
        rbs = st.number_input("Random Blood Sugar (mg/dl)", min_value=50.0, max_value=500.0)

    # Symptoms & Lifestyle
    st.subheader("Symptoms & Lifestyle")
    col1, col2 = st.columns(2)
    with col1:
        pregnant = st.checkbox("Pregnant")
        weight_gain = st.checkbox("Weight gain")
        hair_growth = st.checkbox("Hair growth")
        skin_darkening = st.checkbox("Skin darkening")
    with col2:
        hair_loss = st.checkbox("Hair loss")
        pimples = st.checkbox("Pimples")
        fast_food = st.checkbox("Fast food")
        regular_exercise = st.checkbox("Regular Exercise")

    submitted = st.form_submit_button("Calculate Risk")

    if submitted:
        try:
            # Prepare input data matching the model's expected format
            input_data = {
                "age": age,
                "weight": weight,
                "height": height,
                "bmi": bmi,
                "pulse_rate": pulse_rate,
                "rr": rr,
                "hb": hb,
                "cycle_length": cycle_length,
                "cycle_regularity": 1 if cycle_regularity else 0,
                "marriage_status": marriage_status,
                "waist": waist,
                "hip": hip,
                "waist_hip_ratio": waist / hip if waist > 0 and hip > 0 else 0,
                "tsh": tsh,
                "amh": amh,
                "prl": prl,
                "vit_d3": vit_d3,
                "prg": prg,
                "rbs": rbs,
                "bp_systolic": bp_systolic,
                "bp_diastolic": bp_diastolic,
                "follicle_l": follicle_l,
                "follicle_r": follicle_r,
                "avg_f_size_l": avg_f_size_l,
                "avg_f_size_r": avg_f_size_r,
                "endometrium": endometrium,
                "pregnant": 1 if pregnant else 0,
                "weight_gain": 1 if weight_gain else 0,
                "hair_growth": 1 if hair_growth else 0,
                "skin_darkening": 1 if skin_darkening else 0,
                "hair_loss": 1 if hair_loss else 0,
                "pimples": 1 if pimples else 0,
                "fast_food": 1 if fast_food else 0,
                "regular_exercise": 1 if regular_exercise else 0,
                "fsh": fsh,
                "lh": lh,
                "abortions": abortions,
                "beta_hcg1": beta_hcg1,
                "beta_hcg2": beta_hcg2
            }

            # Convert to array for model input
            features = list(input_data.values())
            
            # Make prediction
            if model is not None:
                risk_probability = predict_probability(model, features)
                if risk_probability is None:
                    risk_probability = fallback_predict(input_data)
            else:
                risk_probability = fallback_predict(input_data)
            
            # Show results
            st.success(f"Risk Score: {risk_probability:.2%}")
            
            # Risk interpretation
            if risk_probability < 0.3:
                risk_level = "Low"
                color = "green"
            elif risk_probability < 0.6:
                risk_level = "Moderate"
                color = "orange"
            else:
                risk_level = "High"
                color = "red"
            
            st.markdown(f"**Risk Level:** <span style='color:{color}'>{risk_level}</span>", unsafe_allow_html=True)
            
            # Recommendations based on risk level
            st.subheader("Ovarian Cyst Management Guidelines")
            st.markdown("*Note: These recommendations are for general guidance. Always consult with your healthcare provider for personalized advice.*")
            
            if risk_level == "Low":
                st.markdown("#### Regular Monitoring 🔍")
                st.write("- 📅 Schedule follow-up ultrasound in 4-6 weeks")
                st.write("- 📝 Track any pelvic pain or discomfort")
                st.write("- 📊 Monitor menstrual cycle changes")
                st.write("- 🌡️ Record any new symptoms")
                
                st.markdown("#### Lifestyle Recommendations 🌱")
                st.write("- �‍♀️ Gentle exercise (walking, swimming)")
                st.write("- �‍♀️ Practice stress-reducing activities")
                st.write("- 💆‍♀️ Consider pelvic floor exercises")
                st.write("- 😴 Maintain regular sleep schedule")
                st.write("- 🥗 Follow a balanced diet")
                
                st.markdown("#### Pain Management 💊")
                st.write("- 🌡️ Use warm compresses for discomfort")
                st.write("- � Over-the-counter pain relief if needed:")
                st.write("  • Ibuprofen (400-600mg as needed)")
                st.write("  • Acetaminophen/Paracetamol (500-1000mg)")
                
                st.markdown("#### Preventive Measures 🛡️")
                st.write("- 💊 Recommended daily supplements:")
                st.write("  • 🍊 Vitamin D3 (2000-4000 IU daily)")
                st.write("  • 🌿 Omega-3 fatty acids (1000mg daily)")
                st.write("  • 🍎 Magnesium (300-400mg daily)")
                st.write("  • 🥑 Vitamin B-complex")
                st.write("- 🫖 Limit caffeine intake")
                st.write("- 🧘‍♀️ Practice stress management")
                st.write("- 🌿 Consider herbal teas (spearmint, green tea)")
                
            elif risk_level == "Moderate":
                st.markdown("#### Medical Evaluation 👩‍⚕️")
                st.write("- 🏥 Consult with gynecologist")
                st.write("- 🔬 Recommended assessments:")
                st.write("  • 🔍 Transvaginal ultrasound")
                st.write("  • 🩸 Hormone level testing")
                st.write("  • � Tumor marker tests (CA-125)")
                st.write("  • � Complete blood count")
                st.write("- 📋 Keep detailed symptom diary")
                st.write("- 📱 Consider ovarian cyst tracking app")
                
                st.markdown("#### Lifestyle Changes 🔄")
                st.write("- 🏋️‍♀️ Exercise recommendations:")
                st.write("  • 💪 Strength training (3x weekly)")
                st.write("  • 🚶‍♀️ Daily walking (45-60 minutes)")
                st.write("  • �‍♀️ Yoga for hormone balance")
                st.write("- 🥗 Anti-inflammatory diet guide:")
                st.write("  • ✅ Increase: leafy greens, lean proteins, healthy fats")
                st.write("  • ❌ Avoid: processed foods, refined sugars, excess dairy")
                st.write("- ⚖️ Aim for gradual weight loss if BMI > 25")
                st.write("- 😌 Stress management techniques")
                st.write("- 😴 Improve sleep hygiene")
                
                st.markdown("#### Medication & Supplement Plan 💊")
                st.write("- 💊 Discuss medications with doctor:")
                st.write("  • 🎯 Birth control options")
                st.write("  • 🌟 Anti-androgen medications")
                st.write("  • 🔄 Ovulation induction if trying to conceive")
                st.write("- 🌿 Recommended supplements:")
                st.write("  • 🔮 Inositol (2-4g daily)")
                st.write("  • 🌞 Vitamin D (4000-6000 IU daily)")
                st.write("  • 🍇 NAC (600-1800mg daily)")
                st.write("  • 🌱 Berberine (500mg 3x daily)")
                st.write("- 🩺 Regular monitoring:")
                st.write("  • 💓 Blood pressure weekly")
                st.write("  • 📊 Blood sugar levels")
                st.write("  • ⚖️ Weight changes")
                
            else:  # High Risk
                st.markdown("#### Immediate Medical Attention 🚨")
                st.write("- 🏥 Emergency medical evaluation needed")
                st.write("- 👩‍⚕️ Specialist consultations required:")
                st.write("  • � Gynecologic surgeon")
                st.write("  • 📊 Gynecologic oncologist")
                st.write("  • 💉 Pain management specialist")
                st.write("  • 💭 Fertility specialist if relevant")
                st.write("- � Comprehensive testing:")
                st.write("  • 📊 Complete hormonal panel")
                st.write("  • 💉 Glucose tolerance test")
                st.write("  • 🩸 Insulin resistance assessment")
                st.write("  • 🫀 Cardiovascular screening")
                st.write("  • 🔍 Pelvic and transvaginal ultrasound")
                
                st.markdown("#### Treatment Considerations 💉")
                st.write("- 🏥 Possible interventions:")
                st.write("  • 🔪 Surgical options:")
                st.write("    ∘ Laparoscopic cyst removal")
                st.write("    ∘ Ovarian cystectomy")
                st.write("    ∘ Emergency surgery if ruptured")
                st.write("  • 💊 Medical management:")
                st.write("    ∘ Pain medication")
                st.write("    ∘ Hormonal treatments")
                st.write("    ∘ Anti-inflammatory medications")
                st.write("  • 🔄 Second-line treatments:")
                st.write("    ∘ GLP-1 receptor agonists")
                st.write("    ∘ Clomiphene for fertility")
                st.write("    ∘ Anti-androgen medications")
                st.write("  • 🌿 Supplementary treatments:")
                st.write("    ∘ High-dose inositol (4g daily)")
                st.write("    ∘ Berberine (1500mg daily)")
                st.write("    ∘ Specialized vitamin compounds")
                
                st.markdown("#### Emergency Signs & Symptoms ⚠️")
                st.write("- 🚨 Watch for warning signs:")
                st.write("  • 😫 Severe pelvic pain")
                st.write("  • 🤢 Severe nausea/vomiting")
                st.write("  • 🌡️ Fever")
                st.write("  • 😵 Dizziness or fainting")
                st.write("  • 💨 Rapid breathing")
                st.write("- 🏃‍♀️ Seek immediate care if experienced")
                
                st.markdown("#### Post-Treatment Care 🌟")
                st.write("- �️ Rest and recovery plan:")
                st.write("  • Limited physical activity")
                st.write("  • Gradual return to normal activities")
                st.write("  • Pain management protocol")
                st.write("- 🏥 Follow-up care:")
                st.write("  • Regular ultrasound monitoring")
                st.write("  • Hormone level checks")
                st.write("  • Ongoing pain assessment")
                
                st.markdown("#### Comprehensive Monitoring 📈")
                st.write("- 📅 Weekly health tracking:")
                st.write("  • 💉 Blood sugar monitoring")
                st.write("  • 💓 Blood pressure checks")
                st.write("  • ⚖️ Body composition analysis")
                st.write("- 🏥 Monthly evaluations:")
                st.write("  • �‍⚕️ Specialist follow-ups")
                st.write("  • 📊 Hormone level testing")
                st.write("  • 🫀 Cardiovascular assessment")
                st.write("- � Support services:")
                st.write("  • 💭 Mental health counseling")
                st.write("  • 👥 PCOS support group")
                st.write("  • 📱 Digital health monitoring")

            # Cyst-specific recommendations based on risk level
            st.subheader("Ovarian Cyst Recommendations & Guidelines")
            if risk_level == "Low":
                st.markdown("#### Monitoring & Self-Care 🔍")
                st.write("- 📅 Schedule routine pelvic exams (yearly)")
                st.write("- 📝 Track menstrual cycles and symptoms")
                st.write("- 🌡️ Monitor for changes in pain levels")
                st.write("- ⚖️ Maintain healthy weight")
                st.write("- 💆‍♀️ Practice stress reduction")

                st.markdown("#### Lifestyle Recommendations 🌱")
                st.write("- 🏃‍♀️ Gentle exercise (walking, swimming)")
                st.write("- 🥗 Anti-inflammatory diet")
                st.write("- 🧘‍♀️ Yoga and stretching")
                st.write("- 💧 Stay hydrated")
                st.write("- 🛏️ Adequate rest (7-9 hours)")

                st.markdown("#### Warning Signs to Watch 🚨")
                st.write("- 💫 Sudden dizziness")
                st.write("- 🤒 Fever")
                st.write("- 😰 Severe pain")
                st.write("- 🤢 Persistent nausea")
                
            elif risk_level == "Moderate":
                st.markdown("#### Medical Evaluation 👩‍⚕️")
                st.write("- 🏥 Schedule gynecologist appointment")
                st.write("- 🔬 Recommended tests:")
                st.write("  • 📸 Pelvic ultrasound")
                st.write("  • 🩸 Hormone level testing")
                st.write("  • 💉 CA-125 test if indicated")
                
                st.markdown("#### Treatment Options 💊")
                st.write("- 💊 Pain management:")
                st.write("  • 🌡️ Over-the-counter pain relievers")
                st.write("  • 🔥 Heat therapy")
                st.write("- 🌿 Hormone therapy options:")
                st.write("  • 💊 Birth control pills")
                st.write("  • 🔄 Hormone regulation")
                
                st.markdown("#### Lifestyle Modifications 🔄")
                st.write("- 🏋️‍♀️ Modified exercise routine:")
                st.write("  • 🚶‍♀️ Low-impact activities")
                st.write("  • 🧘‍♀️ Gentle stretching")
                st.write("- 🥗 Dietary changes:")
                st.write("  • ✅ Anti-inflammatory foods")
                st.write("  • ❌ Avoid trigger foods")
                
            else:  # High Risk
                st.markdown("#### Immediate Medical Attention 🚨")
                st.write("- 🏥 Urgent specialist consultation")
                st.write("- 📋 Comprehensive evaluation:")
                st.write("  • 📸 Advanced imaging (MRI/CT)")
                st.write("  • 🩸 Complete blood work")
                st.write("  • 💉 Tumor marker tests")
                
                st.markdown("#### Treatment Protocol 🏥")
                st.write("- 👩‍⚕️ Surgical evaluation:")
                st.write("  • 🔍 Laparoscopic assessment")
                st.write("  • 🎯 Cyst removal options")
                st.write("  • 🔬 Biopsy if needed")
                st.write("- 💊 Medical management:")
                st.write("  • 💉 Pain management protocol")
                st.write("  • 🌡️ Infection prevention")
                st.write("  • 🔄 Hormone therapy")
                
                st.markdown("#### Emergency Guidelines 🚑")
                st.write("- 🚨 Warning signs requiring ER visit:")
                st.write("  • 😫 Severe abdominal pain")
                st.write("  • 🤢 Severe vomiting")
                st.write("  • 😵 Fainting or dizziness")
                st.write("  • 🌡️ High fever")
                
                st.markdown("#### Follow-up Care 📋")
                st.write("- 📅 Regular monitoring schedule")
                st.write("- 📊 Tracking symptoms and changes")
                st.write("- 👥 Support group resources")
                st.write("- 🧠 Mental health support")
                st.write("- 👶 Fertility preservation options")

            st.markdown("#### General Guidelines for All Risk Levels ℹ️")
            st.write("- 🏥 Keep all scheduled medical appointments")
            st.write("- 📝 Document any changes in symptoms")
            st.write("- 🚫 Avoid strenuous activities when in pain")
            st.write("- 💊 Take prescribed medications as directed")
            st.write("- 📱 Use symptom tracking apps")
            st.write("- 🆘 Know when to seek emergency care")

        except Exception as e:
            st.error(f"Error making prediction: {str(e)}")

st.markdown("---")
st.markdown("*This is a part of the Ovarian Cyst Support App*")
