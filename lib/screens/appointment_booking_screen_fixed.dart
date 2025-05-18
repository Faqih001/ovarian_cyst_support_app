import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/services/provider_service.dart';
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
    _checkConnectivity();
    _loadInitialData();

    // Set initial date if provided
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get available time slots for the selected date
      final timeSlots = await _providerService.getAvailableTimeSlots(
        widget.provider['id'],
        _selectedDate,
      );

      // Get available services
      final services = await _providerService.getProviderServices(
        widget.provider['id'],
      );

      setState(() {
        _availableTimeSlots = timeSlots;
        if (timeSlots.isNotEmpty) {
          _selectedTimeSlot = timeSlots[0];
        }
        _availableServices = services;
        _consultationFee =
            double.tryParse(
              widget.provider['consultationFee']?.toString() ?? '50',
            ) ??
            50;
        _updateTotalCost();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load time slots and services';
      });
    }
  }

  void _updateTotalCost() {
    double serviceTotal = 0;
    for (var serviceId in _selectedServices) {
      final service = _availableServices.firstWhere(
        (s) => s['id'] == serviceId,
        orElse: () => {'cost': 0},
      );
      serviceTotal += double.tryParse(service['cost'].toString()) ?? 0;
    }

    setState(() {
      _servicesFee = serviceTotal;
      _totalCost = _consultationFee + _servicesFee;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _isLoading = true;
        _selectedDate = pickedDate;
      });

      try {
        final timeSlots = await _providerService.getAvailableTimeSlots(
          widget.provider['id'],
          _selectedDate,
        );

        setState(() {
          _availableTimeSlots = timeSlots;
          if (timeSlots.isNotEmpty) {
            _selectedTimeSlot = timeSlots[0];
          } else {
            _selectedTimeSlot = '';
          }
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load time slots for the selected date';
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimeSlot.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a time slot';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Prepare appointment data
      final appointmentDateTime = _createAppointmentDateTime();

      // Create the appointment object
      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        doctorName: widget.provider['name'],
        providerName: widget.provider['name'],
        specialization: widget.provider['specialty'] ?? 'General',
        purpose: _purposeController.text,
        dateTime: appointmentDateTime,
        location: widget.provider['facility'] ?? 'Medical Center',
        notes: _notesController.text,
        reminderEnabled: _reminderEnabled,
      );

      // Book the appointment
      final bookedAppointment = await _providerService.bookAppointment(
        appointment,
      );

      // Schedule a reminder
      if (_reminderEnabled) {
        // Use the method that takes an Appointment object directly
        await NotificationService.scheduleAppointmentReminder(
          bookedAppointment,
        );
      }

      // Show success dialog
      _showBookingSuccessDialog(bookedAppointment.id);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to book appointment: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _createAppointmentDateTime() {
    // Parse the selected date and time to create a proper DateTime object
    try {
      final List<int> timeComponents =
          _selectedTimeSlot
              .split(':')
              .map((part) => int.parse(part.trim()))
              .toList();

      int hour = timeComponents[0];
      int minute = timeComponents.length > 1 ? timeComponents[1] : 0;

      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );
    } catch (e) {
      // If parsing fails, use noon as the default time
      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        12,
        0,
      );
    }
  }

  void _showBookingSuccessDialog(String appointmentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Appointment Booked!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Your appointment with ${widget.provider['name']} has been successfully booked.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: $_selectedTimeSlot',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_reminderEnabled)
                  const Text(
                    'We\'ll send you a reminder before your appointment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(
                    context,
                  ).pop(true); // Go back to previous screen with result
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildAppointmentForm(),
    );
  }

  Widget _buildAppointmentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderCard(),
            const SizedBox(height: 24),
            _buildDateSelection(),
            const SizedBox(height: 24),
            _buildTimeSlotSelection(),
            const SizedBox(height: 24),
            _buildServiceSelection(),
            const SizedBox(height: 24),
            _buildAppointmentDetails(),
            const SizedBox(height: 24),
            _buildCostSummary(),
            const SizedBox(height: 32),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isOffline ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: Text(
                  _isOffline ? 'Offline - Cannot Book' : 'Book Appointment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                widget.provider['photo'] ?? 'https://via.placeholder.com/60',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.provider['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.provider['specialty'] ?? 'Medical Professional',
                    style: TextStyle(color: Colors.grey[600]),
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
                          widget.provider['facility'] ?? 'Medical Center',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_availableTimeSlots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'No available time slots for this date',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableTimeSlots.map((timeSlot) {
                  final isSelected = _selectedTimeSlot == timeSlot;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = timeSlot;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        timeSlot,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Services (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...List.generate(_availableServices.length, (index) {
          final service = _availableServices[index];
          final isSelected = _selectedServices.contains(service['id']);
          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedServices.add(service['id']);
                } else {
                  _selectedServices.remove(service['id']);
                }
                _updateTotalCost();
              });
            },
            title: Text(service['name']),
            subtitle: Text('\$${service['cost']}'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildAppointmentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _purposeController,
          decoration: const InputDecoration(
            labelText: 'Purpose of Visit',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the purpose of your visit';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes (Optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _reminderEnabled,
          onChanged: (value) {
            setState(() {
              _reminderEnabled = value;
            });
          },
          title: const Text('Enable Appointment Reminder'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildCostSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Consultation Fee'),
                Text('\$${_consultationFee.toStringAsFixed(2)}'),
              ],
            ),
            if (_servicesFee > 0) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Additional Services'),
                  Text('\$${_servicesFee.toStringAsFixed(2)}'),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Payment will be collected at the time of your appointment',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
