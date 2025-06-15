import os
import sys
import numpy as np
import pandas as pd
import logging
from datetime import datetime
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.metrics import classification_report
from catboost import CatBoostClassifier
import joblib
import traceback

# Set up logging
log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "logs")
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, f'training_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)

# Constants
RANDOM_SEED = 42

def binarize(val):
    """Convert various forms of binary input to 1/0."""
    if pd.isna(val):
        return np.nan
    if str(val).strip().lower() in ['yes', 'y', '1', 'true']:
        return 1
    elif str(val).strip().lower() in ['no', 'n', '0', 'false']:
        return 0
    else:
        return np.nan

def engineer_features(df):
    """Create engineered features to improve model performance."""
    
    # Calculate BMI categories
    def get_bmi_category(bmi):
        if bmi < 18.5:
            return 0  # Underweight
        elif bmi < 25:
            return 1  # Normal
        elif bmi < 30:
            return 2  # Overweight
        else:
            return 3  # Obese
    
    if 'BMI' in df.columns:
        df['BMI_Category'] = df['BMI'].apply(get_bmi_category)
    
    # Calculate Follicle-related features
    if 'Follicle No. (R)' in df.columns and 'Follicle No. (L)' in df.columns:
        # Add small epsilon to avoid division by zero
        df['Follicle_Ratio'] = df['Follicle No. (R)'] / (df['Follicle No. (L)'] + 1e-5)
        df['Total_Follicles'] = df['Follicle No. (R)'] + df['Follicle No. (L)']
        df['Follicle_Asymmetry'] = abs(df['Follicle No. (R)'] - df['Follicle No. (L)'])
        
        # Normalize ratio to handle extreme values
        df['Follicle_Ratio'] = df['Follicle_Ratio'].clip(0, 10)  # Cap extreme ratios
        
        # Average follicle size features
        if 'Avg. F size (R) (mm)' in df.columns and 'Avg. F size (L) (mm)' in df.columns:
            df['Avg_Follicle_Size'] = (df['Avg. F size (R) (mm)'] + df['Avg. F size (L) (mm)']) / 2
            df['Follicle_Size_Asymmetry'] = abs(df['Avg. F size (R) (mm)'] - df['Avg. F size (L) (mm)'])
    
    # Enhanced body composition metrics
    if 'Weight (Kg)' in df.columns and 'Height(Cm)' in df.columns:
        height_m = df['Height(Cm)'] / 100
        df['Weight_Height_Ratio'] = df['Weight (Kg)'] / height_m
        df['BSA'] = np.sqrt((df['Height(Cm)'] * df['Weight (Kg)']) / 3600)  # Body Surface Area
    
    # Calculate Cycle Regularity Score with more detail
    if 'Cycle length(days)' in df.columns and 'Cycle(R/I)' in df.columns:
        df['Cycle_Score'] = df.apply(
            lambda x: abs(x['Cycle length(days)'] - 28) * (2 if x['Cycle(R/I)'] == 0 else 1),
            axis=1
        )
        # Add severity categories for cycle length
        df['Cycle_Severity'] = pd.cut(
            df['Cycle length(days)'],
            bins=[0, 21, 35, 60, float('inf')],
            labels=[0, 1, 2, 3]
        )
    
    # Enhanced hormone analysis
    hormone_features = {
        'LH/FSH': ('LH(mIU/mL)', 'FSH(mIU/mL)'),
        'TSH_AMH': ('TSH (mIU/L)', 'AMH(ng/mL)'),
        'PRL_TSH': ('PRL(ng/mL)', 'TSH (mIU/L)'),
        'FSH_AMH': ('FSH(mIU/mL)', 'AMH(ng/mL)'),
    }
    
    for ratio_name, (h1, h2) in hormone_features.items():
        if h1 in df.columns and h2 in df.columns:
            # Calculate ratio with epsilon to avoid division by zero
            df[f'{ratio_name}_Ratio'] = df[h1] / (df[h2] + 1e-5)
            # Add interaction term (product)
            df[f'{ratio_name}_Product'] = df[h1] * df[h2]
            # Add sum for overall level
            df[f'{ratio_name}_Sum'] = df[h1] + df[h2]
            
            # Clip ratios to handle extreme values
            df[f'{ratio_name}_Ratio'] = df[f'{ratio_name}_Ratio'].clip(-10, 10)
    
    # Metabolic health score
    metabolic_factors = ['RBS(mg/dl)', 'BMI', 'BP _Systolic (mmHg)', 'BP _Diastolic (mmHg)']
    if all(col in df.columns for col in metabolic_factors):
        # Normalize each factor and combine
        df['Metabolic_Score'] = (
            (df['RBS(mg/dl)'] / 100) +
            (df['BMI'] / 25) +
            (df['BP _Systolic (mmHg)'] / 120) +
            (df['BP _Diastolic (mmHg)'] / 80)
        ) / 4
    
    # Symptom severity score
    symptom_columns = [
        'Weight gain(Y/N)', 'hair growth(Y/N)', 'Skin darkening (Y/N)',
        'Hair loss(Y/N)', 'Pimples(Y/N)'
    ]
    if all(col in df.columns for col in symptom_columns):
        df['Symptom_Score'] = df[symptom_columns].sum(axis=1)
    
    # Handle infinite values
    df = df.replace([np.inf, -np.inf], np.nan)
    
    return df

