#!/bin/bash

echo "Creating fix_firebase_modules.gradle"
cat > android/fix_firebase_modules.gradle << EOF
// Apply this script to all Firebase-related modules
subprojects { project ->
    if (project.name == 'cloud_firestore' || 
        project.name == 'firebase_auth' || 
        project.name == 'firebase_core' ||
        project.name == 'firebase_storage' ||
        project.name == 'firebase_messaging' ||
        project.name == 'firebase_analytics' ||
        project.name == 'firebase_app_check' ||
        project.name.contains('firebase') ||
        project.name.contains('google_ml_kit')) {
        
        project.afterEvaluate {
            android {
                buildFeatures {
                    buildConfig true
                }
            }
        }
    }
}
EOF

echo "Updating settings.gradle.kts to apply the fix"
# Create a backup of the settings file
cp android/settings.gradle.kts android/settings.gradle.kts.bak

# Update the settings file to apply our fix
cat >> android/settings.gradle.kts << EOF

// Apply fix for Firebase modules
apply(from = "\${rootProject.projectDir}/fix_firebase_modules.gradle")
EOF

echo "Script completed successfully"
