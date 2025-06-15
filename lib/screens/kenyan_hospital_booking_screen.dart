import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/models/facility.dart';
import 'package:ovarian_cyst_support_app/models/doctor.dart';
import 'package:ovarian_cyst_support_app/services/hospital_service.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/appointment_service.dart';
import 'package:ovarian_cyst_support_app/widgets/facility_map_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ovarian_cyst_support_app/widgets/app_toast.dart' as toast;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class KenyanHospitalBookingScreen extends StatefulWidget {
  final FacilityType initialFacilityType;
  final Map<String, dynamic>? facility;

  const KenyanHospitalBookingScreen({
    super.key,
    this.initialFacilityType = FacilityType.ministry,
    this.facility,
  });

  @override
  State<KenyanHospitalBookingScreen> createState() =>
      _KenyanHospitalBookingScreenState();
}

class _KenyanHospitalBookingScreenState
    extends State<KenyanHospitalBookingScreen> {
  late final HospitalService _hospitalService;
  final AppointmentService _appointmentService = AppointmentService();
  late AuthService _authService;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  FacilityType _selectedFacilityType = FacilityType.ministry;
  String? _selectedCounty;
  List<String> _counties = [];
  List<Facility> _facilities = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasMoreFacilities = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  Facility? _selectedFacility;
  Doctor? _selectedDoctor;
  List<Doctor> _doctors = [];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isBooking = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isOnline = true;
  bool _showFilterPanel = false;
  bool _isConnectivityBannerVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedFacilityType = widget.initialFacilityType;
    _scrollController.addListener(_scrollListener);
    _checkConnectivity();
    _setupConnectivityListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hospitalService = Provider.of<HospitalService>(context);
    _authService = Provider.of<AuthService>(context);

    // If a facility is provided, select it immediately
    if (widget.facility != null) {
      final facility = Facility(
        id: widget.facility!['id'],
        code: widget.facility!['code'] ?? '',
        name: widget.facility!['name'],
        facilityType: widget.facility!['facilityType'],
        county: widget.facility!['county'],
        subCounty: widget.facility!['subCounty'],
        ward: widget.facility!['division'] ?? '',
        owner: widget.facility!['owner'],
        operationalStatus: 'Operational',
        latitude: widget.facility!['latitude'],
        longitude: widget.facility!['longitude'],
        phone: widget.facility!['phone'],
        email: widget.facility!['email'],
        website: widget.facility!['website'],
        services: _convertToStringList(widget.facility!['services']),
        description: widget.facility!['description'],
      );
      _selectedFacility = facility;
      _loadDoctorsForFacility(facility);
    } else {
      _loadCounties();
      _loadFacilities(reset: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to safely convert list data to List<String>
  List<String> _convertToStringList(dynamic services) {
    if (services == null) {
      return [];
    }

    // If it's already a List<String>
    if (services is List<String>) {
      return services;
    }

    // If it's a List<dynamic> or other list type
    if (services is List) {
      return services.map((item) => item?.toString() ?? '').toList();
    }

    // If it's a single string
    if (services is String) {
      return [services];
    }

    // If it's a map or other object, convert to JSON string
    if (services is Map) {
      return [jsonEncode(services)];
    }

    // Default case - return empty list
    return [];
  }

  // Check initial connectivity
  Future<void> _checkConnectivity() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResults);
  }

  // Set up listener for connectivity changes
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Update connectivity status
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool previousState = _isOnline;
    setState(() {
      _isOnline = !results.contains(ConnectivityResult.none);
      _isConnectivityBannerVisible = true;
    });

    // If we've gone from offline to online, refresh data
    if (!previousState && _isOnline) {
      _loadCounties();
      _loadFacilities(reset: true);

      // If we had a selected facility, also refresh doctors
      if (_selectedFacility != null) {
        _loadDoctorsForFacility(_selectedFacility!);
      }
    }

    // Show appropriate message when connectivity changes
    if (_isOnline && !previousState) {
      toast.AppToast.show(
        context,
        message: 'Back online. Data syncing...',
        isError: false,
      );

      // Hide banner after some time
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isConnectivityBannerVisible = false;
          });
        }
      });
    } else if (!_isOnline && previousState) {
      toast.AppToast.show(
        context,
        message: 'You are offline. Some features may be limited.',
        isError: true,
        duration: const Duration(seconds: 4),
      );
    }

    // Log connectivity change
    debugPrint('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
  }

  // Load the list of counties for filtering
  Future<void> _loadCounties() async {
    try {
      final counties = await _hospitalService.getCounties();
      setState(() {
        _counties = counties;
      });
    } catch (e) {
      debugPrint('Error loading counties: $e');
      setState(() {
        _counties = [];
      });
    }
  }

  // Infinite scroll listener
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreFacilities) {
      _loadMoreFacilities();
    }
  }

  // Load initial facilities or refresh the list
  Future<void> _loadFacilities({required bool reset}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMoreFacilities = true;
      });
    }

    try {
      final facilities = await _hospitalService.getFacilities(
        searchQuery: _isSearching ? _searchController.text : null,
        county: _selectedCounty,
        page: _currentPage,
        pageSize: _pageSize,
        facilityType: _selectedFacilityType,
      );

      setState(() {
        if (reset) {
          _facilities = facilities;
        } else {
          _facilities.addAll(facilities);
        }
        _isLoading = false;
        _hasMoreFacilities = facilities.length == _pageSize;
      });
    } catch (e) {
      debugPrint('Error loading facilities: $e');
      setState(() {
        if (reset) {
          _facilities = [];
        }
        _isLoading = false;
        _hasMoreFacilities = false;
      });
      if (mounted) {
        // Check if the widget is still in the tree
        toast.AppToast.showError(
          context,
          'Failed to load facilities. Please try again later.',
        );
      }
    }
  }

  // Load more facilities when scrolling (pagination)
  Future<void> _loadMoreFacilities() async {
    if (_isLoading || !_hasMoreFacilities) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    await _loadFacilities(reset: false);
  }

  // Handle the search action
  void _handleSearch() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
    _loadFacilities(reset: true);
  }

  // Handle refresh action (pull to refresh)
  Future<void> _handleRefresh() async {
    await _loadFacilities(reset: true);
    return;
  }

  // Change the selected facility type
  void _changeFacilityType(FacilityType type) {
    setState(() {
      _selectedFacilityType = type;
      _selectedFacility = null;
      _selectedDoctor = null;
      _doctors = [];
      _showFilterPanel = false;
    });
    _loadFacilities(reset: true);
  }

  // Filter facilities by county
  void _filterByCounty(String? county) {
    setState(() {
      _selectedCounty = county;
      _showFilterPanel = false;
    });
    _loadFacilities(reset: true);
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedCounty = null;
      _searchController.clear();
      _isSearching = false;
      _showFilterPanel = false;
    });
    _loadFacilities(reset: true);
  }

  // Load doctors for a selected facility
  Future<void> _loadDoctorsForFacility(Facility facility) async {
    setState(() {
      _selectedFacility = facility;
      _selectedDoctor = null;
      _isLoading = true;
    });

    try {
      final doctors = await _hospitalService.getDoctorsForFacility(facility.id);
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      setState(() {
        _doctors = [];
        _isLoading = false;
      });
      if (mounted) {
        // Check if the widget is still in the tree
        toast.AppToast.showError(
          context,
          'Failed to load doctors. Please try again later.',
        );
      }
    }
  }

  // Select a doctor for booking
  void _selectDoctor(Doctor doctor) {
    setState(() {
      _selectedDoctor = doctor;
    });
  }

  // Show date picker for booking
  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final firstDate = now;
    // Allow booking up to 90 days in advance
    final lastDate = now.add(const Duration(days: 90));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime day) {
        // Make weekends not selectable if the doctor is not available
        if (_selectedDoctor != null) {
          // Convert day of week to string (1=Monday, 7=Sunday)
          final dayName = DateFormat('EEEE').format(day);
          return _selectedDoctor!.availableDays.contains(dayName);
        }
        // By default, allow all days
        return true;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Show time picker for booking
  Future<void> _showTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // Book an appointment with the selected facility, doctor, date, and time
  Future<void> _bookAppointment() async {
    if (_selectedFacility == null ||
        _selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      toast.AppToast.showError(
        context,
        'Please select all required information',
      );
      return;
    }

    if (!_isOnline) {
      toast.AppToast.showError(
        context,
        'Cannot book appointments while offline',
      );
      return;
    }

    // Check if user is authenticated
    if (!_authService.isAuthenticated) {
      toast.AppToast.showError(context, 'Please log in to book an appointment');
      // Navigate to login or show login dialog
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      // Combine date and time
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Book the appointment
      await _appointmentService.bookAppointment(
        userId: _authService.currentUser!.uid,
        facilityId: _selectedFacility!.id,
        facilityName: _selectedFacility!.name,
        doctorId: _selectedDoctor!.id,
        doctorName: _selectedDoctor!.name,
        appointmentDateTime: appointmentDateTime,
        status: 'pending', // Initial status
        notes: 'Appointment for ovarian cyst consultation',
      );

      setState(() {
        _isBooking = false;
        // Reset selection after successful booking
        _selectedDate = null;
        _selectedTime = null;
      });

      // Show success message
      if (mounted) {
        toast.AppToast.showSuccess(context, 'Appointment booked successfully');
      }
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      setState(() {
        _isBooking = false;
      });
      if (mounted) {
        toast.AppToast.showError(
          context,
          'Failed to book appointment. Please try again later.',
        );
      }
    }
  }

  // Back to facility selection
  void _backToFacilitySelection() {
    setState(() {
      _selectedFacility = null;
      _selectedDoctor = null;
      _doctors = [];
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  // Toggle filter panel visibility
  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });
  }

  // Check if the filters are active
  bool get _areFiltersActive => _selectedCounty != null || _isSearching;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Healthcare Facility'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
              color: _areFiltersActive ? AppColors.primary : null,
            ),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filter options',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity banner
          _buildConnectivityBanner(),
          // Filter panel
          if (_showFilterPanel) _buildFilterPanel(),
          // Facility type tabs
          _buildFacilityTypeTabs(),
          // Search bar
          _buildSearchBar(),
          // Main content
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: _selectedFacility == null
                  ? _buildFacilityList()
                  : _buildFacilityDetails(),
            ),
          ),
        ],
      ),
    );
  }

  // Build a connectivity banner that shows online/offline status
  Widget _buildConnectivityBanner() {
    if (!_isConnectivityBannerVisible) {
      return const SizedBox.shrink();
    }

    // Banner will auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isConnectivityBannerVisible) {
        setState(() {
          _isConnectivityBannerVisible = false;
        });
      }
    });

    return AnimatedOpacity(
      opacity: _isConnectivityBannerVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOnline ? Colors.green.shade400 : Colors.red.shade400,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isOnline ? Colors.green : Colors.red).withValues(
                  alpha: 0.08 * 255,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isOnline ? Icons.check_circle : Icons.wifi_off,
                color: _isOnline ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isOnline
                      ? 'Connected - All features available'
                      : 'Offline - Limited functionality',
                  style: TextStyle(
                    color: _isOnline
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: _isOnline ? Colors.green : Colors.red,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _isConnectivityBannerVisible = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter panel widget
  Widget _buildFilterPanel() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by County',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All Counties'),
                  selected: _selectedCounty == null,
                  onSelected: (selected) {
                    if (selected) {
                      _filterByCounty(null);
                    }
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppColors.primary.withAlpha(
                    51,
                  ), // approximately 0.2 opacity
                ),
                const SizedBox(width: 8),
                ..._counties.map(
                  (county) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(county),
                      selected: _selectedCounty == county,
                      onSelected: (selected) {
                        if (selected) {
                          _filterByCounty(county);
                        } else {
                          _filterByCounty(null);
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppColors.primary.withAlpha(
                        51,
                      ), // approximately 0.2 opacity
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Facility type tabs widget
  Widget _buildFacilityTypeTabs() {
    return Container(
      color: Colors.white,
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFacilityTypeTab(
            title: 'Ministry of Health',
            type: FacilityType.ministry,
            icon: Icons.local_hospital,
          ),
          _buildFacilityTypeTab(
            title: 'Private Practice',
            type: FacilityType.privatePractice,
            icon: Icons.person,
          ),
          _buildFacilityTypeTab(
            title: 'Private Enterprise',
            type: FacilityType.privateEnterprise,
            icon: Icons.business,
          ),
        ],
      ),
    );
  }

  // Individual facility type tab widget
  Widget _buildFacilityTypeTab({
    required String title,
    required FacilityType type,
    required IconData icon,
  }) {
    final isSelected = _selectedFacilityType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _changeFacilityType(type),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Search bar widget
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search facilities by name',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    if (_isSearching) {
                      setState(() {
                        _isSearching = false;
                      });
                      _loadFacilities(reset: true);
                    }
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _handleSearch(),
        onChanged: (value) {
          if (value.isEmpty && _isSearching) {
            setState(() {
              _isSearching = false;
            });
            _loadFacilities(reset: true);
          }
        },
      ),
    );
  }

  // Facility list widget
  Widget _buildFacilityList() {
    if (_isLoading && _facilities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No facilities found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _areFiltersActive
                  ? 'Try changing your filters or search terms'
                  : 'Try a different facility type',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (_areFiltersActive)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _clearFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Filters'),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount:
          _facilities.length + (_isLoading && _hasMoreFacilities ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _facilities.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final facility = _facilities[index];
        return _buildFacilityCard(facility);
      },
    );
  }

  // Individual facility card widget
  Widget _buildFacilityCard(Facility facility) {
    final hasLocation = facility.latitude != null && facility.longitude != null;
    final hasContactInfo =
        facility.phone != null ||
        facility.email != null ||
        facility.website != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _loadDoctorsForFacility(facility),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(
                      51,
                    ), // approximately 0.2 opacity
                    radius: 24,
                    child: Icon(
                      _getFacilityIcon(facility.facilityType),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          facility.facilityType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${facility.county}, ${facility.subCounty}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Contact Info Indicator
                  if (hasContactInfo)
                    Chip(
                      label: const Text('Contact Available'),
                      backgroundColor: Colors.green[100],
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                      avatar: const Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.green,
                      ),
                    )
                  else
                    Chip(
                      label: const Text('No Contact Info'),
                      backgroundColor: Colors.grey[200],
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                      avatar: const Icon(
                        Icons.phone_disabled,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  // Location Indicator
                  if (hasLocation)
                    Chip(
                      label: const Text('Has Location'),
                      backgroundColor: Colors.blue[100],
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                      avatar: const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.blue,
                      ),
                    )
                  else
                    Chip(
                      label: const Text('No Location'),
                      backgroundColor: Colors.grey[200],
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                      avatar: const Icon(
                        Icons.location_off,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadDoctorsForFacility(facility),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Details & Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Facility details widget (after selection)
  Widget _buildFacilityDetails() {
    if (_selectedFacility == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToFacilitySelection,
              ),
              Text(
                'Back to Facilities',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Facility information card
          _buildFacilityInfoCard(),
          const SizedBox(height: 24),
          // Doctors section
          _buildDoctorsSection(),
          // Selected doctor details
          if (_selectedDoctor != null) ...[
            const SizedBox(height: 24),
            _buildDoctorDetailsCard(),
          ],
          // Booking section
          if (_selectedDoctor != null) ...[
            const SizedBox(height: 24),
            _buildBookingSection(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Facility information card widget
  Widget _buildFacilityInfoCard() {
    final facility = _selectedFacility!;
    // Make sure latitude and longitude are non-null and valid numbers
    final hasLocation =
        facility.latitude != null &&
        facility.longitude != null &&
        facility.latitude! != 0 &&
        facility.longitude! != 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(
                    51,
                  ), // approximately 0.2 opacity
                  radius: 30,
                  child: Icon(
                    _getFacilityIcon(facility.facilityType),
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        facility.facilityType,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${facility.code}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Location information
            ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.primary),
              title: const Text('Location'),
              subtitle: Text(
                '${facility.county}, ${facility.subCounty}, ${facility.ward}',
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (facility.description != null) ...[
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                title: const Text('Description'),
                subtitle: Text(facility.description!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (facility.phone != null) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: AppColors.primary),
                title: const Text('Phone'),
                subtitle: Text(facility.phone!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  final phoneUri = Uri(scheme: 'tel', path: facility.phone!);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  } else {
                    if (mounted) {
                      toast.AppToast.showError(
                        context,
                        'Could not launch phone call',
                      );
                    }
                  }
                },
              ),
            ],
            if (facility.email != null) ...[
              ListTile(
                leading: const Icon(Icons.email, color: AppColors.primary),
                title: const Text('Email'),
                subtitle: Text(facility.email!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  final emailUri = Uri(
                    scheme: 'mailto',
                    path: facility.email!,
                    queryParameters: {
                      'subject':
                          'Inquiry about appointment at ${facility.name}',
                    },
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    if (mounted) {
                      toast.AppToast.showError(
                        context,
                        'Could not launch email app',
                      );
                    }
                  }
                },
              ),
            ],
            if (facility.website != null) ...[
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: const Text('Website'),
                subtitle: Text(facility.website!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  // Ensure URL has proper scheme
                  String url = facility.website!;
                  if (!url.startsWith('http://') &&
                      !url.startsWith('https://')) {
                    url = 'https://$url'; // Default to https
                  }

                  final websiteUri = Uri.parse(url);
                  if (await canLaunchUrl(websiteUri)) {
                    await launchUrl(
                      websiteUri,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (mounted) {
                      toast.AppToast.showError(
                        context,
                        'Could not open website',
                      );
                    }
                  }
                },
              ),
            ],
            if (facility.services.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Services',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: facility.services.map((service) {
                  return Chip(
                    label: Text(service),
                    backgroundColor: AppColors.primary.withAlpha(
                      26,
                    ), // approximately 0.1 opacity
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Map section
            const Text(
              'Location on Map',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (hasLocation) ...[
              FacilityMapWidget(
                latitude: facility.latitude!,
                longitude: facility.longitude!,
                facilityName: facility.name,
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Location information not available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This facility does not have map coordinates in our database.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Doctors section widget
  Widget _buildDoctorsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_doctors.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No doctors available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              const Text(
                'This facility has no doctors registered in our system. Please contact the facility directly for appointment information.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Doctors',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...List.generate(_doctors.length, (index) {
          final doctor = _doctors[index];
          final isSelected = _selectedDoctor?.id == doctor.id;
          return _buildDoctorCard(doctor, isSelected);
        }),
      ],
    );
  }

  // Individual doctor card widget
  Widget _buildDoctorCard(Doctor doctor, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectDoctor(doctor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: doctor.imageUrl != null
                    ? NetworkImage(doctor.imageUrl!)
                    : null,
                backgroundColor: AppColors.primary.withAlpha(
                  51,
                ), // approximately 0.2 opacity
                child: doctor.imageUrl == null
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctor.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (doctor.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty ?? 'General Medicine',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.qualification ?? 'Medical Professional',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    if (doctor.availableDays.isNotEmpty) ...[
                      const Text(
                        'Available Days:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: doctor.availableDays.map((day) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _selectDoctor(doctor),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: Text(
                            isSelected ? 'Selected' : 'Select',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Doctor details card widget
  Widget _buildDoctorDetailsCard() {
    final doctor = _selectedDoctor!;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: doctor.imageUrl != null
                      ? NetworkImage(doctor.imageUrl!)
                      : null,
                  backgroundColor: AppColors.primary.withAlpha(
                    51,
                  ), // approximately 0.2 opacity
                  child: doctor.imageUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialty ?? 'General Medicine',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.qualification ?? 'Medical Professional',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reg No: ${doctor.registrationNumber}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'About',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              doctor.description ?? 'No description available',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.email, color: AppColors.primary),
              title: const Text('Email'),
              subtitle: Text(doctor.email ?? 'No email available'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: () {
                // Email action
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primary),
              title: const Text('Phone'),
              subtitle: Text(doctor.phone ?? 'No phone available'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: () {
                // Phone action
              },
            ),
            const SizedBox(height: 16),
            if (doctor.availableDays.isNotEmpty) ...[
              const Text(
                'Available Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doctor.availableDays.map((day) {
                  return Chip(
                    label: Text(day),
                    backgroundColor: AppColors.primary.withAlpha(
                      26,
                    ), // approximately 0.1 opacity
                    labelStyle: const TextStyle(fontSize: 14),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Booking section widget
  Widget _buildBookingSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Appointment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Date selector
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showDatePicker,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          red: 0,
                          green: 0,
                          blue: 0,
                          alpha: 0.05,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  red: AppColors.primary.red / 255,
                                  green: AppColors.primary.green / 255,
                                  blue: AppColors.primary.blue / 255,
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Appointment Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDate == null
                                        ? 'Select a date'
                                        : DateFormat(
                                            'EEEE, MMMM d, yyyy',
                                          ).format(_selectedDate!),
                                    style: TextStyle(
                                      color: _selectedDate == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time selector
            InkWell(
              onTap: _showTimePicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appointment Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTime == null
                                ? 'Select a time'
                                : _selectedTime!.format(context),
                            style: TextStyle(
                              color: _selectedTime == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking || !_isOnline ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: _isOnline
                      ? Colors.grey[300]
                      : Colors.red[100],
                ),
                child: _isBooking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Booking...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isOnline)
                            const Icon(
                              Icons.wifi_off,
                              size: 18,
                              color: Colors.white,
                            ),
                          if (!_isOnline) const SizedBox(width: 8),
                          Text(
                            !_isOnline
                                ? 'Offline (Cannot Book)'
                                : 'Book Appointment',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            if (!_isOnline) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You need an internet connection to book appointments. Your data will be saved once you\'re back online.',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Get appropriate icon for facility type
  IconData _getFacilityIcon(String facilityType) {
    if (facilityType.toLowerCase().contains('hospital')) {
      return Icons.local_hospital;
    } else if (facilityType.toLowerCase().contains('clinic')) {
      return Icons.medical_services;
    } else if (facilityType.toLowerCase().contains('center')) {
      return Icons.health_and_safety;
    } else {
      return Icons.business;
    }
  }
}
