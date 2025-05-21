"""
PCOS Risk Assessment Web Application using Streamlit.
This module provides both a web interface and API for predicting PCOS risk.
"""

from io import BytesIO
import os
import streamlit as st
import pandas as pd
import numpy as np
import requests
import joblib
from catboost import CatBoostClassifier
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
import uvicorn
from pydantic import BaseModel, Field
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Blood group mapping helper function
def map_blood_group(blood_group_str):
    mapping = {
        'A+': 1,
        'A-': 2,
        'B+': 3,
        'B-': 4,
        'O+': 5,
        'O-': 6,
        'AB+': 7,
        'AB-': 8
    }
    return mapping.get(blood_group_str, 1)  # Default to 1 if unknown

# Model loading function
def load_model():
    try:
        model_path = os.path.join(os.path.dirname(__file__), '..', 'models', 'pcos_model.joblib')
        return joblib.load(model_path)
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        return None

# Prediction function
def predict_probability(model, features):
    try:
        return float(model.predict_proba(np.array([features]))[0][1])
    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        return None

# Fallback prediction when main model fails
def fallback_predict(input_data):
    # Simple rule-based fallback
    risk_factors = [
        input_data.weight_gain,
        input_data.hair_growth,
        input_data.skin_darkening,
        input_data.hair_loss,
        input_data.pimples,
        input_data.fast_food,
        not input_data.regular_exercise
    ]
    risk_count = sum(1 for factor in risk_factors if factor)
    return risk_count / len(risk_factors)  # Simple ratio of risk factors present

# Create FastAPI app
api = FastAPI(title="PCOS Risk Assessment API")

# Add CORS middleware with more specific configuration
api.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development. In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],  # Expose redirect headers
    max_age=3600,  # Cache preflight requests for 1 hour
)

# Add custom middleware to handle redirects
@api.middleware("http")
async def add_custom_headers(request: Request, call_next):
    response = await call_next(request)
    # Add headers to prevent caching
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

class PredictionInput(BaseModel):
    age: float = Field(..., description="Age in years")
    weight: float = Field(..., description="Weight in kg")
    height: float = Field(..., description="Height in cm")
    bmi: float = Field(..., description="Body Mass Index")
    blood_group: int = Field(..., description="Blood group (1-8)")
    pulse_rate: float = Field(..., description="Pulse rate")
    rr: float = Field(..., description="Respiratory rate")
    hb: float = Field(..., description="Hemoglobin level")
    cycle_ri: int = Field(..., description="Cycle regularity index")
    cycle_length: float = Field(..., description="Menstrual cycle length in days")
    marriage_status: float = Field(..., description="Marriage status")
    pregnant: int = Field(..., description="Pregnancy status (0/1)")
    no_of_abortions: float = Field(..., description="Number of abortions")
    beta_hcg1: float = Field(..., description="Beta HCG level 1")
    beta_hcg2: float = Field(..., description="Beta HCG level 2")
    fsh: float = Field(..., description="FSH level")
    lh: float = Field(..., description="LH level")
    fsh_lh_ratio: float = Field(..., description="FSH/LH ratio")
    hip: float = Field(..., description="Hip measurement")
    waist: float = Field(..., description="Waist measurement")
    waist_hip_ratio: float = Field(..., description="Waist to hip ratio")
    tsh: float = Field(..., description="TSH level")
    amh: float = Field(..., description="AMH level")
    prl: float = Field(..., description="Prolactin level")
    vit_d3: float = Field(..., description="Vitamin D3 level")
    prg: float = Field(..., description="Progesterone level")
    rbs: float = Field(..., description="Random blood sugar")
    weight_gain: int = Field(..., description="Weight gain (0/1)")
    hair_growth: int = Field(..., description="Hair growth (0/1)")
    skin_darkening: int = Field(..., description="Skin darkening (0/1)")
    hair_loss: int = Field(..., description="Hair loss (0/1)")
    pimples: int = Field(..., description="Pimples (0/1)")
    fast_food: int = Field(..., description="Fast food consumption (0/1)")
    regular_exercise: int = Field(..., description="Regular exercise (0/1)")
    bp_systolic: float = Field(..., description="Systolic blood pressure")
    bp_diastolic: float = Field(..., description="Diastolic blood pressure")
    follicle_l: float = Field(..., description="Left ovary follicle count")
    follicle_r: float = Field(..., description="Right ovary follicle count")
    avg_f_size_l: float = Field(..., description="Average left follicle size")
    avg_f_size_r: float = Field(..., description="Average right follicle size")
    endometrium: float = Field(..., description="Endometrium thickness")

# Error handler for validation errors
@api.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    return JSONResponse(
        status_code=400,
        content={"error": "Validation error", "details": str(exc)},
    )

# Error handler for other exceptions
@api.exception_handler(Exception)
async def general_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "details": str(exc)},
    )

