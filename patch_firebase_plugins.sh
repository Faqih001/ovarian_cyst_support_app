#!/bin/bash

# This script fixes the buildConfig issue for Firebase plugins

# Find all Firebase-related Gradle files
FIREBASE_GRADLE_FILES=$(find ~/.pub-cache/hosted/pub.dev -path "*firebase*/android/build.gradle")
FIRESTORE_GRADLE_FILES=$(find ~/.pub-cache/hosted/pub.dev -path "*firestore*/android/build.gradle")
ML_KIT_GRADLE_FILES=$(find ~/.pub-cache/hosted/pub.dev -path "*google_ml*/android/build.gradle")

# Combine all the files
ALL_GRADLE_FILES="$FIREBASE_GRADLE_FILES $FIRESTORE_GRADLE_FILES $ML_KIT_GRADLE_FILES"

echo "Found $(echo $ALL_GRADLE_FILES | wc -w) Gradle files to patch"

# Function to patch Gradle files
patch_file() {
    local file=$1
    echo "Processing $file"
    
    # Check if buildFeatures block exists
    if grep -q "buildFeatures" "$file"; then
        echo "buildFeatures block already exists in $file"
        # Make sure buildConfig is enabled
        if ! grep -q "buildConfig true" "$file"; then
            # Find the buildFeatures block and add buildConfig = true
            sed -i '/buildFeatures\s*{/ a \        buildConfig true' "$file"
            echo "Added buildConfig = true to existing buildFeatures block"
        fi
    else
        # Add buildFeatures block before the closing brace of android block
        sed -i '/android {/,/}/ {
            /}/ {
                /}\s*$/ i\
    buildFeatures {\
        buildConfig true\
    }
                t
            }
        }' "$file"
        echo "Added buildFeatures block to $file"
    fi
}

# Process each file
for file in $ALL_GRADLE_FILES; do
    patch_file "$file"
done

echo "All files processed successfully"
