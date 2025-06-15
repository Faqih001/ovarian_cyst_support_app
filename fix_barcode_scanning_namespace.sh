#!/bin/bash
set -e

echo "Applying namespace fix for google_mlkit_barcode_scanning plugin..."

# Locate the package in pub cache
PLUGIN_PATH_0_10=$(find $HOME/.pub-cache -name "google_mlkit_barcode_scanning-0.10.0" -type d | head -1)
PLUGIN_PATH_0_7=$(find $HOME/.pub-cache -name "google_mlkit_barcode_scanning-0.7.0" -type d | head -1)

# First try 0.10.0, then fall back to 0.7.0
if [ -n "$PLUGIN_PATH_0_10" ]; then
  PLUGIN_PATH="$PLUGIN_PATH_0_10"
elif [ -n "$PLUGIN_PATH_0_7" ]; then
  PLUGIN_PATH="$PLUGIN_PATH_0_7"
else
  echo "Error: Could not find google_mlkit_barcode_scanning in pub cache"
  exit 1
fi

echo "Found plugin at: $PLUGIN_PATH"

# Check if the build.gradle file exists
BUILD_GRADLE="$PLUGIN_PATH/android/build.gradle"
if [ ! -f "$BUILD_GRADLE" ]; then
  echo "Error: Could not find build.gradle at $BUILD_GRADLE"
  exit 1
fi

# Back up the original file
cp "$BUILD_GRADLE" "${BUILD_GRADLE}.bak"

# Check if namespace already exists
if grep -q "namespace" "$BUILD_GRADLE"; then
  echo "Namespace already exists in build.gradle"
else
  # Add namespace to android block
  sed -i '/android {/a \    namespace "com.google_mlkit_barcode_scanning"' "$BUILD_GRADLE"
  echo "Added namespace to build.gradle"
fi

echo "Patch applied successfully!"
