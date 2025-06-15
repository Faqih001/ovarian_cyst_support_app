from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import os

app = Flask(__name__)
CORS(app)

# Load the model and scaler
model_dir = os.path.join(os.path.dirname(__file__), 'models')
model = joblib.load(os.path.join(model_dir, 'pcos_model.joblib'))
scaler = joblib.load(os.path.join(model_dir, 'scaler.joblib'))

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        
        # Extract features in the correct order
        features = [
            data['beta_hcg1'],  # First Beta HCG
            data['beta_hcg2'],  # Second Beta HCG
            data['amh_level'],  # AMH Level
            data['pregnant'],    # Pregnancy Status
            data['weight_gain'], # Weight Gain
            data['hair_growth'], # Hair Growth
            data['skin_darkening'], # Skin Darkening
            data['hair_loss'],   # Hair Loss
            data['pimples'],     # Pimples
            data['fast_food'],   # Fast Food
            data['regular_exercise'], # Regular Exercise
            data['blood_group'], # Blood Group
        ]
        
        # Scale features
        X = np.array([features])
        X_scaled = scaler.transform(X)
        
        # Get prediction probability
        risk_prob = float(model.predict_proba(X_scaled)[0][1])
        
        # Get feature names
        feature_names = [
            'Beta HCG (First Test)',
            'Beta HCG (Second Test)',
            'AMH Level',
            'Pregnancy Status',
            'Weight Gain',
            'Hair Growth',
            'Skin Darkening',
            'Hair Loss',
            'Pimples',
            'Fast Food Consumption',
            'Regular Exercise',
            'Blood Group'
        ]
        
        # Get feature contributions
        feature_contributions = {
            name: float(abs(imp)) 
            for name, imp in zip(feature_names, model.feature_importances_)
        }
        
        # Determine risk stage
        if risk_prob < 0.3:
            stage = 'Low Risk'
        elif risk_prob < 0.7:
            stage = 'Moderate Risk'
        else:
            stage = 'High Risk'
        
        # Generate recommendations
        recommendations = []
        if risk_prob >= 0.7:
            recommendations.append("Schedule an immediate consultation with a gynecologist.")
            recommendations.append("Consider comprehensive hormone testing.")
        elif risk_prob >= 0.3:
            recommendations.append("Schedule a check-up with your healthcare provider within the next month.")
            recommendations.append("Monitor your symptoms and keep a health diary.")
        
        # Feature-specific recommendations
        high_impact_features = {k: v for k, v in feature_contributions.items() if v > 0.3}
        for feature in high_impact_features:
            if 'Weight gain' in feature:
                recommendations.append("Consider consulting with a nutritionist and developing a balanced meal plan.")
            elif 'Exercise' in feature:
                recommendations.append("Aim for at least 150 minutes of moderate exercise per week.")
            elif 'Fast food' in feature:
                recommendations.append("Reduce processed food intake and focus on whole, nutrient-rich foods.")
            elif 'Hair' in feature or 'Skin' in feature:
                recommendations.append("Consider consulting with a dermatologist for specialized skin and hair care advice.")
        
        return jsonify({
            'risk_probability': risk_prob,
            'stage': stage,
            'feature_contributions': feature_contributions,
            'recommendations': recommendations
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
