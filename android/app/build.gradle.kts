plugins {
    id("com.android.application")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ovarian_cyst_support_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Using the required NDK version for plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ovarian_cyst_support_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Updated to support tflite_flutter
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add coreLibraryDesugaring for Java 8+ APIs on Android 7 and below
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))

    // Add Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Add other Firebase products needed for the app
    implementation("com.google.firebase:firebase-auth") // For authentication
    implementation("com.google.firebase:firebase-firestore") // For Cloud Firestore
    implementation("com.google.firebase:firebase-messaging") // For Cloud Messaging

    // Add Kotlin standard library with explicit version matching plugin version
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
}
