import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/models/facility.dart';
import 'package:ovarian_cyst_support_app/models/doctor.dart';
import 'package:ovarian_cyst_support_app/services/hospital_service.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/appointment_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ovarian_cyst_support_app/widgets/app_toast.dart' as toast;

class KenyanHospitalBookingScreen extends StatefulWidget {
  const KenyanHospitalBookingScreen({super.key});

  @override
  State<KenyanHospitalBookingScreen> createState() =>
      _KenyanHospitalBookingScreenState();
}

class _KenyanHospitalBookingScreenState
    extends State<KenyanHospitalBookingScreen> {
  final HospitalService _hospitalService = HospitalService();
  final AppointmentService _appointmentService = AppointmentService();

  final _searchController = TextEditingController();
  String? _selectedCounty;
  Facility? _selectedFacility;
  Doctor? _selectedDoctor;
  List<String> _counties = [];
  List<Facility> _facilities = [];
  List<Doctor> _doctors = [];

  bool _isLoadingCounties = false;
  bool _isLoadingFacilities = false;
  bool _isLoadingDoctors = false;
  bool _isSubmitting = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09:00 AM';

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM'
  ];

  @override
  void initState() {
    super.initState();
    _loadCounties();

    // Pre-fill name from auth service if available
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user != null) {
      authService.getUserData().then((userData) {
        if (userData != null && userData['name'] != null) {
          _nameController.text = userData['name'];
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCounties() async {
    setState(() {
      _isLoadingCounties = true;
    });

    try {
      final counties = await _hospitalService.getCounties();
      setState(() {
        _counties = counties;
        _isLoadingCounties = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCounties = false;
      });
      if (mounted) {
        toast.AppToast.showError(context, 'Failed to load counties: $e');
      }
    }
  }

  Future<void> _searchFacilities() async {
    if (_searchController.text.trim().isEmpty && _selectedCounty == null) {
      toast.AppToast.showError(
          context, 'Please enter a search term or select a county');
      return;
    }

    setState(() {
      _isLoadingFacilities = true;
      _facilities = [];
      _selectedFacility = null;
      _doctors = [];
      _selectedDoctor = null;
    });

    try {
      final facilities = await _hospitalService.getFacilities(
        searchQuery: _searchController.text.trim(),
        county: _selectedCounty,
      );

      setState(() {
        _facilities = facilities;
        _isLoadingFacilities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFacilities = false;
      });
      if (mounted) {
        toast.AppToast.showError(context, 'Failed to search facilities: $e');
      }
    }
  }

  Future<void> _loadDoctors() async {
    if (_selectedFacility == null) return;

    setState(() {
      _isLoadingDoctors = true;
      _doctors = [];
      _selectedDoctor = null;
    });

    try {
      final doctors =
          await _hospitalService.getDoctorsForFacility(_selectedFacility!.id);
      setState(() {
        _doctors = doctors;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDoctors = false;
        // Generate sample doctor data if API doesn't return doctors
        _doctors = [
          Doctor(
              id: '1',
              name: 'Dr. Sarah Njeri',
              specialty: 'Gynecology',
              qualification: 'MBBS, MS',
              phone: '0712345678'),
          Doctor(
              id: '2',
              name: 'Dr. John Kamau',
              specialty: 'Obstetrics',
              qualification: 'MD',
              phone: '0723456789'),
        ];
      });
      if (mounted) {
        toast.AppToast.showError(
            context, 'Using sample doctor data for demonstration');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) {
      toast.AppToast.showError(
          context, 'Please fill all required fields correctly');
      return;
    }

    if (_selectedFacility == null) {
      toast.AppToast.showError(context, 'Please select a hospital');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create appointment data
      final appointmentData = {
        'userId': userId,
        'facilityId': _selectedFacility!.id,
        'facilityName': _selectedFacility!.name,
        'doctorId': _selectedDoctor?.id,
        'doctorName': _selectedDoctor?.name,
        'patientName': _nameController.text,
        'phoneNumber': _phoneController.text,
        'appointmentDate': Timestamp.fromDate(_selectedDate),
        'appointmentTime': _selectedTime,
        'purpose': _purposeController.text,
        'notes': _notesController.text,
        'status': 'pending',
        'county': _selectedFacility!.county,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save appointment using the appointment service
      await _appointmentService.addAppointment(appointmentData);

      if (mounted) {
        toast.AppToast.showSuccess(context, 'Appointment booked successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        toast.AppToast.showError(context, 'Failed to book appointment: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment - Kenya Hospitals'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Search for hospital
              _buildSearchSection(),

              const SizedBox(height: 20),

              // Step 2: Facility selection
              if (_facilities.isNotEmpty) _buildFacilitySection(),

              const SizedBox(height: 20),

              // Step 3: Doctor selection
              if (_selectedFacility != null) _buildDoctorSection(),

              const SizedBox(height: 20),

              // Step 4: Appointment form
              if (_selectedFacility != null) _buildAppointmentForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Find a Hospital',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search hospitals by name',
                hintText: 'Enter hospital name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or select a county:'),
            const SizedBox(height: 8),
            _isLoadingCounties
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    hint: const Text('Select County'),
                    value: _selectedCounty,
                    items: _counties
                        .map((county) => DropdownMenuItem(
                              value: county,
                              child: Text(county),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCounty = value;
                      });
                    },
                  ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searchFacilities,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoadingFacilities
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('SEARCH'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2: Select a Hospital',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _facilities.length,
              itemBuilder: (context, index) {
                final facility = _facilities[index];
                final isSelected = _selectedFacility?.id == facility.id;

                return ListTile(
                  title: Text(
                    facility.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${facility.facilityType}'),
                      Text(
                          'Location: ${facility.county}, ${facility.subCounty}'),
                      if (facility.phone != null)
                        Text('Phone: ${facility.phone}'),
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : const Icon(Icons.circle_outlined),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedFacility = facility;
                      _doctors = [];
                      _selectedDoctor = null;
                    });
                    _loadDoctors();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 3: Select a Doctor (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isLoadingDoctors
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                    ? const Text(
                        'No specific doctors available for selection at this facility.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
                          final isSelected = _selectedDoctor?.id == doctor.id;

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              doctor.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (doctor.specialty != null)
                                  Text('Specialty: ${doctor.specialty}'),
                                if (doctor.qualification != null)
                                  Text(
                                      'Qualification: ${doctor.qualification}'),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.primary)
                                : const Icon(Icons.circle_outlined),
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedDoctor = isSelected ? null : doctor;
                              });
                            },
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 4: Book Your Appointment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 0712345678',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^\d{9,10}$')
                      .hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                    return 'Please enter a valid Kenyan phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Appointment Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Preferred Time',
                  border: OutlineInputBorder(),
                ),
                value: _selectedTime,
                items: _timeSlots
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTime = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Visit',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Consultation, Follow-up, etc.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
                  hintText: 'Any additional information for the hospital',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('BOOK APPOINTMENT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
