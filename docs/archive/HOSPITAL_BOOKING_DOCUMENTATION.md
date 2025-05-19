# Hospital Booking Feature Documentation

## Overview
The hospital booking feature allows users to book appointments with both public and private hospitals in Kenya. It integrates with two APIs:

1. **Kenya Master Facility List (MFL) API** - For public hospitals
   - URL: `https://api.kmhfl.health.go.ke/api/v1`
   - Provides information about public health facilities across Kenya

2. **CKAN Data API** - For private hospitals
   - URL: `https://energydata.info/api/3/action/datastore_search`
   - Provides data about private healthcare facilities in Kenya

## Key Components

### 1. Hospital Service (`/lib/services/hospital_service.dart`)
- Manages communication with both APIs
- Handles fetching hospital data based on search criteria
- Provides fallback mock data when APIs fail to respond
- Uses the `FacilityType` enum to distinguish between public and private facilities

### 2. Facility Model (`/lib/models/facility.dart`)
- Represents hospital/facility data
- Compatible with both MFL and CKAN API data structures
- Contains information like location, services, contact details

### 3. Doctor Model (`/lib/models/doctor.dart`)
- Represents healthcare providers at facilities
- Used for doctor selection during booking

### 4. Hospital Booking Screens
- **KenyanHospitalBookingScreen**: The main screen for booking appointments
  - Allows searching for hospitals by name or county
  - Supports filtering by facility type (public/private)
  - Provides doctor selection if available
  - Includes appointment form for date/time selection
  
- **PrivateHospitalBookingScreen**: A wrapper for KenyanHospitalBookingScreen
  - Pre-configures the booking screen for private hospitals

### 5. Appointment Service (`/lib/services/appointment_service.dart`)
- Handles saving and retrieving appointment data
- Manages appointment status updates

## User Flow
1. User taps "Book Appointment" on the home screen
2. User selects hospital type (public or private)
3. User searches for a hospital by name or county
4. User selects a hospital from search results
5. User optionally selects a doctor
6. User fills in appointment details (date, time, purpose)
7. User submits the appointment booking

## Fallback Mechanism
If the APIs are unavailable, the app will automatically use mock data to ensure the feature remains functional even without internet connectivity.

## API Data Handling
- The hospital service converts API data to consistent Facility objects 
- Field mappings are handled for both API formats
- Error handling ensures the app degrades gracefully

## Extending the Feature
To add support for additional healthcare facility APIs:
1. Add new API endpoints to the HospitalService
2. Create appropriate data parsing functions
3. Update the FacilityType enum if needed
4. Add mock data for the new facility type
