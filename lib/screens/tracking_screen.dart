import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:ovarian_cyst_support_app/screens/medication_tracking_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSymptom;

  const TrackingScreen({
    super.key,
    this.initialSymptom,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final DatabaseService _databaseService;
  bool _isLoading = false;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _events = {};

  final List<String> _symptoms = [
    'Abdominal Pain',
    'Bloating',
    'Back Pain',
    'Fatigue',
    'Nausea',
    'Painful Periods',
    'Painful Intercourse',
    'Difficulty Emptying Bladder',
    'Urinary Frequency',
  ];

  final Map<String, int> _symptomsIntensity = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    setState(() => _isLoading = true);
    try {
      // Load today's symptoms
      final symptoms = await _databaseService.getTodaysSymptoms();

      // Update symptoms intensity map
      setState(() {
        _symptomsIntensity.clear();
        for (var symptom in symptoms) {
          _symptomsIntensity[symptom['name']] = symptom['intensity'];
        }
      });

      // Load all symptoms and medications for calendar
      final allSymptoms = await _databaseService.getAllSymptomEntries();
      final medications = await _databaseService.getAllMedications();

      // Create a new events map
      final newEvents = <DateTime, List<dynamic>>{};

      // Group symptoms by date
      for (var symptom in allSymptoms) {
        if (symptom['date'] == null) continue;

        // Parse the date
        final DateTime date = symptom['date'] is DateTime
            ? symptom['date']
            : DateTime.parse(symptom['date'].toString());

        final dateKey = DateTime(
          date.year,
          date.month,
          date.day,
        );

        if (!newEvents.containsKey(dateKey)) {
          newEvents[dateKey] = [];
        }

        List<String> symptomsList = [];
        if (symptom['symptoms'] is List) {
          symptomsList =
              (symptom['symptoms'] as List).map((e) => e.toString()).toList();
        } else if (symptom['symptoms'] is String) {
          symptomsList = [symptom['symptoms']];
        }

        newEvents[dateKey]!.add({
          'type': 'symptom',
          'name': symptomsList.join(', '),
          'intensity': symptom['painLevel'] ?? 0,
        });
      }

      // Add medications to events
      for (var med in medications) {
        final startDate = DateTime.parse(med['startDate']);
        final endDate = med['endDate'] != null
            ? DateTime.parse(med['endDate'])
            : DateTime.now();

        for (var date = startDate;
            date.isBefore(endDate.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          final eventDate = DateTime(date.year, date.month, date.day);
          if (!newEvents.containsKey(eventDate)) {
            newEvents[eventDate] = [];
          }
          newEvents[eventDate]!.add({
            'type': 'medication',
            'name': med['name'],
            'dosage': med['dosage'],
          });
        }
      }

      // Update events state
      if (mounted) {
        setState(() {
          _events = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildEventsForSelectedDay() {
    final selectedEvents = _events[_selectedDay];

    if (selectedEvents == null || selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: AppColors.textLight.withAlpha(128), // 0.5 * 255
            ),
            const SizedBox(height: 16),
            Text(
              'No events for ${DateFormat('MMMM d, y').format(_selectedDay)}',
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    final symptoms =
        selectedEvents.where((e) => (e as Map)['type'] == 'symptom').toList();
    final medications = selectedEvents
        .where((e) => (e as Map)['type'] == 'medication')
        .toList();

    return ListView(
      children: [
        if (symptoms.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Symptoms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...symptoms.map((event) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26), // 0.1 * 255
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.healing,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(event['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                            5,
                            (index) => Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: index < (event['intensity'] as int)
                                      ? AppColors.primary
                                      : AppColors.secondary
                                          .withAlpha(77), // 0.3 * 255
                                )),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        if (medications.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Medications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicationTrackingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Schedule'),
                ),
              ],
            ),
          ),
          ...medications.map((event) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(26), // 0.1 * 255
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text(event['name']),
                  subtitle: Text('Dosage: ${event['dosage']}'),
                ),
              )),
        ],
      ],
    );
  }

  Future<void> _saveSymptom(String symptom, int intensity) async {
    try {
      await _databaseService.logSymptom({
        'name': symptom,
        'intensity': intensity,
        'timestamp': DateTime.now(),
      });

      // Refresh all data
      await _loadSymptoms();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Symptom logged successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving symptom: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Health Tracking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha((255 * 0.7).toInt()),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Symptoms'),
            Tab(text: 'Medication'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSymptomsTab(),
          _buildMedicationTab(),
          _buildCalendarTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEntryDialog();
          } else if (_tabController.index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MedicationTrackingScreen(),
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSymptomsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Symptom Tracker', style: AppStyles.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Track your symptoms to monitor patterns and share with your healthcare provider.',
            style: AppStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          const Text(
            'Today\'s Symptoms',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _symptomsIntensity.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.healing_outlined,
                              size: 80,
                              color: AppColors.textLight.withAlpha(
                                (255 * 0.5).toInt(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No symptoms logged today',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to log your symptoms',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _symptomsIntensity.length,
                        itemBuilder: (context, index) {
                          final symptom =
                              _symptomsIntensity.keys.elementAt(index);
                          final intensity = _symptomsIntensity[symptom] ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        symptom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _showAddEntryDialog(symptom),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ...List.generate(
                                          5,
                                          (i) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4),
                                                child: Icon(
                                                  Icons.circle,
                                                  size: 12,
                                                  color: i < intensity
                                                      ? AppColors.primary
                                                      : AppColors.secondary
                                                          .withAlpha(
                                                          (255 * 0.3).toInt(),
                                                        ),
                                                ),
                                              )),
                                      const Spacer(),
                                      Text(
                                        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medication Schedule', style: AppStyles.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Keep track of your medications and adherence to prescribed schedules.',
            style: AppStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder(
              future: _databaseService.getAllMedications(),
              builder: (context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final medications = snapshot.data ?? [];

                if (medications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 80,
                          color: AppColors.textLight
                              .withAlpha((0.5 * 255).toInt()),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No medications added',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your medications',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final medication = medications[index];
                    final startDate = DateTime.parse(medication['startDate']);
                    final endDate = medication['endDate'] != null
                        ? DateTime.parse(medication['endDate'])
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.medication,
                            color: AppColors.secondary,
                          ),
                        ),
                        title: Text(medication['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dosage: ${medication['dosage']}'),
                            Text(
                              'Started: ${DateFormat('MMM d, y').format(startDate)}${endDate != null ? '\nEnds: ${DateFormat('MMM d, y').format(endDate)}' : ''}',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MedicationTrackingScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) => _events[day] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                final hasSymptoms =
                    events.any((e) => (e as Map)['type'] == 'symptom');
                final hasMedications =
                    events.any((e) => (e as Map)['type'] == 'medication');

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasSymptoms)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      if (hasMedications)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(128), // 0.5 * 255
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildEventsForSelectedDay(),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog([String? existingSymptom]) {
    String? selectedSymptom = existingSymptom;
    int intensity =
        existingSymptom != null ? _symptomsIntensity[existingSymptom] ?? 3 : 3;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log a Symptom'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Symptom:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.secondary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Select Symptom'),
                      value: selectedSymptom,
                      items: _symptoms.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSymptom = newValue;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Intensity:'),
                  const SizedBox(height: 8),
                  Slider(
                    value: intensity.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.secondary.withAlpha(
                      (255 * 0.3).toInt(),
                    ),
                    label: intensity.toString(),
                    onChanged: (value) {
                      setState(() {
                        intensity = value.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Mild', style: TextStyle(fontSize: 12)),
                      Text('Severe', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedSymptom == null
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await _saveSymptom(selectedSymptom!, intensity);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
