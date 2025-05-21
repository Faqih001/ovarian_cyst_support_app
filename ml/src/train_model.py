import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
from tensorflow import keras
import json
import os

def load_and_preprocess_data(data_path):
    """Load and preprocess the PCOS dataset."""
    infertility_df = pd.read_csv(data_path)
    
    features = [
        'AMH(ng/mL)',
        'I   beta-HCG(mIU/mL)',
        'II    beta-HCG(mIU/mL)'
    ]
    
    X = infertility_df[features]
    y = infertility_df['PCOS (Y/N)']
    
    return X, y, features

def create_model(input_shape):
    """Create and compile the neural network model."""
    model = keras.Sequential([
        keras.layers.Dense(16, activation='relu', input_shape=input_shape),
        keras.layers.Dropout(0.3),
        keras.layers.Dense(8, activation='relu'),
        keras.layers.Dense(1, activation='sigmoid')
    ])
    
    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    
    return model

def train_model():
    """Main function to train and save the model."""
    # Load and preprocess data
    X, y, features = load_and_preprocess_data('../data/PCOS_infertility.csv')
    
    # Split the data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    # Scale the features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Create and train the model
    model = create_model((len(features),))
    
    history = model.fit(
        X_train_scaled, y_train,
        epochs=50,
        batch_size=32,
        validation_split=0.2,
        verbose=1
    )
    
    # Evaluate the model
    test_loss, test_accuracy = model.evaluate(X_test_scaled, y_test)
    print(f"\nTest accuracy: {test_accuracy:.2f}")
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    # Create models directory if it doesn't exist
    os.makedirs('../models', exist_ok=True)
    
    # Save the TFLite model
    with open('../models/pcos_model.tflite', 'wb') as f:
        f.write(tflite_model)
    
    # Save scaler parameters
    scaler_params = {
        'mean': scaler.mean_.tolist(),
        'scale': scaler.scale_.tolist(),
        'feature_names': features
    }
    
    with open('../models/pcos_scaler.json', 'w') as f:
        json.dump(scaler_params, f)
    
    print('Model and scaler parameters saved successfully!')

if __name__ == '__main__':
    train_model()
