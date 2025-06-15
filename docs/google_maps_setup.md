# Google Maps API Setup Guide

This document provides detailed instructions for setting up the Google Maps API for the Ovarian Cyst Support App.

## Current API Key Issue

The app logs show that there's an authorization failure with the Google Maps API. The specific error is:

```
Authorization failure. Ensure that the "Maps SDK for Android" is enabled.
Ensure that the following Android Key exists:
API Key: AIzaSyAlmmBfcowptQde9BOD8HOMbAxixIne8qs
Android Application (<cert_fingerprint>;<package_name>): EC:E4:31:35:ED:39:63:9C:B6:42:27:10:96:89:39:CC:05:E3:8B:63;com.example.ovarian_cyst_support_app
```

## Steps to Fix

### 1. Access the Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Make sure you're signed in with the Google account that owns this project

### 2. Enable the Maps SDK for Android

1. Navigate to "APIs & Services" > "Library"
2. Search for "Maps SDK for Android"
3. Click on it and press "Enable" if it's not already enabled

### 3. Configure the API Key

1. Navigate to "APIs & Services" > "Credentials" 
2. Find the API key `AIzaSyAlmmBfcowptQde9BOD8HOMbAxixIne8qs` in the list
3. Click on it to edit its settings
4. Under "Application restrictions", select "Android apps"
5. Click "Add" under the Android apps section
6. Enter the following details:
   - Package name: `com.example.ovarian_cyst_support_app`
   - SHA-1 certificate fingerprint: `EC:E4:31:35:ED:39:63:9C:B6:42:27:10:96:89:39:CC:05:E3:8B:63`
7. Click "Save"

### 4. Verify the API Key Has the Right API Restrictions

1. In the same API key editing page
2. Under "API restrictions", select "Restrict key" 
3. Make sure "Maps SDK for Android" is selected
4. Click "Save"

### 5. Getting the SHA-1 Certificate Fingerprint

If you need to generate the SHA-1 certificate fingerprint again:

**For Debug certificate:**

```bash
cd android
./gradlew signingReport
```

**For Release certificate:**
You'll need to refer to your keystore information.

## Notes

- Changes to API key settings can take up to 5 minutes to propagate
- Make sure your billing is enabled for the Google Cloud project
- Keep the API key confidential and never commit it directly to public repositories

## Additional Resources

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation/android-sdk/overview)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
