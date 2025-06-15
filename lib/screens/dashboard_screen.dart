import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/symptom_entry.dart';
import '../models/appointment.dart';
import '../models/symptom_prediction.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

import 'symptom_prediction_screen.dart';
import 'chatbot_screen.dart';
import 'image_analysis_chat_screen.dart';
import 'provider_search_screen.dart';
import 'tracking_screen.dart';
import 'educational_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOnline = true;
  bool _isSyncing = false;
  bool _isLoading = true;
  int _unreadMessages = 0;
  List<SymptomEntry> _recentSymptoms = [];
  List<Appointment> _upcomingAppointments = [];
  SymptomPrediction? _latestPrediction;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkConnectivity();

    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection != _isOnline) {
        setState(() {
          _isOnline = hasConnection;
        });
        if (hasConnection) {
          _syncData();
        }
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final aiService = Provider.of<AIService>(context, listen: false);

      // Remove limit parameter as it may not be supported
      final symptoms = await dbService.getRecentSymptomEntries();
      final appointments = await dbService.getUpcomingAppointments();
      final prediction = await aiService.getLatestPrediction();

      // Convert Map<String, dynamic> to SymptomEntry objects
      final convertedSymptoms = symptoms
          .map((symptom) => SymptomEntry(
                id: symptom['id'] ?? '',
                date: symptom['date'] is DateTime
                    ? symptom['date']
                    : (symptom['date'] != null
                        ? DateTime.parse(symptom['date'].toString())
                        : DateTime.now()),
                mood: symptom['mood'] ?? '',
                painLevel: symptom['painLevel'] ?? 0,
                bloatingLevel: symptom['bloatingLevel'] ?? 0,
                symptoms: symptom['symptoms'] is List
                    ? List<String>.from(symptom['symptoms'])
                    : [],
                description: symptom['description'] ?? '',
                notes: symptom['notes'] ?? '',
                timestamp: symptom['timestamp'] is Timestamp
                    ? symptom['timestamp'].toDate()
                    : DateTime.now(),
                isUploaded: symptom['isUploaded'] ?? false,
                updatedAt: symptom['updatedAt'] is Timestamp
                    ? symptom['updatedAt'].toDate()
                    : DateTime.now(),
              ))
          .toList();

      // Convert dynamic to Appointment objects using the proper Appointment model fields
      final convertedAppointments = appointments
          .map((apt) => Appointment(
                id: apt['id'] ?? '',
                doctorName: apt['doctorName'] ?? '',
                providerName: apt['providerName'] ?? '',
                specialization: apt['specialization'] ?? '',
                purpose: apt['purpose'] ?? '',
                dateTime: apt['dateTime'] is DateTime
                    ? apt['dateTime']
                    : (apt['date'] != null
                        ? DateTime.parse(apt['date'].toString())
                        : DateTime.now()),
                location: apt['location'] ?? '',
                notes: apt['notes'],
                reminderEnabled: apt['reminderEnabled'] ?? false,
              ))
          .toList();

      setState(() {
        _recentSymptoms = convertedSymptoms;
        _upcomingAppointments = convertedAppointments;
        _latestPrediction = prediction;
        _unreadMessages = 3; // Placeholder, replace with actual unread count
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
  }

  Future<void> _syncData() async {
    if (!_isOnline) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = Provider.of<SyncService>(context, listen: false);

      await syncService.syncAll();
      await _loadData(); // Reload data after sync
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync error: ${e.toString()}')));
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ovarian Health Dashboard'),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(_isOnline ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _isOnline ? _syncData : null,
            tooltip: _isOnline ? 'Online - Tap to sync' : 'Offline',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildHealthInsights(),
                      const SizedBox(height: 24),
                      _buildUpcomingAppointments(),
                      const SizedBox(height: 24),
                      _buildRecentActivity(),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(
                Icons.calendar_today,
                'Calendar',
                false,
                onTap: () {
                  // Navigate to appointments calendar
                },
              ),
              _buildFabPlaceholder(),
              _buildNavItem(
                Icons.chat,
                'Chat',
                false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                  );
                },
                badge: _unreadMessages > 0 ? _unreadMessages : null,
              ),
              _buildNavItem(Icons.menu, 'More', false),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const TrackingScreen()));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected, {
    VoidCallback? onTap,
    int? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color:
                      isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabPlaceholder() {
    return const SizedBox(width: 48);
  }

  Widget _buildLoadingView() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  Icons.medical_services,
                  'Find Doctor',
                  Colors.blue[700]!,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProviderSearchScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  Icons.analytics,
                  'AI Insights',
                  Colors.purple[700]!,
                  () {
                    // Show options for AI features
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "AI Features",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Choose an AI-powered feature:",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.analytics,
                                  color: Colors.purple),
                              title: const Text("Symptom Prediction"),
                              subtitle: const Text(
                                  "AI analysis based on your symptoms"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SymptomPredictionScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.image_search,
                                  color: Colors.indigo),
                              title: const Text("Image Analysis"),
                              subtitle: const Text(
                                  "Upload medical images for educational insights"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ImageAnalysisChatScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading:
                                  const Icon(Icons.chat, color: Colors.teal),
                              title: const Text("AI Assistant Chat"),
                              subtitle: const Text(
                                  "Ask questions about ovarian cysts"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatbotScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _buildActionButton(Icons.book, 'Learn', Colors.green[700]!, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EducationalScreen(),
                    ),
                  );
                }),
                _buildActionButton(
                  Icons.people,
                  'Community',
                  Colors.orange[700]!,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CommunityScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInsights() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Insights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SymptomPredictionScreen(),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_latestPrediction != null) ...[
              _buildPredictionSummary(),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recent health data available. Add symptom entries for AI insights.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrackingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Track Your Symptoms'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionSummary() {
    // Placeholder data, replace with actual prediction data
    final risk = _latestPrediction?.riskLevel ?? 'Low';
    final riskScore = _latestPrediction?.severityScore ?? 0.2;
    final recommendations = _latestPrediction?.potentialIssues ??
        [
          'Keep tracking your symptoms',
          'Stay hydrated',
          'Contact your doctor if pain increases',
        ];

    Color riskColor;
    if (risk == 'High') {
      riskColor = Colors.red;
    } else if (risk == 'Medium') {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Risk Assessment:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          risk,
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Based on recent entries',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: riskScore,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                    ),
                    Text(
                      '${(riskScore * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Recommendations:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...recommendations.map(
          (rec) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(rec, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Appointments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to appointments calendar
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_upcomingAppointments.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No upcoming appointments',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              ..._upcomingAppointments
                  .take(2)
                  .map((appointment) => _buildAppointmentItem(appointment)),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProviderSearchScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Book an Appointment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(Appointment appointment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(
                  context,
                ).primaryColor.withAlpha((0.2 * 255).toInt()),
              ),
              child: Center(
                child: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${appointment.providerName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.specialization,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year} at ${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show appointment actions
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Symptom Entries',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _recentSymptoms.isEmpty
                  ? const Center(
                      child: Text(
                        'No recent symptom entries',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getChartDataFromSymptoms(),
                            isCurved: true,
                            color: Theme.of(context).primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha((0.2 * 255).toInt()),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (_recentSymptoms.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recent Entries:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ..._recentSymptoms
                  .take(3)
                  .map((symptom) => _buildSymptomItem(symptom)),
            ],
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartDataFromSymptoms() {
    List<FlSpot> spots = [];

    // For testing, generate dummy data if no real data available
    if (_recentSymptoms.isEmpty) {
      return [
        const FlSpot(0, 3),
        const FlSpot(1, 1),
        const FlSpot(2, 4),
        const FlSpot(3, 2),
        const FlSpot(4, 5),
      ];
    }

    // Sort symptoms by date
    final sortedSymptoms = _recentSymptoms.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Convert to chart data
    for (int i = 0; i < sortedSymptoms.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedSymptoms[i].painLevel.toDouble()));
    }

    return spots;
  }

  Widget _buildSymptomItem(SymptomEntry symptom) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getPainLevelColor(
                symptom.painLevel,
              ).withAlpha((0.2 * 255).toInt()),
            ),
            child: Center(
              child: Text(
                symptom.painLevel.toString(),
                style: TextStyle(
                  color: _getPainLevelColor(symptom.painLevel),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${symptom.timestamp.day}/${symptom.timestamp.month}/${symptom.timestamp.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            _getPainLevelText(symptom.painLevel),
            style: TextStyle(
              color: _getPainLevelColor(symptom.painLevel),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPainLevelColor(int level) {
    if (level <= 2) return Colors.green;
    if (level <= 4) return Colors.orange;
    return Colors.red;
  }

  String _getPainLevelText(int level) {
    if (level <= 2) return 'Mild';
    if (level <= 4) return 'Moderate';
    return 'Severe';
  }
}
