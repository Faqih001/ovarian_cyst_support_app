import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/tracking_screen.dart';
import 'package:ovarian_cyst_support_app/screens/community_screen.dart';
import 'package:ovarian_cyst_support_app/screens/profile_screen.dart';
import 'package:ovarian_cyst_support_app/screens/educational_screen.dart';
import 'package:ovarian_cyst_support_app/screens/provider_search_screen.dart';
import 'package:ovarian_cyst_support_app/screens/medication_tracking_screen.dart';
import 'package:ovarian_cyst_support_app/screens/kenyan_hospital_booking_screen.dart';
import 'package:ovarian_cyst_support_app/screens/ovarian_cyst_prediction_screen.dart';
import 'package:ovarian_cyst_support_app/screens/chatbot_screen.dart';
import 'package:ovarian_cyst_support_app/screens/image_analysis_chat_screen.dart';
import 'package:ovarian_cyst_support_app/screens/notification_screen.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/firebase_notification_service.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:ovarian_cyst_support_app/services/hospital_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;

  final List<Widget> _screens = [
    const HomeContent(),
    TrackingScreen(),
    const CommunityScreen(),
    const ChatbotScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: 'Chat AI',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final DatabaseService _databaseService;
  Map<String, dynamic>? _upcomingAppointment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _initializeServices();
    _loadUpcomingAppointment();
  }

  Future<void> _initializeServices() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<FirebaseNotificationService>(
      context,
      listen: false,
    );

    if (authService.user?.uid != null) {
      await notificationService.initialize(authService.user!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUpcomingAppointment() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final appointments = await _databaseService.getUpcomingAppointments();
      if (mounted && appointments.isNotEmpty) {
        final Map<String, dynamic> firstAppointment = {
          'id': appointments[0].id,
          'date': appointments[0].dateTime,
          'time': appointments[0].dateTime.toString(),
          'doctor': appointments[0].doctorName,
          'type': appointments[0].specialization,
          'status': 'pending', // Default status
        };
        setState(() => _upcomingAppointment = firstAppointment);
      }
    } catch (e) {
      debugPrint('Error loading appointment: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<AuthService>(
                                  builder: (context, authService, _) {
                                    final user = authService.user;
                                    final name =
                                        user?.displayName?.split(' ')[0] ??
                                        'Guest';
                                    return Text(
                                      'Welcome, $name!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  'How are you feeling today?',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(
                                      (0.8 * 255).round(),
                                    ),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Consumer<FirebaseNotificationService>(
                                  builder: (context, notificationService, _) {
                                    final unreadCount = notificationService
                                        .getUnreadCount();
                                    return Stack(
                                      children: [
                                        IconButton(
                                          iconSize: 36,
                                          padding: const EdgeInsets.all(8.0),
                                          icon: const Icon(
                                            Icons.notifications_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const NotificationScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              child: Text(
                                                unreadCount > 99
                                                    ? '99+'
                                                    : '$unreadCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feeling tracker
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha((0.1 * 255).round()),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'How are you feeling?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const TrackingScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Track',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildEmojiButton('😊', 'Good'),
                              _buildEmojiButton('😐', 'Okay'),
                              _buildEmojiButton('😣', 'Pain'),
                              _buildEmojiButton('😴', 'Tired'),
                              _buildEmojiButton('😥', 'Stressed'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(
                          (0.1 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.edit_note,
                                label: 'Log Symptoms',
                                color: AppColors.primary,
                              ),
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.medication,
                                label: 'Medications',
                                color: Colors.green,
                              ),
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.analytics,
                                label: 'ML Prediction',
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.image_search,
                                label: 'Image Analysis',
                                color: Colors.indigo,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Upcoming Appointment
                    _buildAppointmentSection(),

                    const SizedBox(height: 24),

                    // Health Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Tips & Resources',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildResourceCard(
                            title: 'Nutrition for Ovarian Health',
                            description:
                                'Foods that can help manage symptoms and support recovery',
                            icon: Icons.food_bank,
                            color: AppColors.primary,
                          ),
                          _buildResourceCard(
                            title: 'Safe Exercises',
                            description:
                                'Gentle workout routines that can help with pain management',
                            icon: Icons.fitness_center,
                            color: AppColors.accent,
                          ),
                          _buildResourceCard(
                            title: 'Kenya Ovarian Health Guide',
                            description:
                                'Learn more about ovarian cysts from Kenyan health experts',
                            icon: Icons.school,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Health Insights Header
                    const Text(
                      'Health Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Health Tracking
                    _buildHealthTracking(),

                    // Add some space at the bottom
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAppointment(Map<String, dynamic> appointment) async {
    try {
      final appointmentId = appointment['id'];
      if (appointmentId == null) return;

      await _databaseService.updateAppointmentStatus(
        appointmentId,
        'confirmed',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment confirmed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the appointments list
      setState(() => _loadUpcomingAppointment());
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logSymptom(String label, int severity, String userId) async {
    // Capture scaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Get current timestamp
      final now = DateTime.now();

      final newSymptom = {
        'type': label,
        'severity': severity,
        'description': 'Feeling $label',
        'timestamp': Timestamp.fromDate(now),
        'date': now.toIso8601String(),
        'userId': userId,
        'status': 'active',
      };

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('symptoms')
          .add(newSymptom);

      // Get the document with the ID
      final symptomWithId = {'id': docRef.id, ...newSymptom};

      if (!mounted) return;

      // Navigate to tracking screen with the new symptom
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackingScreen(initialSymptom: symptomWithId),
        ),
      );

      // Refresh the UI if still mounted
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Show error if still mounted
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error recording symptom: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editSymptom(
    String docId,
    String userId,
    int severity,
    String description,
  ) async {
    // Capture scaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('symptoms')
          .doc(docId)
          .update({
            'severity': severity,
            'description': description,
            'lastUpdated': Timestamp.now(),
          });

      if (!mounted) return;

      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Symptom updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error updating symptom: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmojiButton(String emoji, String label) {
    return InkWell(
      onTap: () async {
        try {
          final userId = Provider.of<AuthService>(
            context,
            listen: false,
          ).currentUser?.uid;
          if (userId == null) {
            // Handle not logged in case
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in to track symptoms'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          await _logSymptom(label, _getSeverityFromLabel(label), userId);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error recording symptom: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withAlpha((0.3 * 255).round()),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  int _getSeverityFromLabel(String label) {
    switch (label) {
      case 'Good':
        return 1;
      case 'Okay':
        return 2;
      case 'Pain':
        return 4;
      case 'Tired':
        return 3;
      case 'Stressed':
        return 3;
      default:
        return 3;
    }
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        switch (label) {
          case 'Log Symptoms':
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => TrackingScreen()));
            break;
          case 'Medications':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MedicationTrackingScreen(),
              ),
            );
            break;
          case 'ML Prediction':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OvarianCystPredictionScreen(),
              ),
            );
            break;
          case 'Image Analysis':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ImageAnalysisChatScreen(),
              ),
            );
            break;
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        if (title == 'Kenya Ovarian Health Guide') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const EducationalScreen(initialCategory: 'kenya_guide'),
            ),
          );
        } else if (title == 'Nutrition for Ovarian Health') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const EducationalScreen(initialCategory: 'nutrition'),
            ),
          );
        } else if (title == 'Safe Exercises') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const EducationalScreen(initialCategory: 'exercise'),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentActions(Map<String, dynamic>? appointment) {
    if (appointment == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProviderSearchScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Reschedule'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirmAppointment(appointment),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentInfo(Map<String, dynamic>? appointment) {
    if (appointment == null) return const SizedBox.shrink();

    final date =
        (appointment['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final time = appointment['time'] as String? ?? '';
    final doctor = appointment['doctor'] as String? ?? '';
    final type = appointment['type'] as String? ?? '';

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_month, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${date.day}/${date.month}/${date.year} - $time',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentSection() {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_upcomingAppointment == null) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.1 * 255).round()),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'No upcoming appointments',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Show options for booking appointment
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                'Book an Appointment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Select the type of healthcare facility you want to book with:',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(Icons.local_hospital),
                                title: const Text(
                                  'Ministry of Health Facilities',
                                ),
                                subtitle: const Text(
                                  'Public hospitals and clinics',
                                ),
                                onTap: () {
                                  Navigator.pop(context); // Close the modal
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const KenyanHospitalBookingScreen(
                                            initialFacilityType:
                                                FacilityType.ministry,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.person),
                                title: const Text('Private Practice'),
                                subtitle: const Text(
                                  'Individual healthcare providers',
                                ),
                                onTap: () {
                                  Navigator.pop(context); // Close the modal
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const KenyanHospitalBookingScreen(
                                            initialFacilityType:
                                                FacilityType.privatePractice,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.business),
                                title: const Text('Private Enterprise'),
                                subtitle: const Text(
                                  'Private hospitals and institutions',
                                ),
                                onTap: () {
                                  Navigator.pop(context); // Close the modal
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const KenyanHospitalBookingScreen(
                                            initialFacilityType:
                                                FacilityType.privateEnterprise,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.healing),
                                title: const Text('Other Healthcare Providers'),
                                subtitle: const Text(
                                  'Private clinics and specialists',
                                ),
                                onTap: () {
                                  Navigator.pop(context); // Close the modal
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ProviderSearchScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Appointment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProviderSearchScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAppointmentInfo(_upcomingAppointment),
          const SizedBox(height: 16),
          _buildAppointmentActions(_upcomingAppointment),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildHealthTracking() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(
            Provider.of<AuthService>(context, listen: false).currentUser?.uid,
          )
          .collection('symptoms')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha((0.1 * 255).round()),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                onTap: (_) => setState(() {}), // Force refresh on tab change
                tabs: const [
                  Tab(text: 'Symptoms'),
                  Tab(text: 'Medications'),
                  Tab(text: 'Activity'),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 200.0,
                  maxHeight: 400.0,
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSymptomsView(snapshot.data?.docs ?? []),
                    _buildMedicationsView(),
                    _buildActivityView(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymptomsView(List<QueryDocumentSnapshot> symptoms) {
    if (symptoms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.healing_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No symptoms logged yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: symptoms.length,
      itemBuilder: (context, index) {
        final data = symptoms[index].data() as Map<String, dynamic>? ?? {};
        final docId = symptoms[index].id;
        final userId = Provider.of<AuthService>(
          context,
          listen: false,
        ).currentUser?.uid;

        // Safely access the symptom data with null checks
        final type = data['type'] as String? ?? 'Unknown';
        final severity = data['severity'] as int? ?? 1;
        final description = data['description'] as String? ?? '';
        final timestamp = data['timestamp'] as Timestamp? ?? Timestamp.now();

        return Card(
          child: Dismissible(
            key: Key(docId),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('symptoms')
                    .doc(docId)
                    .delete();

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Symptom deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting symptom: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: ListTile(
              leading: _buildSeverityIndicator(severity),
              title: Text(type),
              subtitle: Text(description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatDate(timestamp.toDate())),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () =>
                        _showEditSymptomDialog(context, docId, data),
                  ),
                ],
              ),
              onTap: () => _showSymptomDetails(context, data),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeverityIndicator(int severity) {
    final color = severity < 3
        ? Colors.green
        : severity < 5
        ? Colors.orange
        : Colors.red;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withAlpha(51), // 0.2 * 255 ≈ 51
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          severity.toString(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showSymptomDetails(BuildContext context, Map<String, dynamic> symptom) {
    final type = symptom['type'] as String? ?? 'Unknown';
    final severity = symptom['severity'] as int? ?? 1;
    final description = symptom['description'] as String? ?? '';
    final timestamp = symptom['timestamp'] as Timestamp? ?? Timestamp.now();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Symptom Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: _buildSeverityIndicator(severity),
                title: Text(type),
                subtitle: Text(description),
              ),
              const SizedBox(height: 8),
              Text(
                'Recorded on: ${_formatDateTime(timestamp.toDate())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSymptomDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> symptom,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _EditSymptomDialog(
          docId: docId,
          symptom: symptom,
          onSave: (severity, description) {
            final userId = Provider.of<AuthService>(
              context,
              listen: false,
            ).currentUser?.uid;
            if (userId != null) {
              _editSymptom(docId, userId, severity, description);
            }
          },
        );
      },
    );
  }

  Widget _buildMedicationsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(
            Provider.of<AuthService>(context, listen: false).currentUser?.uid,
          )
          .collection('medications')
          .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final medications = snapshot.data?.docs ?? [];

        if (medications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active medications',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication =
                medications[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.medication),
                title: Text(medication['name'] as String? ?? 'Unknown'),
                subtitle: Text(
                  '${medication['dosage']} - ${medication['frequency']}',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Activity tracking coming soon',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Dialog for editing symptoms
class _EditSymptomDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> symptom;
  final void Function(int severity, String description) onSave;

  const _EditSymptomDialog({
    required this.docId,
    required this.symptom,
    required this.onSave,
  });

  @override
  State<_EditSymptomDialog> createState() => _EditSymptomDialogState();
}

class _EditSymptomDialogState extends State<_EditSymptomDialog> {
  late TextEditingController _descriptionController;
  late int _currentSeverity;

  @override
  void initState() {
    super.initState();
    _currentSeverity = widget.symptom['severity'] as int? ?? 1;
    _descriptionController = TextEditingController(
      text: widget.symptom['description'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Symptom'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Severity'),
          Slider(
            value: _currentSeverity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _currentSeverity.toString(),
            onChanged: (value) {
              setState(() {
                _currentSeverity = value.round();
              });
            },
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_currentSeverity, _descriptionController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ChatbotBottomSheet extends StatefulWidget {
  const ChatbotBottomSheet({super.key});

  @override
  State<ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<ChatbotBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isImageMode = false;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotateAnimation;

  @override
  void initState() {
    super.initState();
    // Setup tab controller
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Only respond to user interactions, not programmatic ones
      if (_tabController.indexIsChanging) {
        // Provide tactile feedback when switching tabs
        HapticFeedback.lightImpact();

        setState(() {
          _isImageMode = _tabController.index == 1;
        });

        // Clear any active focus to hide keyboard when switching tabs
        FocusScope.of(context).unfocus();

        // Start animations when tab changes
        if (_iconAnimationController.status == AnimationStatus.completed) {
          _iconAnimationController.reset();
        }
        _iconAnimationController.forward();
      }
    });

    // Setup animations for smooth transitions
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _iconRotateAnimation =
        Tween<double>(
          begin: 0.0,
          end: 2 * 3.14159, // Full rotation
        ).animate(
          CurvedAnimation(
            parent: _iconAnimationController,
            curve: Curves.easeInOutBack,
          ),
        );

    // Start initial animation
    _iconAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 38), // 0.15 * 255 ≈ 38
                blurRadius: 24,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle and Header
              _buildHeader(),

              // Tab Bar
              // Enhanced modern tab switcher with animation and haptic feedback
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 51),
                      _isImageMode
                          ? AppColors.accent.withValues(alpha: 51)
                          : AppColors.primary
                                .withBlue(200)
                                .withValues(alpha: 51),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 20),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    splashBorderRadius: BorderRadius.circular(25),
                    splashFactory: InkRipple.splashFactory,
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white.withValues(
                          alpha: 26,
                        ); // 0.1 * 255 ≈ 26
                      }
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white.withValues(
                          alpha: 51,
                        ); // 0.2 * 255 ≈ 51
                      }
                      return null;
                    }),
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          _isImageMode
                              ? AppColors.accent
                              : AppColors.primary.withBlue(200),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    dividerHeight: 0,
                    tabs: [
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: !_isImageMode
                                      ? Colors.white.withValues(
                                          alpha: 51,
                                        ) // 0.2 * 255 ≈ 51
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_rounded,
                                  color: !_isImageMode
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  size: !_isImageMode ? 20 : 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chat',
                                style: TextStyle(
                                  fontWeight: !_isImageMode
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isImageMode
                                      ? Colors.white.withValues(
                                          alpha: 51,
                                        ) // 0.2 * 255 ≈ 51
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.image_search_rounded,
                                  color: _isImageMode
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  size: _isImageMode ? 20 : 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Analysis',
                                style: TextStyle(
                                  fontWeight: _isImageMode
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Content Area with smooth page transitions
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 10),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [_buildChatTab(), _buildImageAnalysisTab()],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Close button at the top right corner
        Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: _isImageMode ? AppColors.accent : AppColors.primary,
              ),
            ),
            tooltip: 'Close',
          ),
        ),
        // Enhanced Drag Handle with subtle animation
        GestureDetector(
          onTap: () {
            // Provide feedback when tapped
            HapticFeedback.mediumImpact();

            // Dismiss the bottom sheet when handle is tapped
            Navigator.of(context).pop();
          },
          child: Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: _isImageMode
                  ? AppColors.accent.withValues(alpha: 77) // 0.3 * 255 ≈ 77
                  : AppColors.primary.withValues(alpha: 77),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // Centered Avatar/Icon with gradient background and animations
        Center(
          child: AnimatedBuilder(
            animation: _iconAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _iconScaleAnimation.value,
                child: Transform.rotate(
                  angle: _iconRotateAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          _isImageMode
                              ? AppColors.accent
                              : AppColors.primary.withBlue(200),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isImageMode
                                      ? AppColors.accent
                                      : AppColors.primary)
                                  .withValues(alpha: 51),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                      child: Icon(
                        _isImageMode
                            ? Icons.image_search_rounded
                            : Icons.smart_toy_rounded,
                        key: ValueKey<bool>(_isImageMode),
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Title and Subtitle with animations
        Center(
          child: Column(
            children: [
              // Animated title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _isImageMode ? 'Image Analysis' : 'OvaCare Assistant',
                  key: ValueKey<bool>(_isImageMode),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Animated subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _isImageMode
                      ? 'Upload medical images for instant analysis'
                      : 'Your personal health companion',
                  key: ValueKey<bool>(_isImageMode),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChatTab() {
    return AnimatedOpacity(
      opacity: !_isImageMode ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 250),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: !_isImageMode
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const ChatbotScreen(),
        ),
      ),
    );
  }

  Widget _buildImageAnalysisTab() {
    return AnimatedOpacity(
      opacity: _isImageMode ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 250),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isImageMode
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const ImageAnalysisChatScreen(),
        ),
      ),
    );
  }
}
