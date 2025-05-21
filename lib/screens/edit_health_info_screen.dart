import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/services/user_profile_service.dart';

class EditHealthInfoScreen extends StatefulWidget {
  const EditHealthInfoScreen({super.key});

  @override
  State<EditHealthInfoScreen> createState() => _EditHealthInfoScreenState();
}

class _EditHealthInfoScreenState extends State<EditHealthInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diagnosisDateController =
      TextEditingController();
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _cystTypeController = TextEditingController();
  final TextEditingController _cystSizeController = TextEditingController();

  List<String> _medications = [];
  List<String> _allergies = [];

  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final userProfileService = Provider.of<UserProfileService>(
      context,
      listen: false,
    );
    final userProfile = userProfileService.userProfile;

    if (userProfile != null && userProfile.healthInfo != null) {
      final healthInfo = userProfile.healthInfo!;

      if (healthInfo['diagnosisDate'] != null) {
        _diagnosisDateController.text = healthInfo['diagnosisDate'];
        try {
          _selectedDate = DateFormat(
            'yyyy-MM-dd',
          ).parse(healthInfo['diagnosisDate']);
        } catch (e) {
          // Handle date parsing error
        }
      }

      _doctorController.text = healthInfo['doctorName'] ?? '';
      _hospitalController.text = healthInfo['hospitalName'] ?? '';
      _cystTypeController.text = healthInfo['cystType'] ?? '';
      _cystSizeController.text = healthInfo['cystSize'] ?? '';

      if (healthInfo['medications'] != null) {
        _medications = List<String>.from(healthInfo['medications']);
      }

      if (healthInfo['allergies'] != null) {
        _allergies = List<String>.from(healthInfo['allergies']);
      }
    }
  }

  @override
  void dispose() {
    _diagnosisDateController.dispose();
    _doctorController.dispose();
    _hospitalController.dispose();
    _cystTypeController.dispose();
    _cystSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _diagnosisDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addItem(List<String> list, String item) {
    if (item.isNotEmpty) {
      setState(() {
        list.add(item);
      });
    }
  }

  void _removeItem(List<String> list, int index) {
    setState(() {
      list.removeAt(index);
    });
  }

  Widget _buildChipsList(
    List<String> items,
    String label,
    Function(int) onDelete,
    Function(String) onAdd,
  ) {
    final TextEditingController controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ...items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                deleteIcon: const Icon(Icons.cancel, size: 16),
                onDeleted: () => onDelete(entry.key),
              );
            }),

            // Add button
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Add $label'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(hintText: 'Enter $label'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              onAdd(controller.text.trim());
                              controller.clear();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateHealthInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProfileService = Provider.of<UserProfileService>(
        context,
        listen: false,
      );

      final success = await userProfileService.updateHealthInfo(
        diagnosisDate: _diagnosisDateController.text,
        doctorName:
            _doctorController.text.isNotEmpty ? _doctorController.text : null,
        hospitalName:
            _hospitalController.text.isNotEmpty
                ? _hospitalController.text
                : null,
        cystType:
            _cystTypeController.text.isNotEmpty
                ? _cystTypeController.text
                : null,
        cystSize:
            _cystSizeController.text.isNotEmpty
                ? _cystSizeController.text
                : null,
        medications: _medications.isNotEmpty ? _medications : null,
        allergies: _allergies.isNotEmpty ? _allergies : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health information updated successfully'),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                userProfileService.errorMessage ??
                    'Failed to update health information',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Health Information'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diagnosis Date
              TextFormField(
                controller: _diagnosisDateController,
                decoration: InputDecoration(
                  labelText: 'Diagnosis Date *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter diagnosis date';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Doctor Name
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: 'Doctor Name',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Hospital Name
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Hospital/Clinic Name',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Cyst Type
              TextFormField(
                controller: _cystTypeController,
                decoration: const InputDecoration(
                  labelText: 'Cyst Type',
                  prefixIcon: Icon(Icons.biotech_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Cyst Size
              TextFormField(
                controller: _cystSizeController,
                decoration: const InputDecoration(
                  labelText: 'Cyst Size (cm)',
                  prefixIcon: Icon(Icons.straighten_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              // Medications
              _buildChipsList(
                _medications,
                'Medications',
                (index) => _removeItem(_medications, index),
                (item) => _addItem(_medications, item),
              ),

              const SizedBox(height: 24),

              // Allergies
              _buildChipsList(
                _allergies,
                'Allergies',
                (index) => _removeItem(_allergies, index),
                (item) => _addItem(_allergies, item),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateHealthInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
