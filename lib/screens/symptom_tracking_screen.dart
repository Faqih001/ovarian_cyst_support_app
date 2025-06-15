import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/models/symptom_entry.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomTrackingScreen extends StatefulWidget {
  const SymptomTrackingScreen({super.key});

  @override
  State<SymptomTrackingScreen> createState() => _SymptomTrackingScreenState();
}

class _SymptomTrackingScreenState extends State<SymptomTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Stream<QuerySnapshot>? _entriesStream;
  bool _isLoading = true;

  // Symptom options
  final List<String> _moodOptions = [
    'Great',
    'Good',
    'Okay',
    'Not Good',
    'Terrible'
  ];

  final List<String> _symptomOptions = [
    'Pelvic Pain',
    'Bloating',
    'Nausea',
    'Fatigue',
    'Back Pain',
    'Irregular Bleeding',
    'Pressure',
    'Cramping',
    'Other'
  ];

  // For new symptom entry
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  int _painLevel = 3;
  int _bloatingLevel = 2;
  String _selectedMood = 'Good';
  final List<String> _selectedSymptoms = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initSymptomStream();
  }

  void _initSymptomStream() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    if (authService.user != null) {
      _entriesStream =
          firestoreService.getSymptomEntries(authService.user!.uid);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSymptomEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    try {
      await firestoreService.addSymptomEntry(authService.user!.uid, {
        'date': _selectedDate,
        'painLevel': _painLevel,
        'bloatingLevel': _bloatingLevel,
        'mood': _selectedMood,
        'symptoms': _selectedSymptoms,
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Symptom entry added successfully')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding symptom entry: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDate = DateTime.now();
      _painLevel = 3;
      _bloatingLevel = 2;
      _selectedMood = 'Good';
      _selectedSymptoms.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Tracking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Add Entry'),
            Tab(text: 'Log'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAddEntryTab(), _buildLogTab(), _buildTrendsTab()],
      ),
    );
  }

  Widget _buildAddEntryTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date selection
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );

                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pain level
                  const Text(
                    'Pain Level',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _painLevel.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _painLevel.toString(),
                    onChanged: (value) {
                      setState(() {
                        _painLevel = value.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text('No Pain'), Text('Severe Pain')],
                  ),

                  const SizedBox(height: 24),

                  // Bloating level
                  const Text(
                    'Bloating Level',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _bloatingLevel.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _bloatingLevel.toString(),
                    onChanged: (value) {
                      setState(() {
                        _bloatingLevel = value.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('No Bloating'),
                      Text('Severe Bloating'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Mood selection
                  const Text(
                    'Mood',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _moodOptions.map((mood) {
                      return ChoiceChip(
                        label: Text(mood),
                        selected: _selectedMood == mood,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedMood = mood;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Symptoms selection
                  const Text(
                    'Symptoms',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _symptomOptions.map((symptom) {
                      return FilterChip(
                        label: Text(symptom),
                        selected: _selectedSymptoms.contains(symptom),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.add(symptom);
                            } else {
                              _selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Notes
                  const Text(
                    'Notes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add any additional notes here...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addSymptomEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Entry'),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildLogTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entriesStream == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No entries yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking your symptoms by adding an entry',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Entry'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No entries yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start tracking your symptoms by adding an entry',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Entry'),
                ),
              ],
            ),
          );
        }

        final entries = snapshot.data!.docs
            .map((doc) => SymptomEntry.fromFirestore(doc))
            .toList();

        // Sort entries with most recent first
        entries.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          itemCount: entries.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final entry = entries[index];
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(entry.date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary
                                .withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            entry.mood,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildProgressIndicator('Pain', entry.painLevel),
                        const SizedBox(width: 16),
                        _buildProgressIndicator(
                            'Bloating', entry.bloatingLevel),
                      ],
                    ),
                    if (entry.symptoms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Symptoms:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: entry.symptoms.map((symptom) {
                          return Chip(
                            label: Text(
                              symptom,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.primary
                                .withAlpha((0.1 * 255).round()),
                          );
                        }).toList(),
                      ),
                    ],
                    if (entry.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.notes),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_entriesStream == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No data to analyze',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add entries to see trends and patterns',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Entry'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No data to analyze',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add entries to see trends and patterns',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Entry'),
                ),
              ],
            ),
          );
        }

        final entries = snapshot.data!.docs
            .map((doc) => SymptomEntry.fromFirestore(doc))
            .toList();

        // Sort entries by date for charts
        entries.sort((a, b) => a.date.compareTo(b.date));

        // Only show up to last 7 entries for readability
        final chartEntries =
            entries.length > 7 ? entries.sublist(entries.length - 7) : entries;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pain & Bloating Levels',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < chartEntries.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('MM/dd').format(
                                            chartEntries[value.toInt()].date,
                                          ),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: chartEntries.length - 1.0,
                            minY: 0,
                            maxY: 10,
                            lineBarsData: [
                              // Pain line
                              LineChartBarData(
                                spots: List.generate(
                                  chartEntries.length,
                                  (index) => FlSpot(
                                    index.toDouble(),
                                    chartEntries[index].painLevel.toDouble(),
                                  ),
                                ),
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color:
                                      Colors.red.withAlpha((0.1 * 255).round()),
                                ),
                              ),
                              // Bloating line
                              LineChartBarData(
                                spots: List.generate(
                                  chartEntries.length,
                                  (index) => FlSpot(
                                    index.toDouble(),
                                    chartEntries[index]
                                        .bloatingLevel
                                        .toDouble(),
                                  ),
                                ),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blue
                                      .withAlpha((0.1 * 255).round()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Pain', Colors.red),
                          const SizedBox(width: 24),
                          _buildLegendItem('Bloating', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Symptom frequency
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Most Common Symptoms',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildCommonSymptomsChart(entries),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Summary statistics
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Average Pain',
                              _calculateAveragePain(entries).toStringAsFixed(1),
                              Icons.healing,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Total Entries',
                              entries.length.toString(),
                              Icons.note_alt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Most Common Mood',
                              _findMostCommonMood(entries),
                              Icons.mood,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Tracking Since',
                              _getTrackingDuration(entries),
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(String label, int value) {
    Color getColor() {
      if (value <= 3) return Colors.green;
      if (value <= 6) return Colors.orange;
      return Colors.red;
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: $value/10',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value / 10,
            backgroundColor: Colors.grey.shade200,
            color: getColor(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildCommonSymptomsChart(List<SymptomEntry> entries) {
    // Count symptom frequencies
    final Map<String, int> symptomCounts = {};

    for (final entry in entries) {
      for (final symptom in entry.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
    }

    if (symptomCounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No symptoms recorded yet'),
        ),
      );
    }

    // Sort by frequency
    final sortedSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 symptoms
    final topSymptoms = sortedSymptoms.take(5).toList();

    return Column(
      children: topSymptoms.map((entry) {
        final symptom = entry.key;
        final count = entry.value;
        final percentage = count / entries.length * 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$symptom (${percentage.toStringAsFixed(0)}%)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateAveragePain(List<SymptomEntry> entries) {
    if (entries.isEmpty) return 0;

    final sum = entries.fold(0, (sum, entry) => sum + entry.painLevel);
    return sum / entries.length;
  }

  String _findMostCommonMood(List<SymptomEntry> entries) {
    if (entries.isEmpty) return 'N/A';

    final Map<String, int> moodCounts = {};

    for (final entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    String mostCommonMood = '';
    int highestCount = 0;

    moodCounts.forEach((mood, occurrences) {
      if (occurrences > highestCount) {
        mostCommonMood = mood;
        highestCount = occurrences;
      }
    });

    return mostCommonMood;
  }

  String _getTrackingDuration(List<SymptomEntry> entries) {
    if (entries.isEmpty) return 'N/A';

    final firstEntryDate =
        entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);

    final daysTracking = DateTime.now().difference(firstEntryDate).inDays;

    if (daysTracking < 30) {
      return '$daysTracking days';
    } else if (daysTracking < 365) {
      final months = (daysTracking / 30).floor();
      return '$months months';
    } else {
      final years = (daysTracking / 365).floor();
      final months = ((daysTracking % 365) / 30).floor();
      return '$years year${years > 1 ? 's' : ''}${months > 0 ? ', $months month${months > 1 ? 's' : ''}' : ''}';
    }
  }
}
