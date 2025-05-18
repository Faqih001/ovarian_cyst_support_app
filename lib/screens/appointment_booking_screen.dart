import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/services/provider_service.dart';
import 'package:ovarian_cyst_support_app/services/payment_service.dart';
import 'package:ovarian_cyst_support_app/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';

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
  final ProviderService _providerService = ProviderService();
  final PaymentService _paymentService = PaymentService();
  // Using static methods from NotificationService, so instance not needed

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
    _initializeData();
    _checkConnectivity();
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
        _fetchAvailabilityForDate(_selectedDate);
      }
    });
  }

  void _initializeData() {
    // Set initial date if provided
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    // Set consultation fee
    _consultationFee = widget.provider['consultationFee'] ?? 0;
    _updateTotalCost();

    // Fetch availability for selected date
    _fetchAvailabilityForDate(_selectedDate);

    // Fetch available services
    _fetchAvailableServices();
  }

  Future<void> _fetchAvailabilityForDate(DateTime date) async {
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
        date,
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

  Future<void> _fetchAvailableServices() async {
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimeSlot.isEmpty) {
      _showMessage('Please select a time slot');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create appointment with proper fields matching the model
      final appointmentDateTime = _createAppointmentDateTime();

      final appointment = Appointment(
        id: '${widget.provider['id']}_${DateTime.now().millisecondsSinceEpoch}',
        doctorName: widget.provider['name'],
        providerName: widget.provider['name'],
        specialization: widget.provider['specialty'] ?? 'General Practitioner',
        purpose: _purposeController.text,
        dateTime: appointmentDateTime,
        location: widget.provider['location'],
        notes: _notesController.text,
        reminderEnabled: _reminderEnabled,
      );

      // Book appointment
      final bookedAppointment = await _providerService.bookAppointment(
        appointment,
      );

      // Set reminder if enabled
      if (_reminderEnabled) {
        await NotificationService.scheduleAppointmentReminder(
          bookedAppointment.id,
          bookedAppointment.dateTime,
          bookedAppointment.providerName,
          bookedAppointment.purpose,
          bookedAppointment.location,
        );
      }

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      _showBookingSuccessDialog(bookedAppointment.id);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });

      _showMessage(_errorMessage);
    }
  }

  DateTime _createAppointmentDateTime() {
    // Parse the selected date and time to create a proper DateTime object
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    DateTime appointmentDateTime;

    try {
      // Try to parse the time in 24-hour format (e.g., "14:00")
      appointmentDateTime = DateTime.parse('$dateStr $_selectedTimeSlot:00');
    } catch (e) {
      try {
        // Try to parse the time in 12-hour format (e.g., "2:00 PM")
        final timeParts = _selectedTimeSlot.split(' ');
        final timeOnly = timeParts[0];
        final amPm = timeParts.length > 1 ? timeParts[1] : 'AM';

        final hourMinute = timeOnly.split(':');
        int hour = int.parse(hourMinute[0]);
        final int minute = hourMinute.length > 1 ? int.parse(hourMinute[1]) : 0;

        // Adjust hour for PM
        if (amPm.toUpperCase() == 'PM' && hour < 12) {
          hour += 12;
        } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }

        appointmentDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          hour,
          minute,
        );
      } catch (e) {
        // Fallback to noon if parsing fails
        appointmentDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          12,
          0,
        );
      }
    }

    return appointmentDateTime;
  }

  Future<void> _processPayment(String appointmentId) async {
    if (_phoneController.text.isEmpty) {
      _showMessage('Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Process payment
      final paymentResult = await _paymentService.processPayment(
        phoneNumber: _phoneController.text,
        amount: _totalCost,
        appointmentId: appointmentId,
        description: 'Appointment with Dr. ${widget.provider['name']}',
      );

      setState(() {
        _isLoading = false;
      });

      // Show payment result
      if (paymentResult['success']) {
        _showMessage(
          'Payment request sent. Please check your phone to complete.',
        );

        // Check if widget is still mounted after async operation
        if (!mounted) return;

        // Close the current dialog
        Navigator.of(context).pop();

        // Navigate back to previous screen
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        _showMessage('Payment failed: ${paymentResult['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showMessage('Payment error: ${e.toString()}');
    }
  }

  void _showBookingSuccessDialog(String appointmentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Appointment Booked'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Your appointment has been booked successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dr. ${widget.provider['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)} at $_selectedTimeSlot',
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to pay now?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${PaymentService.formatCurrency(_totalCost)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    hintText: 'e.g., 254712345678',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Pay Later'),
            ),
            ElevatedButton(
              onPressed:
                  _isLoading ? null : () => _processPayment(appointmentId),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Pay Now'),
            ),
          ],
        );
      },
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
      body:
          _isLoading && _availableTimeSlots.isEmpty
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
                                          _fetchAvailabilityForDate(
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
                                          _fetchAvailabilityForDate(
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
                                  _fetchAvailabilityForDate(pickedDate);
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
                        child:
                            _isLoading
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
              backgroundColor: Theme.of(context).primaryColor.withAlpha(51), // Replaced withOpacity(0.2)
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
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected
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
      children:
          _availableServices.map((service) {
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
