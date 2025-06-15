#!/bin/bash

echo "==== Ovarian Cyst Support App Linting & Analysis ===="
echo "Running Flutter analyze..."
flutter analyze

echo -e "\nRunning Flutter lints..."
flutter pub run dart_code_metrics:metrics analyze lib

echo -e "\nChecking for outdated packages..."
flutter pub outdated

echo -e "\nAnalysis completed!"
