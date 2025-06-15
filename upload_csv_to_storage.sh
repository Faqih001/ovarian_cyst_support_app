#!/bin/bash

# CSV File Upload Script for Ovarian Cyst Support App
# This script uploads the healthcare_facilities.csv file to Firebase Storage
# during development or CI/CD pipeline runs

echo "Starting CSV upload to Firebase Storage..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check if the CSV file exists
CSV_PATH="./assets/healthcare_facilities.csv"
if [ ! -f "$CSV_PATH" ]; then
    echo "Error: CSV file not found at $CSV_PATH"
    exit 1
fi

# Run the upload script (this creates a simple Flutter app that just uploads the CSV)
flutter run -d chrome --web-port 8080 --web-renderer html --route="/admin/upload-csv" 2>&1 | grep -i "CSV"

echo "CSV upload process completed. Please check the logs for success or failure."
