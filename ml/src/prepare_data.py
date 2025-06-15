import pandas as pd
import os

def prepare_data():
    """Prepare and combine PCOS datasets for training."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.join(script_dir, "..", "data")

    try:
        # Read both datasets
        infertility_data = pd.read_csv(os.path.join(data_dir, "PCOS_infertility.csv"))
        non_infertility_data = pd.read_excel(
            os.path.join(data_dir, "PCOS_data_without_infertility.xlsx")
        )

        # Combine datasets based on Patient File No.
        combined_data = pd.merge(
            non_infertility_data,
            infertility_data,
            on='Patient File No.',
            suffixes=('', '_inf'),
            how='left'
        )

        # Drop duplicate columns and unnecessary ones
        columns_to_drop = [
            'Sl. No', 'Sl. No_inf', 'PCOS (Y/N)_inf',
            'I   beta-HCG(mIU/mL)_inf', 'II    beta-HCG(mIU/mL)_inf',
            'AMH(ng/mL)_inf', 'Unnamed: 44'
        ]
        combined_data = combined_data.drop(columns=[col for col in columns_to_drop if col in combined_data.columns])

        # Rename target column
        combined_data = combined_data.rename(columns={'PCOS (Y/N)': 'Target'})

        # Save the combined dataset
        output_path = os.path.join(data_dir, "PCOS_data_without_infertility.xlsx")
        combined_data.to_excel(output_path, index=False)
        print(f"Combined data saved to: {output_path}")
        print(f"Total records: {len(combined_data)}")
        print("\nColumns:", combined_data.columns.tolist())

    except Exception as e:
        print(f"Error preparing data: {str(e)}")
        raise

if __name__ == "__main__":
    prepare_data()
