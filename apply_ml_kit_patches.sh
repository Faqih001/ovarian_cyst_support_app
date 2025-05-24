#!/bin/bash
set -e

echo "Applying patches for ML Kit plugins..."

# Get pub cache directory directly
PUB_CACHE="$HOME/.pub-cache"
if [[ ! -d "$PUB_CACHE" ]]; then
  # Try alternative location
  PUB_CACHE="$HOME/snap/flutter/common/flutter/.pub-cache"
fi

echo "Flutter Pub cache located at: $PUB_CACHE"

# Patch google_mlkit_barcode_scanning
BARCODE_PLUGIN_DIR="$PUB_CACHE/hosted/pub.dev/google_mlkit_barcode_scanning-"
if [ -d "$PUB_CACHE" ]; then
  # Find the specific version directory
  BARCODE_DIR=$(find "$PUB_CACHE/hosted/pub.dev/" -name "google_mlkit_barcode_scanning-*" -type d | sort -V | tail -n 1)
  
  if [ -n "$BARCODE_DIR" ]; then
    echo "Found barcode scanning plugin at: $BARCODE_DIR"
    # Copy the patched build.gradle
    cp -v ./patches/google_mlkit_barcode_scanning/android/build.gradle "$BARCODE_DIR/android/"
    echo "✅ Successfully patched google_mlkit_barcode_scanning"
  else
    echo "❌ Could not find google_mlkit_barcode_scanning directory in pub cache"
  fi
  
  # Patch smart reply plugin too
  SMART_REPLY_DIR=$(find "$PUB_CACHE/hosted/pub.dev/" -name "google_mlkit_smart_reply-*" -type d | sort -V | tail -n 1)
  
  if [ -n "$SMART_REPLY_DIR" ]; then
    echo "Found smart reply plugin at: $SMART_REPLY_DIR"
    # Copy the patched build.gradle
    cp -v ./patches/google_mlkit_smart_reply/android/build.gradle "$SMART_REPLY_DIR/android/"
    echo "✅ Successfully patched google_mlkit_smart_reply"
  else
    echo "❌ Could not find google_mlkit_smart_reply directory in pub cache"
  fi
else
  echo "❌ Could not determine Flutter pub cache path"
  exit 1
fi

echo "All patches applied successfully!"
