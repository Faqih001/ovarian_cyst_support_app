import 'package:flutter/material.dart';
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
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
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
    const ProfileScreen(),
  ];

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
      body: _screens[_currentIndex],
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () => _showChatbotSheet(context),
          backgroundColor: AppColors.primary,
          elevation: 4,
          tooltip: 'AI Assistant',
          child: Stack(
            children: [
              const Icon(
                Icons.chat_rounded,
                color: Colors.white,
                size: 28,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 10,
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _showChatbotSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      // Setting this to false allows the sheet to overlap the navigation bar
      useSafeArea: false,
      // Setting this to true makes the sheet cover full screen height
      // but we'll handle spacing with our padding
      showDragHandle: false,
      // Set the animation curve for smoother opening
      barrierColor: Colors.black.withAlpha(128), // 0.5 * 255 = 127.5 ~ 128
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const ChatbotBottomSheet(),
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
    _loadUpcomingAppointment();
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
                    padding: const EdgeInsets.all(16.0),
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
                                        fontSize: 18,
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
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white.withAlpha(
                                (0.2 * 255).round(),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
          appointmentId, 'confirmed');

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
      final symptomWithId = {
        'id': docRef.id,
        ...newSymptom,
      };

      if (!mounted) return;

      // Navigate to tracking screen with the new symptom
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackingScreen(
            initialSymptom: symptomWithId,
          ),
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
      String docId, String userId, int severity, String description) async {
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
          final userId =
              Provider.of<AuthService>(context, listen: false).currentUser?.uid;
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
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TrackingScreen()),
            );
            break;
          case 'Medications':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const MedicationTrackingScreen()),
            );
            break;
          case 'ML Prediction':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const OvarianCystPredictionScreen()),
            );
            break;
          case 'Image Analysis':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ImageAnalysisChatScreen()),
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
              builder: (_) => const EducationalScreen(
                initialCategory: 'kenya_guide',
              ),
            ),
          );
        } else if (title == 'Nutrition for Ovarian Health') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EducationalScreen(
                initialCategory: 'nutrition',
              ),
            ),
          );
        } else if (title == 'Safe Exercises') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EducationalScreen(
                initialCategory: 'exercise',
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
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
                MaterialPageRoute(
                  builder: (_) => const ProviderSearchScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(
                color: AppColors.primary,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
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
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
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
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textLight,
                  ),
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
      content = Column(
        children: [
          const Text(
            'No upcoming appointments',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
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
                            style: TextStyle(
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.local_hospital),
                            title: const Text('Ministry of Health Facilities'),
                            subtitle:
                                const Text('Public hospitals and clinics'),
                            onTap: () {
                              Navigator.pop(context); // Close the modal
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const KenyanHospitalBookingScreen(
                                    initialFacilityType: FacilityType.ministry,
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Private Practice'),
                            subtitle:
                                const Text('Individual healthcare providers'),
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
                                'Private hospitals and institutions'),
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
                            subtitle:
                                const Text('Private clinics and specialists'),
                            onTap: () {
                              Navigator.pop(context); // Close the modal
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProviderSearchScreen(),
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
            ),
            child: const Text('Book Appointment'),
          ),
        ],
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
              Provider.of<AuthService>(context, listen: false).currentUser?.uid)
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
            Icon(
              Icons.healing_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
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
        final userId =
            Provider.of<AuthService>(context, listen: false).currentUser?.uid;

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
      BuildContext context, String docId, Map<String, dynamic> symptom) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _EditSymptomDialog(
          docId: docId,
          symptom: symptom,
          onSave: (severity, description) {
            final userId = Provider.of<AuthService>(context, listen: false)
                .currentUser
                ?.uid;
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
              Provider.of<AuthService>(context, listen: false).currentUser?.uid)
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
            decoration: const InputDecoration(
              labelText: 'Description',
            ),
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

class ChatbotBottomSheet extends StatelessWidget {
  const ChatbotBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    // Get the bottom padding to account for navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom +
        60; // Reduced from 80 to make more space
    // Calculate horizontal padding - 3% of screen width on each side (reduced from 5%)
    final horizontalPadding = screenSize.width * 0.03;

    return DraggableScrollableSheet(
      initialChildSize: 0.88, // Further increased for better visibility
      minChildSize: 0.65, // Increased min size
      maxChildSize: 0.98, // Allow almost full screen
      builder: (_, controller) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: bottomPadding,
            left: horizontalPadding,
            right: horizontalPadding,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51), // 0.2 * 255 = 51
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add a drag handle to make it clear it's draggable
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // Title and assistant options
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "OvaCare Assistant",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Choose how you'd like assistance:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Option buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildAssistantOption(
                              context,
                              icon: Icons.chat,
                              title: "Text Chat",
                              description: "Ask questions about ovarian cysts",
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChatbotScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAssistantOption(
                              context,
                              icon: Icons.image_search,
                              title: "Image Analysis",
                              description:
                                  "Upload medical images for educational insights",
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ImageAnalysisChatScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25.0),
                      bottomRight: Radius.circular(25.0),
                    ),
                    child: const ChatbotScreen(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssistantOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
