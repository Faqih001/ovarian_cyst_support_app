import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovarian_cyst_support_app/services/provider_service.dart';
import 'package:ovarian_cyst_support_app/services/payment_service.dart';
import 'package:ovarian_cyst_support_app/services/notification_service.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  final DateTime? initialDate;

  const AppointmentBookingScreen({
    super.key,
    required this.provider,
    this.initialDate,
  });

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  late final FirestoreService _firestoreService;
  final ProviderService _providerService = ProviderService();
  final PaymentService _paymentService = PaymentService();
  late final String _userId;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '';
  List<String> _availableTimeSlots = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String _errorMessage = '';
  bool _reminderEnabled = true;

  // Payment details
  double _consultationFee = 0;
  double _servicesFee = 0;
  double _totalCost = 0;

  // Selected services
  List<Map<String, dynamic>> _availableServices = [];
  final List<String> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _userId = Provider.of<AuthService>(context, listen: false).user?.uid ?? '';
    _initializeScreen();
    _checkConnectivity();
  }

  Future<void> _initializeScreen() async {
    if (widget.initialDate != null) {
      setState(() => _selectedDate = widget.initialDate!);
    }
    await _loadAvailableTimeSlots();
    await _loadProviderServices();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });

      if (!_isOffline) {
        // Refresh data when back online
        _loadAvailableTimeSlots();
      }
    });
  }

  Future<void> _loadAvailableTimeSlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _availableTimeSlots = [];
      _selectedTimeSlot = '';
    });

    try {
      if (_isOffline) {
        setState(() {
          _availableTimeSlots = [
            '09:00',
            '10:00',
            '11:00',
            '14:00',
            '15:00',
            '16:00',
          ];
          _isLoading = false;
        });
        return;
      }

      final timeSlots = await _providerService.getAvailableTimeSlots(
        widget.provider['id'],
        _selectedDate,
      );

      setState(() {
        _availableTimeSlots = timeSlots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load availability. Please try again.';
        _isLoading = false;

        // Fallback timeSlots
        _availableTimeSlots = [
          '8:00 AM',
          '9:00 AM',
          '10:00 AM',
          '11:00 AM',
          '2:00 PM',
          '3:00 PM',
          '4:00 PM',
        ];
      });
    }
  }

  Future<void> _loadProviderServices() async {
    setState(() {
      _availableServices = [];
    });

    try {
      if (_isOffline) {
        setState(() {
          _availableServices = [
            {
              'name': 'Regular Checkup',
              'cost': 0.0,
              'description': 'Standard gynecological examination',
            },
            {
              'name': 'Ultrasound',
              'cost': 2000.0,
              'description': 'Pelvic ultrasound scan',
            },
            {
              'name': 'Lab Tests',
              'cost': 1500.0,
              'description': 'Basic lab work including hormonal tests',
            },
            {
              'name': 'Treatment Consultation',
              'cost': 1000.0,
              'description': 'Discussion of treatment options and plan',
            },
          ];
        });
        return;
      }

      final services = await _providerService.getProviderServices(
        widget.provider['id'],
      );

      setState(() {
        _availableServices = services;
      });
    } catch (e) {
      // Use fallback services
      setState(() {
        _availableServices = [
          {
            'name': 'Regular Checkup',
            'cost': 0.0,
            'description': 'Standard gynecological examination',
          },
          {
            'name': 'Ultrasound',
            'cost': 2000.0,
            'description': 'Pelvic ultrasound scan',
          },
          {
            'name': 'Lab Tests',
            'cost': 1500.0,
            'description': 'Basic lab work including hormonal tests',
          },
          {
            'name': 'Treatment Consultation',
            'cost': 1000.0,
            'description': 'Discussion of treatment options and plan',
          },
        ];
      });
    }
  }

  void _updateTotalCost() {
    _servicesFee = 0;
    for (var serviceName in _selectedServices) {
      final service = _availableServices.firstWhere(
        (s) => s['name'] == serviceName,
        orElse: () => {'cost': 0.0},
      );
      _servicesFee += service['cost'] ?? 0;
    }

    _totalCost = _consultationFee + _servicesFee;
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedTimeSlot.isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appointmentData = {
        'userId': _userId,
        'providerId': widget.provider['id'],
        'providerName': widget.provider['name'],
        'date': Timestamp.fromDate(_selectedDate),
        'timeSlot': _selectedTimeSlot,
        'purpose': _purposeController.text,
        'notes': _notesController.text,
        'phone': _phoneController.text,
        'services': _selectedServices,
        'status': 'pending',
        'totalCost': _totalCost,
        'reminderEnabled': _reminderEnabled,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestoreService.addAppointment(_userId, appointmentData);

      if (_reminderEnabled) {
        await NotificationService.scheduleAppointmentReminder(
          _selectedDate,
          widget.provider['name'],
          _selectedTimeSlot,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to book appointment: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment'), elevation: 0),
      body: _isLoading && _availableTimeSlots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Doctor info card
                  _buildDoctorInfoCard(),
                  const SizedBox(height: 24),

                  // Date selection
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {
                                      final previousMonth = DateTime(
                                        _selectedDate.year,
                                        _selectedDate.month - 1,
                                        _selectedDate.day,
                                      );
                                      if (previousMonth.isAfter(
                                        DateTime.now().subtract(
                                          const Duration(days: 1),
                                        ),
                                      )) {
                                        setState(() {
                                          _selectedDate = previousMonth;
                                        });
                                        _loadAvailableTimeSlots(
                                          _selectedDate,
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {
                                      final nextMonth = DateTime(
                                        _selectedDate.year,
                                        _selectedDate.month + 1,
                                        _selectedDate.day,
                                      );
                                      if (nextMonth.isBefore(
                                        DateTime.now().add(
                                          const Duration(days: 60),
                                        ),
                                      )) {
                                        setState(() {
                                          _selectedDate = nextMonth;
                                        });
                                        _loadAvailableTimeSlots(
                                          _selectedDate,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 60),
                                ),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _selectedDate = pickedDate;
                                  _selectedTimeSlot = '';
                                });
                                _loadAvailableTimeSlots(pickedDate);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat(
                                    'EEEE, MMMM d, yyyy',
                                  ).format(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time slot selection
                  Row(
                    children: [
                      const Text(
                        'Select Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoading && _availableTimeSlots.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTimeSlotGrid(),
                  const SizedBox(height: 24),

                  // Purpose
                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose of Visit *',
                      hintText: 'e.g., Regular check-up, Follow-up, etc.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter purpose of visit';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      hintText: 'Any additional information for the doctor',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),

                  // Reminder toggle
                  SwitchListTile(
                    title: const Text('Set Reminder'),
                    subtitle: const Text(
                      'Get notified 24 hours before appointment',
                    ),
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _reminderEnabled = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // Additional services
                  const Text(
                    'Additional Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildServicesSelection(),
                  const SizedBox(height: 24),

                  // Cost summary
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cost Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Consultation Fee'),
                              Text(
                                PaymentService.formatCurrency(
                                  _consultationFee,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Additional Services'),
                              Text(
                                PaymentService.formatCurrency(_servicesFee),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                PaymentService.formatCurrency(_totalCost),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Book button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDoctorInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withAlpha(51), // Replaced withOpacity(0.2)
              child: Text(
                widget.provider['name'].substring(0, 1),
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
                    'Dr. ${widget.provider['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.provider['specialty'] ?? 'General Practitioner',
                    style: TextStyle(color: Colors.grey[700]),
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
                          widget.provider['location'] ?? 'Unknown location',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
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
    );
  }

  Widget _buildTimeSlotGrid() {
    if (_availableTimeSlots.isEmpty) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              _isLoading
                  ? 'Loading available time slots...'
                  : 'No time slots available for this date.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = _availableTimeSlots[index];
        final isSelected = timeSlot == _selectedTimeSlot;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedTimeSlot = timeSlot;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                timeSlot,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicesSelection() {
    return Column(
      children: _availableServices.map((service) {
        final isSelected = _selectedServices.contains(service['name']);

        return CheckboxListTile(
          title: Text(service['name']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service['description'] ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                PaymentService.formatCurrency(service['cost'] ?? 0),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedServices.add(service['name']);
              } else {
                _selectedServices.remove(service['name']);
              }
              _updateTotalCost();
            });
          },
          activeColor: Theme.of(context).primaryColor,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}