@api.post("/predict")
async def predict_api(input_data: PredictionInput):
    try:
        # Load model
        model = load_model()
        if not model:
            return {"error": "Model loading failed"}

        # Extract features in the correct order
        features = [
            input_data.beta_hcg1,
            input_data.beta_hcg2,
            input_data.amh,
            input_data.pregnant,
            input_data.weight_gain,
            input_data.hair_growth,
            input_data.skin_darkening,
            input_data.hair_loss,
            input_data.pimples,
            input_data.fast_food,
            input_data.regular_exercise,
            input_data.blood_group
        ]

        # Make prediction
        risk_prob = predict_probability(model, features)
        if risk_prob is None:
            return {"error": "Prediction failed"}

        # Determine risk stage
        if risk_prob < 0.3:
            stage = "Low Risk"
        elif risk_prob < 0.7:
            stage = "Moderate Risk"
        else:
            stage = "High Risk"

        # Feature contributions
        feature_names = [
            "Beta HCG (First)",
            "Beta HCG (Second)",
            "AMH Level",
            "Pregnancy Status",
            "Weight Gain",
            "Hair Growth",
            "Skin Darkening",
            "Hair Loss",
            "Pimples",
            "Fast Food",
            "Regular Exercise",
            "Blood Group"
        ]
        
        feature_contributions = {
            name: abs(float(value)) * 0.1 
            for name, value in zip(feature_names, features)
        }

        # Generate recommendations
        recommendations = []
        if risk_prob >= 0.7:
            recommendations.extend([
                "Schedule an immediate consultation with a gynecologist",
                "Complete comprehensive hormone testing",
                "Consider ultrasound examination",
                "Monitor symptoms closely"
            ])
        elif risk_prob >= 0.3:
            recommendations.extend([
                "Schedule a check-up within the next month",
                "Keep a symptom diary",
                "Consider lifestyle modifications",
                "Monitor menstrual cycle changes"
            ])
        else:
            recommendations.extend([
                "Continue regular health monitoring",
                "Maintain healthy lifestyle habits",
                "Schedule routine check-up",
                "Track any changes in symptoms"
            ])

        return {
            "risk_probability": float(risk_prob),
            "stage": stage,
            "recommendations": recommendations,
            "feature_contributions": feature_contributions
        }
    except Exception as e:
        return {"error": str(e)}

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
            # Convert blood group to numeric value
            blood_group_num = map_blood_group(blood_group)
            
            # Create PredictionInput instance with validated data
            prediction_input = PredictionInput(
                age=age,
                weight=weight,
                height=height,
                bmi=bmi,
                blood_group=blood_group_num,
                pulse_rate=pulse_rate,
                rr=rr,
                hb=hb,
                cycle_ri=1 if cycle_regularity else 0,
                cycle_length=cycle_length,
                marriage_status=marriage_status,
                pregnant=1 if pregnant else 0,
                no_of_abortions=abortions,
                beta_hcg1=beta_hcg1,
                beta_hcg2=beta_hcg2,
                fsh=fsh,
                lh=lh,
                fsh_lh_ratio=fsh/lh if lh > 0 else 0,
                hip=hip,
                waist=waist,
                waist_hip_ratio=waist / hip if waist > 0 and hip > 0 else 0,
                tsh=tsh,
                amh=amh,
                prl=prl,
                vit_d3=vit_d3,
                prg=prg,
                rbs=rbs,
                weight_gain=1 if weight_gain else 0,
                hair_growth=1 if hair_growth else 0,
                skin_darkening=1 if skin_darkening else 0,
                hair_loss=1 if hair_loss else 0,
                pimples=1 if pimples else 0,
                fast_food=1 if fast_food else 0,
                regular_exercise=1 if regular_exercise else 0,
                bp_systolic=bp_systolic,
                bp_diastolic=bp_diastolic,
                follicle_l=follicle_l,
                follicle_r=follicle_r,
                avg_f_size_l=avg_f_size_l,
                avg_f_size_r=avg_f_size_r,
                endometrium=endometrium
            )
            
            # Extract only the features needed for the model in the correct order and format
            model_features = [
                prediction_input.age,
                prediction_input.weight,
                prediction_input.height,
                prediction_input.bmi,
                prediction_input.blood_group,
                prediction_input.pulse_rate,
                prediction_input.rr,
                prediction_input.hb,
                prediction_input.cycle_ri,
                prediction_input.cycle_length,
                prediction_input.marriage_status,
                prediction_input.pregnant,
                prediction_input.no_of_abortions,  # This matches "No. of aborptions" in the model
                prediction_input.beta_hcg1,
                prediction_input.beta_hcg2,
                prediction_input.fsh,
                prediction_input.lh,
                prediction_input.fsh_lh_ratio,
                prediction_input.hip,
                prediction_input.waist,
                prediction_input.waist_hip_ratio,
                prediction_input.tsh,
                prediction_input.amh,
                prediction_input.prl,
                prediction_input.vit_d3,
                prediction_input.prg,
                prediction_input.rbs,
                prediction_input.weight_gain,
                prediction_input.hair_growth,
                prediction_input.skin_darkening,
                prediction_input.hair_loss,
                prediction_input.pimples,
                prediction_input.fast_food,
                prediction_input.regular_exercise,
                prediction_input.bp_systolic,
                prediction_input.bp_diastolic,
                prediction_input.follicle_l,
                prediction_input.follicle_r,
                prediction_input.avg_f_size_l,
                prediction_input.avg_f_size_r,  # This matches "Avg. F size (R) (mm)" in the model
                prediction_input.endometrium
            ]
            
            # Make prediction
            if model is not None:
                risk_probability = predict_probability(model, model_features)
                if risk_probability is None:
                    risk_probability = fallback_predict(prediction_input)
            else:
                risk_probability = fallback_predict(prediction_input)
            
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

# To run the FastAPI app, uncomment the following lines:
# if __name__ == "__main__":
#     uvicorn.run(api, host="0.0.0.0", port=8000)
