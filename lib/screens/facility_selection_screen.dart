import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ovarian_cyst_support_app/services/facility_service.dart';
import 'package:ovarian_cyst_support_app/screens/kenyan_hospital_booking_screen.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class FacilitySelectionScreen extends StatefulWidget {
  const FacilitySelectionScreen({super.key});

  @override
  State<FacilitySelectionScreen> createState() =>
      _FacilitySelectionScreenState();
}

class _FacilitySelectionScreenState extends State<FacilitySelectionScreen> {
  final FacilityService _facilityService = FacilityService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<HealthcareFacility> _facilities = [];
  List<String> _counties = [];
  List<String> _facilityTypes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _selectedCounty;
  String? _selectedType;
  Position? _currentPosition;
  double _maxDistance = 50.0; // Default 50 km radius
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _loadFacilities();
      await _requestLocationPermission();
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFacilities() async {
    try {
      final facilities = await _facilityService.loadFacilities();
      final counties = _facilityService.getAvailableCounties();
      final types = _facilityService.getAvailableFacilityTypes();

      if (mounted) {
        setState(() {
          _facilities = facilities;
          _counties = counties;
          _facilityTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _locationEnabled = true;
          });
          _searchFacilities();
        }
      }
    } catch (e) {
      // Location services are not available or permission denied
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _searchFacilities() async {
    setState(() => _isLoading = true);

    try {
      final facilities = await _facilityService.searchFacilities(
        query: _searchController.text,
        county: _selectedCounty,
        type: _selectedType,
        latitude: _locationEnabled ? _currentPosition?.latitude : null,
        longitude: _locationEnabled ? _currentPosition?.longitude : null,
        maxDistance: _locationEnabled ? _maxDistance : null,
      );

      if (mounted) {
        setState(() {
          _facilities = facilities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Facilities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCounty,
                    decoration: const InputDecoration(
                      labelText: 'County',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Counties'),
                      ),
                      ..._counties.map(
                        (county) => DropdownMenuItem(
                          value: county,
                          child: Text(county),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedCounty = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Facility Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ..._facilityTypes.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  if (_locationEnabled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Distance Range',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxDistance,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: '${_maxDistance.round()} km',
                      onChanged: (value) {
                        setModalState(() {
                          _maxDistance = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCounty = null;
                              _selectedType = null;
                              _maxDistance = 50.0;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _searchFacilities();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Healthcare Facility'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search facilities...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _searchFacilities();
              },
            ),
          ),
          Expanded(
            child: _buildFacilitiesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading facilities',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadFacilities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_facilities.isEmpty) {
      return const Center(
        child: Text('No facilities found'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _facilities.length,
      itemBuilder: (context, index) {
        final facility = _facilities[index];
        String distance = '';

        if (_locationEnabled && _currentPosition != null) {
          final distanceInKm = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                facility.latitude,
                facility.longitude,
              ) /
              1000; // Convert to kilometers
          distance = '${distanceInKm.toStringAsFixed(1)} km';
        }

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            title: Text(
              facility.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(facility.type),
                Text('${facility.location}, ${facility.county}'),
                if (distance.isNotEmpty)
                  Text(
                    distance,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KenyanHospitalBookingScreen(
                      facility: facility.toMap(),
                    ),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KenyanHospitalBookingScreen(
                    facility: facility.toMap(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
