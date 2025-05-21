import tensorflow as tf
from tensorflow import keras

def create_model(input_shape):
    """
    Create the PCOS prediction model architecture
    Args:
        input_shape (tuple): Shape of input features
    Returns:
        keras.Model: Compiled keras model
    """
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

def save_as_tflite(model, output_path):
    """
    Convert Keras model to TFLite format and save
    Args:
        model (keras.Model): Trained Keras model
        output_path (str): Path to save TFLite model
    """
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
