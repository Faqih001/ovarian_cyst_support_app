# Kenyan Healthcare Facilities Integration

## Overview

This documentation covers the implementation of the healthcare facilities booking feature in the Ovarian Cyst Support App. The feature allows users to search for and book appointments with three types of healthcare facilities in Kenya:

1. **Ministry of Health Facilities** - Government-run public hospitals and health centers
2. **Private Practice** - Individual healthcare providers in private practice
3. **Private Enterprise** - Private hospitals, clinics, and healthcare institutions

## Data Source

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

## Implementation Details

### Key Components

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

### User Flow

1. User selects "Book Appointment" on the home screen
2. User chooses the type of healthcare facility (Ministry, Private Practice, or Private Enterprise)
3. User searches for facilities by name or selects a county
4. User selects a facility from the search results
5. User optionally selects a doctor (when available)
6. User completes the appointment form with date, time, and purpose
7. Appointment is saved to the database

## Technical Considerations

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

## Future Enhancements

1. **Doctor Data**: Add actual doctor information for facilities
2. **Advanced Filtering**: Support filtering by available services, ratings, etc.
3. **GeoLocation**: Add the ability to find nearby facilities based on user location
4. **Appointment Availability**: Show real-time availability of appointment slots
5. **Facility Reviews**: Allow users to view and submit ratings and reviews
