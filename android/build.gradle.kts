buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

// Set the build directory location
rootProject.buildDir = File(rootProject.projectDir, "../build/host")

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Add configuration to resolve dependency conflicts
    configurations.all {
        resolutionStrategy {
            // Force specific versions for conflicting dependencies
            force("com.google.firebase:firebase-iid:21.1.0")
            force("com.google.firebase:firebase-messaging:23.4.1")
            
            // Exclude conflicting classes
            exclude(group = "com.google.firebase", module = "firebase-iid")
        }
    }
}

// Let Flutter handle the build directory setup instead of overriding it
// This prevents issues with manifest file locations
// Configure subprojects directly without using projectsEvaluated
subprojects {
    // Use afterEvaluate on each individual subproject instead of globally
    afterEvaluate {
        // Enable buildConfig for Firebase and ML Kit modules
        plugins.withId("com.android.library") {
            if (project.name == "cloud_firestore" || 
                project.name == "firebase_auth" || 
                project.name == "firebase_core" ||
                project.name == "firebase_storage" ||
                project.name == "firebase_messaging" ||
                project.name == "firebase_analytics" ||
                project.name == "firebase_app_check" ||
                project.name.contains("firebase") ||
                project.name.contains("google_ml_kit")) {
                
                project.extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
                    buildFeatures {
                        buildConfig = true
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
