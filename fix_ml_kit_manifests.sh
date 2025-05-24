#!/bin/bash
set -e

echo "Fixing AndroidManifest.xml package attribute for ML Kit plugins..."

# Find google_mlkit_smart_reply in the pub cache
PLUGIN_PATH=$(find $HOME/.pub-cache -name "google_mlkit_smart_reply-0.7.0" -type d | head -1)

if [ -z "$PLUGIN_PATH" ]; then
  echo "Error: Could not find google_mlkit_smart_reply in pub cache"
  exit 1
fi

echo "Found plugin at: $PLUGIN_PATH"

# Check if the AndroidManifest.xml file exists
MANIFEST_PATH="$PLUGIN_PATH/android/src/main/AndroidManifest.xml"
if [ ! -f "$MANIFEST_PATH" ]; then
  echo "Error: Could not find AndroidManifest.xml at $MANIFEST_PATH"
  exit 1
fi

# Back up the original file
cp "$MANIFEST_PATH" "${MANIFEST_PATH}.bak"

# Remove package attribute from AndroidManifest.xml
sed -i 's/ package="com.google_mlkit_smart_reply"//g' "$MANIFEST_PATH"

echo "Fixed AndroidManifest.xml for google_mlkit_smart_reply!"

# Now check for all ML Kit plugins and fix them
ML_KIT_PLUGINS=$(find $HOME/.pub-cache -name "google_mlkit_*-*" -type d)

if [ -n "$ML_KIT_PLUGINS" ]; then
  for PLUGIN_DIR in $ML_KIT_PLUGINS; do
    MANIFEST_FILE="$PLUGIN_DIR/android/src/main/AndroidManifest.xml"
    
    # Check if the manifest file exists
    if [ ! -f "$MANIFEST_FILE" ]; then
      continue
    fi
    
    PLUGIN_NAME=$(basename "$PLUGIN_DIR" | sed 's/-[0-9.]*$//')
    echo "Checking $PLUGIN_NAME..."
    
    # Back up the original file if not already backed up
    if [ ! -f "${MANIFEST_FILE}.bak" ]; then
      cp "$MANIFEST_FILE" "${MANIFEST_FILE}.bak"
    fi
    
    # Check if it contains a package attribute
    if grep -q 'package="' "$MANIFEST_FILE"; then
      echo "  Removing package attribute from $MANIFEST_FILE"
      sed -i 's/ package="[^"]*"//g' "$MANIFEST_FILE"
    fi
  done
fi

echo "All ML Kit plugins AndroidManifest.xml files processed!"
