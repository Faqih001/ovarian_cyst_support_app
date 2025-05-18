import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          _showAddEntryDialog();
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
            child:
                _symptomsIntensity.isEmpty
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
                        String symptom = _symptomsIntensity.keys.elementAt(
                          index,
                        );
                        int intensity = _symptomsIntensity[symptom] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  symptom,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Intensity: '),
                                    ...List.generate(5, (i) {
                                      return Icon(
                                        Icons.circle,
                                        size: 12,
                                        color:
                                            i < intensity
                                                ? AppColors.primary
                                                : AppColors.secondary.withAlpha(
                                                  (255 * 0.3).toInt(),
                                                ),
                                      );
                                    }),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No medications logged',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your medications',
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Calendar View Coming Soon',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your symptoms and medications over time',
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog() {
    String? selectedSymptom;
    int intensity = 3;

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
                      items:
                          _symptoms.map((String value) {
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
                  onPressed:
                      selectedSymptom == null
                          ? null
                          : () {
                            setState(() {
                              _symptomsIntensity[selectedSymptom!] = intensity;
                            });
                            Navigator.of(context).pop();
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
