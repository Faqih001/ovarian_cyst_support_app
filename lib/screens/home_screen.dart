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
    const TrackingScreen(),
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
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  Map<String, dynamic>? _upcomingAppointment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                                const Text(
                                  'Welcome, Sarah!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'How are you feeling?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Track',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
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
                                icon: Icons.calendar_today,
                                label: 'Appointments',
                                color: AppColors.accent,
                              ),
                              _buildQuickActionButton(
                                context: context,
                                icon: Icons.medication,
                                label: 'Medications',
                                color: Colors.green,
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

                    // Health Insights
                    const Text(
                      'Health Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Health Tracking
                    _buildHealthTracking(),

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
                        ],
                      ),
                    ),

                    // Add some space at the bottom
                    const SizedBox(height: 80),
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

  Widget _buildEmojiButton(String emoji, String label) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TrackingScreen(),
          ),
        );
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
              MaterialPageRoute(builder: (_) => const TrackingScreen()),
            );
            break;
          case 'Appointments':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProviderSearchScreen()),
            );
            break;
          case 'Medications':
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const MedicationTrackingScreen()),
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
    return InkWell(
      onTap: () {
        switch (title) {
          case 'Nutrition for Ovarian Health':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EducationalScreen(initialCategory: 'nutrition'),
              ),
            );
            break;
          case 'Safe Exercises':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EducationalScreen(initialCategory: 'exercise'),
              ),
            );
            break;
          default:
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
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
                            subtitle: const Text('Public hospitals and clinics'),
                            onTap: () {
                              Navigator.pop(context); // Close the modal
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const KenyanHospitalBookingScreen(
                                    initialFacilityType: FacilityType.ministry,
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Private Practice'),
                            subtitle: const Text('Individual healthcare providers'),
                            onTap: () {
                              Navigator.pop(context); // Close the modal
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const KenyanHospitalBookingScreen(
                                    initialFacilityType: FacilityType.privatePractice,
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('Private Enterprise'),
                            subtitle: const Text('Private hospitals and institutions'),
                            onTap: () {
                              Navigator.pop(context); // Close the modal
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const KenyanHospitalBookingScreen(
                                    initialFacilityType: FacilityType.privateEnterprise,
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
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Symptoms'),
                  Tab(text: 'Medications'),
                  Tab(text: 'Activity'),
                ],
              ),
              SizedBox(
                height: 200,
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
        final symptom = symptoms[index].data() as Map<String, dynamic>;
        return Card(
          child: ListTile(
            leading: _buildSeverityIndicator(symptom['severity'] as int? ?? 1),
            title: Text(symptom['type'] as String? ?? 'Unknown'),
            subtitle: Text(symptom['description'] as String? ?? ''),
            trailing: Text(
              _formatDate(
                (symptom['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              ),
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
