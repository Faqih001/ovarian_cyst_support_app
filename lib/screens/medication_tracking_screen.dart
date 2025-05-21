import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';

class MedicationTrackingScreen extends StatefulWidget {
  const MedicationTrackingScreen({super.key});

  @override
  State<MedicationTrackingScreen> createState() =>
      _MedicationTrackingScreenState();
}

class _MedicationTrackingScreenState extends State<MedicationTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseService _databaseService;
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  // Form controllers for adding medication
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _frequency = 'Daily';
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _reminderEnabled = true;
  final _notesController = TextEditingController();

  final List<String> _frequencyOptions = [
    'Daily',
    'Twice Daily',
    'Every Other Day',
    'Weekly',
    'As Needed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _loadMedications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load medications from database
      final medications = await _databaseService.getMedications();

      setState(() {
        _medications = medications;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medications: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medication = {
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'frequency': _frequency,
        'timeHour': _selectedTime.hour,
        'timeMinute': _selectedTime.minute,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'reminderEnabled': _reminderEnabled ? 1 : 0,
        'notes': _notesController.text,
        'isUploaded': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add unique ID
      medication['id'] = DateTime.now().millisecondsSinceEpoch.toString();

      await _databaseService.saveMedication(medication);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication saved successfully')),
        );

        // Clear form
        _nameController.clear();
        _dosageController.clear();
        _frequency = 'Daily';
        _selectedTime = TimeOfDay.now();
        _startDate = DateTime.now();
        _endDate = null;
        _reminderEnabled = true;
        _notesController.clear();

        // Reload medications and switch to list tab
        await _loadMedications();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving medication: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle medication deletion
  Future<void> _handleMedicationDeletion(
      Map<String, dynamic> medication) async {
    if (!mounted) return;

    // Store scaffold messenger before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete medication
      await _databaseService.deleteMedication(medication['id']);

      // Reload medications
      await _loadMedications();

      // Show success message if still mounted
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Handle errors if still mounted
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(
      Map<String, dynamic> medication) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text(
          'Are you sure you want to delete this medication?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _handleMedicationDeletion(medication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Tracking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Add Medication'),
            Tab(text: 'My Medications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAddMedicationTab(), _buildMedicationListTab()],
      ),
    );
  }

  Widget _buildAddMedicationTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication name
                  const Text(
                    'Medication Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter medication name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a medication name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Dosage
                  const Text(
                    'Dosage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., 500mg, 1 tablet, 2 pills',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the dosage';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Frequency
                  const Text(
                    'Frequency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _frequencyOptions.map((freq) {
                      return ChoiceChip(
                        label: Text(freq),
                        selected: _frequency == freq,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _frequency = freq;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Time
                  const Text(
                    'Time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.access_time),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );

                      if (pickedTime != null) {
                        setState(() {
                          _selectedTime = pickedTime;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Start date
                  const Text(
                    'Start Date',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      DateFormat('MMM dd, yyyy').format(_startDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          _startDate = pickedDate;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // End date (optional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'End Date (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_endDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _endDate = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'No end date',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _endDate ??
                            _startDate.add(const Duration(days: 30)),
                        firstDate: _startDate,
                        lastDate: DateTime(2101),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          _endDate = pickedDate;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Enable reminders
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable Reminders',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _reminderEnabled = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Notes
                  const Text(
                    'Notes (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add any notes about this medication...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveMedication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Medication'),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildMedicationListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No medications added yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your medications to receive reminders',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Medication'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _medications.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final medication = _medications[index];
        final name = medication['name'] as String;
        final dosage = medication['dosage'] as String;
        final frequency = medication['frequency'] as String;
        final startDate = DateTime.parse(medication['startDate'] as String);
        final endDate = medication['endDate'] != null
            ? DateTime.parse(medication['endDate'] as String)
            : null;
        final time = TimeOfDay(
          hour: medication['timeHour'] as int,
          minute: medication['timeMinute'] as int,
        );
        final reminderEnabled = medication['reminderEnabled'] == 1;
        final isActive = endDate == null || endDate.isAfter(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withAlpha(
                                          (0.1 * 255).toInt(),
                                        )
                                      : Colors.grey.withAlpha(
                                          (0.1 * 255).toInt(),
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Completed',
                                  style: TextStyle(
                                    color:
                                        isActive ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(dosage, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today,
                      'Start Date',
                      DateFormat('MMM dd, yyyy').format(startDate),
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      Icons.access_time,
                      'Time',
                      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(Icons.repeat, 'Frequency', frequency),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      Icons.notifications,
                      'Reminders',
                      reminderEnabled ? 'Enabled' : 'Disabled',
                    ),
                  ],
                ),
                if (endDate != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    Icons.event_busy,
                    'End Date',
                    DateFormat('MMM dd, yyyy').format(endDate),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Edit medication functionality will be implemented later
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () =>
                          _showDeleteConfirmationDialog(medication),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