def load_and_preprocess_data():
    """Load and preprocess PCOS data."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.join(script_dir, "..", "data")
    
    # Define the columns we want to use - exactly matching the dataset
    SELECTED_COLUMNS = [
        'PCOS (Y/N)', ' Age (yrs)', 'Weight (Kg)', 'Height(Cm) ', 'BMI',
        'Blood Group', 'Pulse rate(bpm) ', 'RR (breaths/min)', 'Hb(g/dl)',
        'Cycle(R/I)', 'Cycle length(days)', 'Marraige Status (Yrs)',
        'Pregnant(Y/N)', 'No. of aborptions', '  I   beta-HCG(mIU/mL)',
        'II    beta-HCG(mIU/mL)', 'FSH(mIU/mL)', 'LH(mIU/mL)', 'FSH/LH',
        'Hip(inch)', 'Waist(inch)', 'Waist:Hip Ratio', 'TSH (mIU/L)',
        'AMH(ng/mL)', 'PRL(ng/mL)', 'Vit D3 (ng/mL)', 'PRG(ng/mL)',
        'RBS(mg/dl)', 'Weight gain(Y/N)', 'hair growth(Y/N)',
        'Skin darkening (Y/N)', 'Hair loss(Y/N)', 'Pimples(Y/N)',
        'Fast food (Y/N)', 'Reg.Exercise(Y/N)', 'BP _Systolic (mmHg)',
        'BP _Diastolic (mmHg)', 'Follicle No. (L)', 'Follicle No. (R)',
        'Avg. F size (L) (mm)', 'Avg. F size (R) (mm)', 'Endometrium (mm)'
    ]
    
    logging.info(f"Loading data from: {data_dir}")
    
    try:
        # Load the main dataset from the Full_new sheet
        df = pd.read_excel(
            os.path.join(data_dir, "PCOS_data_without_infertility.xlsx"),
            sheet_name="Full_new"
        )
        
        # Remove unwanted columns immediately
        columns_to_drop = ['Sl. No', 'Patient File No.']
        df = df.drop(columns=columns_to_drop, errors='ignore')
        
        logging.info("\nOriginal columns after removing unwanted ones: %s", df.columns.tolist())
        
        # Clean column names by stripping whitespace
        df.columns = df.columns.str.strip()
        
        # Map original column names to our standardized names
        column_mapping = {col.strip(): col.strip() for col in df.columns}
        df = df.rename(columns=column_mapping)
        
        logging.info("\nCleaned columns: %s", df.columns.tolist())
        
        # Clean up the SELECTED_COLUMNS list
        clean_selected_columns = [col.strip() for col in SELECTED_COLUMNS]
        
        # Check which columns are missing
        missing_cols = set(clean_selected_columns) - set(df.columns)
        if missing_cols:
            logging.warning("\nWarning: Missing columns: %s", missing_cols)
            # Remove missing columns from our selection
            clean_selected_columns = [col for col in clean_selected_columns if col not in missing_cols]
        
        # Select only the columns we want to use
        df = df[clean_selected_columns]
        
        logging.info("Successfully loaded dataset")
        logging.info(f"Total records: {len(df)}")
        
        # Clean column names
        df.columns = df.columns.str.strip()
        
        # Print data types before conversion
        logging.info("\nData types before conversion:")
        logging.info("%s", df.dtypes)
        
        # Convert binary columns to numeric (using exact column names from dataset)
        binary_columns = [
            'PCOS (Y/N)', 'Pregnant(Y/N)', 'Weight gain(Y/N)',
            'hair growth(Y/N)', 'Skin darkening (Y/N)', 'Hair loss(Y/N)',
            'Pimples(Y/N)', 'Fast food (Y/N)', 'Reg.Exercise(Y/N)'
        ]
        
        for col in binary_columns:
            if col in df.columns:
                df[col] = df[col].map({'Yes': 1, 'No': 0, 'Y': 1, 'N': 0, 1: 1, 0: 0})
        
        # Convert blood group to numeric
        blood_group_map = {'A+': 0, 'A-': 1, 'B+': 2, 'B-': 3, 'O+': 4, 'O-': 5, 'AB+': 6, 'AB-': 7}
        df['Blood Group'] = df['Blood Group'].map(blood_group_map)
        
        # Convert cycle regularity to numeric
        df['Cycle(R/I)'] = df['Cycle(R/I)'].map({'R': 1, 'I': 0})
        
        # Convert all numeric columns to float
        numeric_cols = df.select_dtypes(include=['object']).columns
        for col in numeric_cols:
            if col not in ['Blood Group']:  # Skip already converted columns
                df[col] = pd.to_numeric(df[col], errors='coerce')
        
        # Add engineered features
        df = engineer_features(df)
        
        # Handle missing values
        numeric_columns = df.select_dtypes(include=['float64', 'int64']).columns
        df[numeric_columns] = df[numeric_columns].fillna(df[numeric_columns].mean())
        
        # Print data types after conversion
        logging.info("\nData types after conversion:")
        logging.info("%s", df.dtypes)
        
        # Remove any unwanted columns (like 'Sl. No' or empty columns)
        columns_to_drop = ['Sl. No', 'Patient File No.', 'Unnamed: 44'] 
        df = df.drop(columns=[col for col in columns_to_drop if col in df.columns])
        
        return df
        
    except Exception as e:
        logging.error(f"Error in data preprocessing: {str(e)}")
        logging.error(traceback.format_exc())
        raise

def preprocess_data(df):
    """
    Preprocess the PCOS dataset with robust feature engineering and data cleaning.
    Handles missing values, outliers, and creates domain-specific features.
    """
    logging.info("Starting data preprocessing and feature engineering...")
    try:
        # Make a copy to avoid modifying original data
        df = df.copy()
        
        # First convert all numeric columns to float
        numeric_cols = df.select_dtypes(include=['int64', 'float64']).columns
        for col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors='coerce')
        
        # Binary columns conversion
        binary_columns = [
            'PCOS (Y/N)', 'Pregnant(Y/N)', 'Weight gain(Y/N)', 'hair growth(Y/N)', 
            'Skin darkening (Y/N)', 'Hair loss(Y/N)', 'Pimples(Y/N)',
            'Fast food (Y/N)', 'Reg.Exercise(Y/N)'
        ]
        
        # Log data quality before conversion
        logging.info("\nMissing values before preprocessing:")
        logging.info(df.isnull().sum()[df.isnull().sum() > 0])
        
        # Handle binary columns
        for col in binary_columns:
            if col in df.columns:
                # Convert string values to numeric
                df[col] = df[col].map({'Yes': 1, 'No': 0, 'Y': 1, 'N': 0, 1.0: 1, 0.0: 0})
                df[col] = df[col].astype('float64')
                logging.info(f"Binarized column: {col}")
        
        # Handle blood group conversion
        if 'Blood Group' in df.columns:
            blood_group_map = {'A+': 0, 'A-': 1, 'B+': 2, 'B-': 3, 'O+': 4, 'O-': 5, 'AB+': 6, 'AB-': 7}
            df['Blood Group'] = df['Blood Group'].map(blood_group_map)
            df['Blood Group'] = df['Blood Group'].astype('float64')
            
        # Make sure all remaining non-numeric columns are converted to numeric
        object_columns = df.select_dtypes(include=['object']).columns
        for col in object_columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
        
        # Calculate follicle ratios with safeguards against division by zero
        if 'Follicle No. (R)' in df.columns and 'Follicle No. (L)' in df.columns:
            df['Follicle_Sum'] = df['Follicle No. (R)'] + df['Follicle No. (L)']
            df['Follicle_Ratio'] = df['Follicle No. (R)'].astype(float) / (df['Follicle No. (L)'].astype(float) + 1e-5)
            df['Follicle_Ratio'] = df['Follicle_Ratio'].clip(0, 10)
            logging.info("Calculated follicle features")
        
        # Hormone feature engineering with proper type conversion
        hormone_pairs = [
            ('FSH(mIU/mL)', 'LH(mIU/mL)'),
            ('FSH(mIU/mL)', 'AMH(ng/mL)'),
            ('LH(mIU/mL)', 'AMH(ng/mL)')
        ]
        
        for h1, h2 in hormone_pairs:
            if h1 in df.columns and h2 in df.columns:
                df[h1] = pd.to_numeric(df[h1], errors='coerce')
                df[h2] = pd.to_numeric(df[h2], errors='coerce')
                
                ratio_name = f"{h1.split('(')[0]}_{h2.split('(')[0]}"
                df[f'{ratio_name}_Ratio'] = df[h1].astype(float) / (df[h2].astype(float) + 1e-5)
                df[f'{ratio_name}_Product'] = df[h1].astype(float) * df[h2].astype(float)
                df[f'{ratio_name}_Sum'] = df[h1].astype(float) + df[h2].astype(float)
                df[f'{ratio_name}_Ratio'] = df[f'{ratio_name}_Ratio'].clip(-10, 10)
                logging.info(f"Created hormone features for {ratio_name}")
        
        # BMI-related features
        if all(col in df.columns for col in ['Weight (Kg)', 'Height(Cm)']):
            df['Weight (Kg)'] = pd.to_numeric(df['Weight (Kg)'], errors='coerce')
            df['Height(Cm)'] = pd.to_numeric(df['Height(Cm)'], errors='coerce')
            
            height_m = df['Height(Cm)'].astype(float) / 100
            df['BMI'] = df['Weight (Kg)'].astype(float) / (height_m ** 2)
            df['BMI'] = df['BMI'].clip(0, 100)  # Remove unrealistic values
            logging.info("Calculated BMI features")
        
        # Handle missing values after all conversions
        numeric_columns = df.select_dtypes(include=['float64', 'int64']).columns
        for col in numeric_columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
            
        df = df.fillna(df.median())
        logging.info("Handled missing values")
        
        # Final check for any remaining non-numeric columns
        non_numeric = df.select_dtypes(exclude=['float64', 'int64']).columns
        if len(non_numeric) > 0:
            logging.warning(f"Warning: Non-numeric columns remaining: {non_numeric}")
            # Convert any remaining columns to numeric
            for col in non_numeric:
                df[col] = pd.to_numeric(df[col], errors='coerce')
                df[col] = df[col].fillna(df[col].median())
        
        # Verify all columns are numeric
        assert all(dt.kind in 'biufc' for dt in df.dtypes), "Non-numeric columns found after preprocessing"
        
        return df
        
    except Exception as e:
        logging.error(f"Error in data preprocessing: {str(e)}")
        logging.error(traceback.format_exc())
        raise

def train_model(X_train, y_train, X_test, y_test):
    """
    Train and evaluate the PCOS prediction model using CatBoost with cross-validation.
    """
    logging.info("Starting model training with cross-validation...")
    try:
        # Initialize model with optimized parameters
        model = CatBoostClassifier(
            iterations=1000,
            learning_rate=0.02,
            depth=6,
            l2_leaf_reg=3,
            loss_function='Logloss',
            random_seed=RANDOM_SEED,
            verbose=100,
            early_stopping_rounds=50,
            task_type='CPU',
            grow_policy='SymmetricTree',  # Add this to fix max_leaves error
            auto_class_weights='Balanced'  # Handle class imbalance
        )
        
        # Perform stratified k-fold cross-validation
        cv_scores = {'accuracy': [], 'precision': [], 'recall': [], 'f1': []}
        skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_SEED)
        
        for fold, (train_idx, val_idx) in enumerate(skf.split(X_train, y_train), 1):
            X_fold_train, X_fold_val = X_train.iloc[train_idx], X_train.iloc[val_idx]
            y_fold_train, y_fold_val = y_train.iloc[train_idx], y_train.iloc[val_idx]
            
            # Train on this fold
            model.fit(
                X_fold_train, y_fold_train,
                eval_set=[(X_fold_val, y_fold_val)],
                verbose=False
            )
            
            # Evaluate on validation fold
            y_fold_pred = model.predict(X_fold_val)
            fold_report = classification_report(y_fold_val, y_fold_pred, output_dict=True, zero_division=1)
            
            # Store metrics - use macro avg for all metrics
            cv_scores['accuracy'].append(fold_report['accuracy'])
            cv_scores['precision'].append(fold_report['macro avg']['precision'])
            cv_scores['recall'].append(fold_report['macro avg']['recall'])
            cv_scores['f1'].append(fold_report['macro avg']['f1-score'])
            
            logging.info(f"\nFold {fold} Results:")
            logging.info(f"Accuracy: {fold_report['accuracy']:.4f}")
            logging.info(f"Precision: {fold_report['macro avg']['precision']:.4f}")
            logging.info(f"Recall: {fold_report['macro avg']['recall']:.4f}")
            logging.info(f"F1-score: {fold_report['macro avg']['f1-score']:.4f}")
        
        # Print average CV scores
        logging.info("\nCross-validation Results:")
        for metric, scores in cv_scores.items():
            logging.info(f"{metric.capitalize()}: {np.mean(scores):.4f} ± {np.std(scores):.4f}")
        
        # Final training on full training set
        model.fit(
            X_train, y_train,
            eval_set=[(X_test, y_test)],
            verbose=False
        )
        
        # Evaluate on test set
        y_pred = model.predict(X_test)
        
        # Get detailed classification report
        report = classification_report(y_test, y_pred, output_dict=True, zero_division=1)
        
        logging.info("\nModel Performance:")
        logging.info(f"Accuracy: {report['accuracy']:.4f}")
        logging.info(f"Precision: {report['macro avg']['precision']:.4f}")
        logging.info(f"Recall: {report['macro avg']['recall']:.4f}")
        logging.info(f"F1-score: {report['macro avg']['f1-score']:.4f}")
        
        # Feature importance analysis
        feature_importance = pd.DataFrame({
            'feature': X_train.columns,
            'importance': model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        logging.info("\nTop 10 Most Important Features:")
        for idx, row in feature_importance.head(10).iterrows():
            logging.info(f"{row['feature']}: {row['importance']:.4f}")
        
        return model, feature_importance
        
    except Exception as e:
        logging.error(f"Error in model training: {str(e)}")
        logging.error(traceback.format_exc())
        raise

def main():
    """Main function to run the PCOS prediction model training pipeline."""
    try:
        print("Starting PCOS prediction model training...")
        print("Python version:", sys.version)
        print("Working directory:", os.getcwd())
        print("\nLoading and preprocessing data...")
        
        # Set up file paths
        current_dir = os.path.dirname(os.path.abspath(__file__))
        data_path = os.path.join(current_dir, "..", "data", "PCOS_data_without_infertility.xlsx")
        model_path = os.path.join(current_dir, "..", "models", "pcos_model.joblib")
        scaler_path = os.path.join(current_dir, "..", "models", "scaler.joblib")
        feature_names_path = os.path.join(current_dir, "..", "models", "feature_names.txt")
        
        # Create models directory if it doesn't exist
        os.makedirs(os.path.dirname(model_path), exist_ok=True)
        
        # Load and preprocess data
        print(f"\nLoading data from: {os.path.dirname(data_path)}\n")
        df = pd.read_excel(data_path, sheet_name='Full_new')
        
        # Clean column names once at the start
        df.columns = df.columns.str.strip()
        
        # Remove unwanted columns
        columns_to_drop = ['Sl. No', 'Patient File No.', 'Unnamed: 44']
        df = df.drop(columns=columns_to_drop, errors='ignore')
        
        # Print initial data shape
        print("Data shape:", df.shape)
        
        # Preprocess data
        df = preprocess_data(df)
        
        # Prepare features and target
        target = 'PCOS (Y/N)'
        features = [col for col in df.columns if col != target]
        
        print("\nNumber of features being used:", len(features))
        print("\nFeatures:", features)
        
        X = df[features]
        y = df[target]
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=RANDOM_SEED, stratify=y
        )
        
        print("\nTraining model...")
        
        # Train and evaluate model
        model, feature_importance = train_model(X_train, y_train, X_test, y_test)
        
        # Save model and feature importance
        logging.info(f"Saving model to {model_path}")
        joblib.dump(model, model_path)
        
        # Save feature names
        with open(feature_names_path, 'w') as f:
            f.write('\n'.join(features))
        
        feature_importance_path = os.path.join(
            os.path.dirname(model_path), 
            "feature_importance.csv"
        )
        feature_importance.to_csv(feature_importance_path, index=False)
        logging.info(f"Saved feature importance to {feature_importance_path}")
        
        logging.info("Training pipeline completed successfully")
        
    except Exception as e:
        logging.error(f"Error in main pipeline: {str(e)}")
        logging.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    main()
