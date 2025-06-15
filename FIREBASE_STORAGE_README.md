# Firebase Storage Implementation for Healthcare Facilities Data

## Overview

This implementation resolves the issue where the healthcare facilities CSV file cannot be loaded directly from the assets directory. The solution uses Firebase Storage to store and retrieve the data, with a local assets file fallback.

## Implementation Details

### 1. Storage Service (`lib/services/storage_service.dart`)

This service handles all Firebase Storage operations:

- Uploading CSV files from assets to Firebase Storage
- Downloading CSV files from Firebase Storage
- Checking if files exist in Firebase Storage

### 2. Hospital Service (`lib/services/hospital_service_fixed.dart`)

The updated `HospitalService` class:

- Attempts to load the CSV file from Firebase Storage first
- Falls back to the local asset if Firebase Storage fails
- Automatically uploads the CSV to Firebase Storage if not already present

### 3. Main Application Entry (`lib/main.dart`)

At application startup:
- Firebase Storage is initialized
- The CSV file is uploaded to Firebase Storage if necessary

### 4. UI Integration

The hospital booking screen has been updated to:
- Use the new `HospitalService` implementation
- Add connectivity status checks
- Display appropriate error messages when offline

## How to Use

1. Make sure Firebase Storage is properly configured in your Firebase project
2. Run the app - the CSV file will be automatically uploaded to Firebase Storage on first launch
3. Data will be loaded from Firebase Storage with a local fallback if needed

## Utility Scripts

- `upload_csv_to_storage.sh`: A utility script for manually uploading the CSV file to Firebase Storage

## Troubleshooting

If you encounter issues with data loading:

1. Check network connectivity
2. Verify that the CSV file exists in the assets directory
3. Check Firebase Storage permissions
4. Use the upload script to manually upload the CSV file
5. Review logs for any specific error messages

## Technical Implementation

The implementation follows the following workflow:

1. Check if the CSV file exists in Firebase Storage
2. If not, upload the CSV from assets to Firebase Storage
3. Try to download the CSV from Firebase Storage
4. If download fails, fall back to loading from local assets
5. Parse the CSV data into facility objects
6. Cache the data for future use

This approach reduces network requests while ensuring the data is always available to the user.
