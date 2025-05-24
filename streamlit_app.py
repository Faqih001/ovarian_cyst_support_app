"""
PCOS Risk Assessment Streamlit App
This is the entry point for Streamlit Cloud deployment
"""

import os
import sys
import streamlit as st

# Add the ml directory to the path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "ml")))

try:
    # Try to import the main function from our app
    from ml.streamlit.app import main
    
    # Execute the main function
    if __name__ == "__main__":
        main()
except ImportError as e:
    st.error(f"Error importing the Streamlit app: {e}")
    st.write("#### Debugging Information:")
    st.write(f"Current directory: {os.getcwd()}")
    st.write(f"Python path: {sys.path}")
    
    # Check if the file exists
    app_path = os.path.join(os.path.dirname(__file__), "ml", "streamlit", "app.py")
    st.write(f"App file exists: {os.path.exists(app_path)}")
    
    # List directories to debug
    st.write("#### Directory Structure:")
    try:
        st.write("Root directory:")
        st.write(os.listdir(os.path.dirname(__file__)))
        
        if os.path.exists(os.path.join(os.path.dirname(__file__), "ml")):
            st.write("ML directory:")
            st.write(os.listdir(os.path.join(os.path.dirname(__file__), "ml")))
            
            if os.path.exists(os.path.join(os.path.dirname(__file__), "ml", "streamlit")):
                st.write("Streamlit directory:")
                st.write(os.listdir(os.path.join(os.path.dirname(__file__), "ml", "streamlit")))
    except Exception as list_err:
        st.error(f"Error listing directories: {list_err}")
