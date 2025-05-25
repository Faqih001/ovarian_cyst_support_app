import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/services/provider_service.dart';
import 'package:ovarian_cyst_support_app/screens/appointment_booking_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class ProviderSearchScreen extends StatefulWidget {
  const ProviderSearchScreen({super.key});

  @override
  State<ProviderSearchScreen> createState() => _ProviderSearchScreenState();
}

class _ProviderSearchScreenState extends State<ProviderSearchScreen> {
  final ProviderService _providerService = ProviderService();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isOffline = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _providers = [];

  // Filter state
  String _selectedSpecialty = 'All Specialties';
  String _selectedLocation = 'All Locations';
  double _maxDistance = 50.0; // kilometers

  final List<String> _specialties = [
    'All Specialties',
    'Gynecology',
    'Obstetrics',
    'Fertility',
    'Oncology',
  ];
  final List<String> _locations = [
    'All Locations',
    'Nairobi',
    'Mombasa',
    'Kisumu',
    'Nakuru',
    'Eldoret',
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadProviders();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    setState(() {
      // Check if we're offline - when the list is empty or contains only ConnectivityResult.none
      _isOffline = connectivityResults.isEmpty ||
          (connectivityResults.contains(ConnectivityResult.none) &&
              connectivityResults.length == 1);
    });

    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });

      if (!_isOffline) {
        // Refresh data when back online
        _loadProviders();
      }
    });
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final providers = await _providerService.getProviders(
        specialty:
            _selectedSpecialty != 'All Specialties' ? _selectedSpecialty : null,
        location:
            _selectedLocation != 'All Locations' ? _selectedLocation : null,
      );

      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading providers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _loadProviders();
  }

  void _searchProviders(String query) {
    // This would trigger a search API call in a real implementation
    // For now, just filter the existing list
    if (query.trim().isEmpty) {
      _loadProviders();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _providers = _providers.where((provider) {
            final name = provider['name'].toString().toLowerCase();
            final specialty = provider['specialty'].toString().toLowerCase();
            final location = provider['location'].toString().toLowerCase();
            final searchLower = query.toLowerCase();

            return name.contains(searchLower) ||
                specialty.contains(searchLower) ||
                location.contains(searchLower);
          }).toList();

          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Healthcare Providers'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (_isOffline)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 20, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'re offline. Showing cached providers.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, specialty, or location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProviders('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _searchProviders(value);
              },
            ),
          ),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Gynecology'),
                _buildFilterChip('Obstetrics'),
                _buildFilterChip('Fertility'),
                _buildFilterChip('Oncology'),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProviders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _providers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No providers found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or search terms',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProviders,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _providers.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                final provider = _providers[index];
                                return _buildProviderCard(provider);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = label == 'All'
        ? _selectedSpecialty == 'All Specialties'
        : _selectedSpecialty == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSpecialty = selected ? label : 'All Specialties';
            if (label == 'All') {
              _selectedSpecialty = 'All Specialties';
            }
          });
          _applyFilters();
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Theme.of(
          context,
        ).primaryColor.withAlpha((0.2 * 255).round()),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final availableDates = provider['availableDates'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider header
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withAlpha((0.2 * 255).round()),
              child: Text(
                provider['name'].substring(0, 1),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(
              provider['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  provider['specialty'] ?? 'General Practitioner',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingBar.builder(
                      initialRating: provider['rating'] ?? 0.0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 16,
                      ignoreGestures: true,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {},
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${provider['reviewCount'] ?? 0})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                provider['isFavorite'] == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                color:
                    provider['isFavorite'] == true ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                // Toggle favorite
                setState(() {
                  provider['isFavorite'] = !(provider['isFavorite'] == true);
                });

                // This would save to database in a real app
                _showMessage(
                  provider['isFavorite'] == true
                      ? 'Added to favorites'
                      : 'Removed from favorites',
                );
              },
            ),
          ),

          // Provider details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    provider['location'] ?? 'Unknown location',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'KES ${provider['consultationFee'] ?? 0}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          // Available dates
          if (availableDates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Dates',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableDates.length,
                      itemBuilder: (context, index) {
                        final date = DateTime.parse(availableDates[index]);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              _navigateToBooking(provider, date);
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            child: Text(
                              DateFormat('MMM d').format(date),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // View provider details
                      _showProviderDetails(provider);
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _navigateToBooking(provider, null);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Book'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Filter Providers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Specialty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: _specialties.map((specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSpecialty = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: _locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Maximum Distance: 50 km',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: '${_maxDistance.round()} km',
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedSpecialty = 'All Specialties';
                              _selectedLocation = 'All Locations';
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
                            _applyFilters();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToBooking(
    Map<String, dynamic> provider,
    DateTime? selectedDate,
  ) {
    // This would navigate to the appointment booking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentBookingScreen(
          provider: provider,
          initialDate: selectedDate,
        ),
      ),
    );
  }

  void _showProviderDetails(Map<String, dynamic> provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha((0.2 * 255).round()),
                          child: Text(
                            provider['name'].substring(0, 1),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider['specialty'] ?? 'General Practitioner',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rating and reviews
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: provider['rating'] ?? 0.0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 20,
                          ignoreGestures: true,
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {},
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${provider['rating']?.toStringAsFixed(1) ?? '0.0'} (${provider['reviewCount'] ?? 0} reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact and location info
                    _buildInfoRow(
                      Icons.location_on,
                      provider['location'] ?? 'Unknown location',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.phone,
                      provider['phone'] ?? 'No phone number',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.email, provider['email'] ?? 'No email'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.attach_money,
                      'Consultation Fee: KES ${provider['consultationFee'] ?? 0}',
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider['bio'] ?? 'No information available.',
                      style: TextStyle(color: Colors.grey[800], height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // Education
                    const Text(
                      'Education & Experience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildEducationList(provider['education']),
                    const SizedBox(height: 16),

                    // Services
                    const Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildServicesList(provider['services']),
                    const SizedBox(height: 24),

                    // Book button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToBooking(provider, null);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[800]))),
      ],
    );
  }

  List<Widget> _buildEducationList(List<dynamic>? education) {
    if (education == null || education.isEmpty) {
      return [
        Text(
          'No education information available.',
          style: TextStyle(color: Colors.grey[800]),
        ),
      ];
    }

    return education.map<Widget>((edu) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.school, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edu['degree'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    edu['institution'] ?? '',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  if (edu['year'] != null)
                    Text(
                      edu['year'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildServicesList(List<dynamic>? services) {
    if (services == null || services.isEmpty) {
      return [
        Text(
          'No services information available.',
          style: TextStyle(color: Colors.grey[800]),
        ),
      ];
    }

    return services.map<Widget>((service) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(service, style: TextStyle(color: Colors.grey[800])),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
