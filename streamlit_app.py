"""
Streamlit app entry point.
This file serves as a pointer to the actual app implementation in ml/streamlit/app.py.
"""
import os
import sys
import streamlit as st

# Set page configuration must be the first streamlit command
st.set_page_config(
    page_title="PCOS Risk Assessment",
    page_icon="🩺",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Add the project root to the Python path
project_root = os.path.dirname(os.path.abspath(__file__))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# Import the create_streamlit_ui function from the app.py file
from ml.streamlit.app import create_streamlit_ui

# This will be executed by Streamlit when it loads this file
if __name__ == "__main__":
    create_streamlit_ui()
