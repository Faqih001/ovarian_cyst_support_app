# Ovarian Cyst Support App

A comprehensive mobile application to support women diagnosed with ovarian cysts. The app provides educational resources, symptom tracking, community support, and healthcare appointment booking specifically for Kenyan users.

## 📱 Features

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

## 🔧 Technical Details

### Data Sources
- Healthcare facilities data from a comprehensive CSV database
- Mock data as fallback for testing and offline use

### Implementation Notes
- Uses Flutter for cross-platform development
- Firebase integration for authentication and data storage
- Offline capability for essential features

## 🚀 Getting Started

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

## 📋 Healthcare Facilities Integration

### Overview

The healthcare facilities booking feature allows users to search for and book appointments with three types of healthcare facilities in Kenya:

1. **Ministry of Health Facilities** - Government-run public hospitals and health centers
2. **Private Practice** - Individual healthcare providers in private practice
3. **Private Enterprise** - Private hospitals, clinics, and healthcare institutions

### Data Source

The implementation uses a local CSV file (`assets/healthcare_facilities.csv`) that contains comprehensive data about healthcare facilities across Kenya. This approach offers several advantages:

- **Offline Access**: Users can search for facilities even without an internet connection
- **Reliability**: No dependency on external APIs that may have downtime or rate limits
- **Performance**: Faster search results and less data usage

The CSV file includes the following key information for each facility:
- Facility name
- Type (Hospital, Dispensary, Health Center, etc.)
- Owner (Ministry of Health, Private Practice, Private Enterprise)
- Location (County, Sub-County, Division)
- Geographic coordinates (Latitude, Longitude)
- Nearest landmark

### Implementation Details

#### Key Components

1. **HospitalService Class**
   - Loads and parses the CSV file containing facility data
   - Provides methods to search and filter facilities
   - Implements caching to improve performance
   - Offers mock data as fallback in case of errors

2. **Facility Model**
   - Represents healthcare facilities with all relevant attributes
   - Supports conversion from CSV data to structured model objects

3. **Doctor Model**
   - Represents healthcare providers for appointment booking
   - Currently uses mock data since the CSV doesn't contain doctor information

4. **FacilityType Enum**
   - Defines the three categories of healthcare facilities:
     - `ministry`: Ministry of Health facilities (public)
     - `privatePractice`: Individual healthcare providers
     - `privateEnterprise`: Private hospitals and institutions

5. **KenyanHospitalBookingScreen**
   - Provides UI for searching and selecting facilities
   - Allows filtering by facility type
   - Supports selecting doctors and booking appointments

#### User Flow

1. User selects "Book Appointment" on the home screen
2. User chooses the type of healthcare facility (Ministry, Private Practice, or Private Enterprise)
3. User searches for facilities by name or selects a county
4. User selects a facility from the search results
5. User optionally selects a doctor (when available)
6. User completes the appointment form with date, time, and purpose
7. Appointment is saved to the database

#### Technical Considerations

1. **CSV Loading**
   - The CSV file is loaded and parsed asynchronously when the service is first used
   - Results are cached to avoid repeated loading
   - Standard Flutter's `rootBundle` is used to access the asset

2. **Search and Filtering**
   - Facilities can be filtered by:
     - Facility type (Ministry, Private Practice, Private Enterprise)
     - Search term (matching facility name)
     - County
   - Results are paginated for better performance

3. **Error Handling**
   - Mock data is provided as a fallback when:
     - The CSV file cannot be loaded
     - The parsing fails
     - No matching facilities are found

#### Future Enhancements

1. **Doctor Data**: Add actual doctor information for facilities
2. **Advanced Filtering**: Support filtering by available services, ratings, etc.
3. **GeoLocation**: Add the ability to find nearby facilities based on user location
4. **Appointment Availability**: Show real-time availability of appointment slots
5. **Facility Reviews**: Allow users to view and submit ratings and reviews

## 🐛 Debugging and Troubleshooting

### Common Issues and Solutions

#### Notification Service Issues

**Problem**: Inconsistent use of the `NotificationService.scheduleAppointmentReminder()` method with different parameter orders.

**Solution**: Standardized on using the method that takes an `Appointment` object directly.

```dart
// CORRECT - Using the Appointment object directly
await NotificationService.scheduleAppointmentReminder(appointment);
```

#### DateTime Parsing Without Error Handling

**Problem**: Time slot parsing was done inline without proper error handling.

**Solution**: Added a dedicated helper method with try-catch for robust error handling:

```dart
DateTime _createAppointmentDateTime() {
  try {
    final List<int> timeComponents = _selectedTimeSlot.split(':')
        .map((part) => int.parse(part.trim()))
        .toList();
    int hour = timeComponents[0];
    int minute = timeComponents.length > 1 ? timeComponents[1] : 0;
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
  } catch (e) {
    // Fallback to noon if parsing fails
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 12, 0);
  }
}
```

#### Null Safety Issues

**Problem**: Some null checks were redundant, while others were missing where needed.

**Solution**: Fixed null safety issues by:
- Removing redundant null checks where types are non-nullable
- Adding proper null checks where needed
- Using the null-aware operators (?., ??, ?=) appropriately

### Flutter Best Practices Applied

1. **Clean Architecture Pattern**
   - Maintained separation between UI (screens), business logic (services), and data (models)
   - Used dependency injection for services

2. **Error Handling**
   - Added try-catch blocks for network and parsing operations
   - Provided fallback values for error cases
   - Displayed user-friendly error messages

3. **Code Organization**
   - Followed the standard Flutter project structure:
     ```
     lib/
       ├── main.dart
       ├── models/          # Data models
       ├── screens/         # UI screens
       ├── services/        # Business logic and API calls
       ├── widgets/         # Reusable UI components
       └── utils/           # Utility functions and constants
     ```
   - Grouped related functionality in dedicated methods
   - Used clear, descriptive naming conventions

4. **State Management**
   - Used setState() appropriately for local UI state
   - Managed loading states and error messages consistently

5. **Package Usage**
   - Imported only necessary packages
   - Followed recommended patterns for each package
   - Kept dependencies up-to-date

### Helpful Development Tools

1. **Flutter DevTools**
   - Use for performance monitoring
   - Inspect widget trees
   - Debug layout issues

2. **VS Code Extensions**
   - Flutter and Dart extensions
   - Better Comments for improved code documentation

3. **Static Analysis**
   - Enable strict lint rules in analysis_options.yaml
   - Run `flutter analyze` before committing code
   - Address all warnings, not just errors

## 📚 References

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Package Guidelines](https://docs.flutter.dev/packages-and-plugins)
