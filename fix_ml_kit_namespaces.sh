#!/bin/bash
set -e

echo "Fixing namespaces for all Google ML Kit plugins..."

# Find all ML Kit plugins in the pub cache
ML_KIT_PLUGINS=$(find $HOME/.pub-cache -name "google_mlkit_*-*" -type d)

if [ -z "$ML_KIT_PLUGINS" ]; then
  echo "No ML Kit plugins found in pub cache"
  exit 1
fi

for PLUGIN_PATH in $ML_KIT_PLUGINS; do
  # Get plugin name from path
  PLUGIN_NAME=$(basename "$PLUGIN_PATH" | sed 's/-[0-9.]*$//')
  
  echo "Processing $PLUGIN_NAME..."
  
  # Check if the build.gradle file exists
  BUILD_GRADLE="$PLUGIN_PATH/android/build.gradle"
  if [ ! -f "$BUILD_GRADLE" ]; then
    echo "  Skipping: Could not find build.gradle at $BUILD_GRADLE"
    continue
  fi
  
  # Back up the original file if not already backed up
  if [ ! -f "${BUILD_GRADLE}.bak" ]; then
    cp "$BUILD_GRADLE" "${BUILD_GRADLE}.bak"
  fi
  
  # Check if namespace already exists
  if grep -q "namespace" "$BUILD_GRADLE"; then
    echo "  Namespace already exists in build.gradle"
  else
    # Extract plugin ID from group declaration
    GROUP_ID=$(grep "^group" "$BUILD_GRADLE" | cut -d "'" -f 2 || echo "")
    
    if [ -z "$GROUP_ID" ]; then
      # Use the plugin name as a fallback
      GROUP_ID="com.$PLUGIN_NAME"
    fi
    
    # Add namespace to android block
    sed -i "/android {/a \\    namespace \"$GROUP_ID\"" "$BUILD_GRADLE"
    echo "  Added namespace \"$GROUP_ID\" to build.gradle"
  fi
done

echo "All ML Kit plugins processed. Rebuilding Flutter app now..."
