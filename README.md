# Ovarian Cyst Support App

A comprehensive mobile application to support women diagnosed with ovarian cysts. The app provides educational resources, symptom tracking, community support, and healthcare appointment booking specifically for Kenyan users.

## Features

### Healthcare Facility Integration
- Book appointments with three types of healthcare facilities in Kenya:
  - **Ministry of Health Facilities** (Government-run public hospitals)
  - **Private Practice** (Individual healthcare providers)
  - **Private Enterprise** (Private hospitals and institutions)
- Search facilities by name or county
- Browse doctors when available
- Schedule appointments with date and time selection

### Symptom Tracking
- Track pain levels, symptoms, and medication
- Visualize patterns over time
- Set reminders for medication

### Educational Resources
- Learn about ovarian cysts, treatments, and management
- Access articles and videos from verified medical sources
- Understand diagnostic procedures and recovery

### Community Support
- Join support groups
- Share experiences with others
- Ask questions to healthcare professionals

## Technical Details

### Data Sources
- Healthcare facilities data from a comprehensive CSV database
- Mock data as fallback for testing and offline use

### Implementation Notes
- Uses Flutter for cross-platform development
- Firebase integration for authentication and data storage
- Offline capability for essential features

## Documentation

For more detailed documentation, see:
- [Healthcare Facilities Integration](docs/HEALTHCARE_FACILITIES_INTEGRATION.md)
- [Debugging Guide](DEBUG_GUIDE.md)
- [Flutter Debugging Guide](FLUTTER_DEBUG_GUIDE.md)

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or Visual Studio Code
- Firebase project (for authentication and database)

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (follow instructions in firebase.json)
4. Run `flutter run` to start the application
