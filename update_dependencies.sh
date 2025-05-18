#!/bin/bash

echo "==== Ovarian Cyst Support App Dependency Update ===="

# Check if there are any outdated packages
echo "Checking for outdated packages..."
flutter pub outdated

# Ask for confirmation
echo -e "\nDo you want to update all packages to their latest compatible versions? (y/n)"
read answer

if [ "$answer" != "${answer#[Yy]}" ]; then
  echo "Updating packages..."
  flutter pub upgrade

  echo -e "\nRunning Flutter clean to ensure clean build..."
  flutter clean

  echo -e "\nGetting dependencies..."
  flutter pub get

  echo -e "\nVerifying app build after update..."
  flutter build apk --debug --flavor development
  
  echo -e "\nUpdate completed! Please test the app thoroughly."
else
  echo "Update cancelled."
fi
