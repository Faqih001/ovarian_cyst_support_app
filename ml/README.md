# PCOS Prediction Model

This directory contains the machine learning components for PCOS prediction.

## Directory Structure

```
ml/
├── data/               # Dataset files
├── models/            # Saved models and parameters
└── src/               # Source code
    ├── train_model.py # Model training script
    ├── test_model.py  # Model testing script
    └── app.py         # Streamlit web application
```

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Train the model:
```bash
cd src
python train_model.py
```

3. Test the model:
```bash
python test_model.py
```

4. Run the Streamlit app:
```bash
streamlit run app.py
```

## Model Details

The model uses three key clinical markers for PCOS prediction:
- AMH (Anti-Müllerian Hormone) levels
- Beta-HCG Level I
- Beta-HCG Level II

The prediction system uses a neural network model trained on clinical data and provides probability scores for PCOS diagnosis.

## API Integration

The Streamlit app provides a web interface for predictions. To integrate with the Flutter app, use the provided API endpoint:

```
https://[your-streamlit-domain]/predict
```

## Deployment

The Streamlit app can be deployed to various platforms:
- Streamlit Cloud (Recommended)
- Heroku
- Google Cloud Platform
- AWS

For deployment instructions, refer to the Streamlit documentation.
