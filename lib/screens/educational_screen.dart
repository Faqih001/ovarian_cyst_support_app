import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EducationalScreen extends StatefulWidget {
  final String initialCategory;

  const EducationalScreen({super.key, this.initialCategory = 'basics'});

  @override
  State<EducationalScreen> createState() => _EducationalScreenState();
}

class _EducationalScreenState extends State<EducationalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'basics',
    'symptoms',
    'treatment',
    'nutrition',
    'exercise',
    'kenya'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    // Set initial tab based on category
    final initialIndex = _categories.indexOf(widget.initialCategory);
    if (initialIndex != -1) {
      _tabController.animateTo(initialIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String section = args?['section'] ?? 'main';

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(section)),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          if (section == 'main')
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51), // 0.2 * 255
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey[600],
                tabs: [
                  Tab(text: 'Basics'),
                  Tab(text: 'Symptoms'),
                  Tab(text: 'Treatment'),
                  Tab(text: 'Nutrition'),
                  Tab(text: 'Exercise'),
                  Tab(text: 'Kenya Guide'),
                ],
              ),
            ),
          Expanded(
            child: _getContent(section),
          ),
        ],
      ),
    );
  }

  String _getTitle(String section) {
    switch (section) {
      case 'kenya_guide':
        return 'Kenya Health Guide';
      case 'nutrition':
        return 'Nutrition Guide';
      case 'exercises':
        return 'Exercise Guide';
      default:
        return 'Educational Resources';
    }
  }

  Widget _getContent(String section) {
    switch (section) {
      case 'kenya_guide':
        return _buildKenyaGuide();
      case 'nutrition':
        return _buildNutritionGuide();
      case 'exercises':
        return _buildExerciseGuide();
      default:
        return _buildMainContent();
    }
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: _categories.map((category) {
        switch (category) {
          case 'basics':
            return const BasicsTab();
          case 'symptoms':
            return const SymptomsTab();
          case 'treatment':
            return const TreatmentTab();
          case 'nutrition':
            return const NutritionTab();
          case 'exercise':
            return const ExerciseTab();
          case 'kenya':
            return _buildKenyaGuide();
          default:
            return const Center(child: Text('Coming soon'));
        }
      }).toList(),
    );
  }

  Widget _buildKenyaGuide() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Updated padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ovarian Health in Kenya',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Local Healthcare Resources',
            content: '''
• Kenyatta National Hospital - Reproductive Health Department
• Aga Khan University Hospital - Women's Health Centre
• Moi Teaching and Referral Hospital - Gynecology Unit
            ''',
            icon: Icons.local_hospital,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Understanding Ovarian Cysts',
            content: '''
Common symptoms to watch for:
• Abdominal pain or pressure
• Irregular menstrual cycles
• Bloating
• Nausea

Seek medical attention if you experience severe pain or persistent symptoms.
            ''',
            icon: Icons.health_and_safety,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Treatment Options in Kenya',
            content: '''
• Traditional medicine consultations
• Modern medical treatments
• Surgical options when necessary
• Support groups and counseling services
            ''',
            icon: Icons.medical_services,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Local Support Networks',
            content: '''
• Kenya Network of Women with AIDS (KENWA)
• Women's Health Organizations
• Community Health Workers
• Mental Health Support Groups
            ''',
            icon: Icons.people,
          ),
          const SizedBox(height: 32), // Added extra bottom spacing
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(26), // 0.1 * 255
                    AppColors.accent.withAlpha(26), // 0.1 * 255
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nutrition Guidelines',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A balanced diet plays a crucial role in managing ovarian cysts and overall reproductive health.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildNutritionSection(
            'Recommended Foods',
            'Include these nutrient-rich foods in your daily diet:',
            [
              'Dark leafy greens (spinach, kale) - Rich in iron and antioxidants',
              'Fatty fish (salmon, mackerel) - High in omega-3 fatty acids',
              'Lean proteins (chicken, legumes, tofu) - Essential for healing',
              'Whole grains (quinoa, brown rice) - For sustained energy',
              'Nuts and seeds (almonds, flaxseeds) - Rich in healthy fats',
              'Colorful fruits (berries, citrus) - High in vitamins and antioxidants',
              'Probiotic foods (yogurt, kefir) - For gut health',
              'Green tea - Rich in antioxidants',
            ],
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 24),
          _buildNutritionSection(
            'Foods to Limit',
            'Minimize these foods to reduce inflammation and symptoms:',
            [
              'Processed foods - High in unhealthy fats and preservatives',
              'Sugary drinks and snacks - Can increase inflammation',
              'Caffeine - May worsen hormone imbalances',
              'Alcohol - Can affect hormone levels',
              'High-sodium foods - May increase bloating and water retention',
              'Red meat - Can increase inflammation',
              'Refined carbohydrates - May affect blood sugar levels',
            ],
            Icons.remove_circle,
            Colors.red,
          ),
          const SizedBox(height: 24),
          _buildNutritionSection(
            'Helpful Tips',
            'Maintain these healthy eating habits:',
            [
              'Eat small, frequent meals throughout the day',
              'Stay well hydrated with water and herbal teas',
              'Consider taking doctor-recommended supplements',
              'Plan your meals ahead to ensure balanced nutrition',
              'Listen to your body and identify trigger foods',
            ],
            Icons.lightbulb,
            AppColors.accent,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(
    String title,
    String subtitle,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26), // 0.1 * 255
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(26), // 0.1 * 255
                    AppColors.accent.withAlpha(26), // 0.1 * 255
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exercise Guidelines',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Safe exercises can help manage symptoms and improve overall health.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildRecommendedExercises(),
          const SizedBox(height: 24),
          _buildExercisePrecautions(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRecommendedExercises() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.directions_run, size: 24, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  'Recommended Activities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildExerciseItem(
              icon: Icons.directions_walk,
              title: 'Walking',
              duration: '30-60 minutes',
              frequency: '5 times per week',
              tips: 'Start slow and gradually increase pace and duration',
            ),
            _buildExerciseItem(
              icon: Icons.pool,
              title: 'Swimming',
              duration: '30 minutes',
              frequency: '2-3 times per week',
              tips: 'Focus on gentle strokes and avoid intense movements',
            ),
            _buildExerciseItem(
              icon: Icons.self_improvement,
              title: 'Yoga',
              duration: '20-30 minutes',
              frequency: '3-4 times per week',
              tips: 'Avoid poses that put pressure on the abdomen',
            ),
            _buildExerciseItem(
              icon: Icons.fitness_center,
              title: 'Light Strength Training',
              duration: '15-20 minutes',
              frequency: '2-3 times per week',
              tips: 'Use light weights and focus on proper form',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem({
    required IconData icon,
    required String title,
    required String duration,
    required String frequency,
    required String tips,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Duration: $duration'),
                Text('Frequency: $frequency'),
                Text('Tips: $tips'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePrecautions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Exercise Precautions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPrecautionItem(
            'Stop exercising and seek medical attention if you experience severe pain',
          ),
          _buildPrecautionItem(
            'Avoid high-impact activities that could cause the cyst to rupture',
          ),
          _buildPrecautionItem(
            'Listen to your body and don\'t push beyond your comfort level',
          ),
          _buildPrecautionItem(
            'Stay hydrated and wear comfortable, supportive clothing',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Always consult with your healthcare provider before starting any new exercise routine',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecautionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class BasicsTab extends StatelessWidget {
  const BasicsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'What are Ovarian Cysts?',
            content:
                'Ovarian cysts are fluid-filled sacs that develop on or inside an ovary. Many women will develop at least one cyst during their lifetime. In most cases, cysts are harmless and go away on their own.',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Types of Ovarian Cysts',
            content:
                '• Functional cysts: Form during a normal menstrual cycle\n• Dermoid cysts: May contain hair, fat, or other tissue\n• Cystadenomas: Develop on the surface of an ovary\n• Endometriomas: Form due to endometriosis',
            icon: Icons.category,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Risk Factors',
            content:
                '• Hormonal problems\n• Pregnancy\n• Endometriosis\n• Severe pelvic infection\n• Previous ovarian cyst',
            icon: Icons.warning_amber,
          ),
          const SizedBox(height: 16),
          _buildInteractiveAnatomyImage(
            title: 'Basic Ovarian Anatomy',
            caption:
                'Basic ovarian anatomy showing normal ovary structure and a typical ovarian cyst',
            details:
                'Tap the highlighted regions to learn more about each part of the ovarian anatomy.',
            anatomyParts: [
              AnatomyPart(
                name: 'Ovary',
                description:
                    'The female reproductive organ that produces eggs and hormones. Each woman typically has two ovaries.',
                region: const Rect.fromLTWH(100, 150, 80, 60),
              ),
              AnatomyPart(
                name: 'Follicle',
                description:
                    'A fluid-filled sac containing a developing egg. During each menstrual cycle, several follicles begin to develop.',
                region: const Rect.fromLTWH(120, 170, 40, 40),
              ),
              AnatomyPart(
                name: 'Cyst',
                description:
                    'A fluid-filled sac that can develop on or inside the ovary. Most are harmless and disappear on their own.',
                region: const Rect.fromLTWH(160, 140, 60, 60),
              ),
              AnatomyPart(
                name: 'Fallopian Tube',
                description:
                    'The tube that carries eggs from the ovary to the uterus. Fertilization typically occurs here.',
                region: const Rect.fromLTWH(200, 160, 100, 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppStyles.headingMedium.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: AppStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveAnatomyImage({
    required String title,
    required String caption,
    required String details,
    required List<AnatomyPart> anatomyParts,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.headingMedium),
                const SizedBox(height: 8),
                Text(caption, style: AppStyles.bodyMedium),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    SvgPicture.asset(
                      'assets/images/education/cyst_anatomy_1.svg',
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    ...anatomyParts.map((part) {
                      return Positioned(
                        left: part.region.left,
                        top: part.region.top,
                        width: part.region.width,
                        height: part.region.height,
                        child: GestureDetector(
                          onTapDown: (details) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(part.name),
                                content: Text(part.description),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withAlpha((0.2 * 255).round()),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  details,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SymptomsTab extends StatelessWidget {
  const SymptomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSymptomCard(
            symptom: 'Pelvic Pain',
            description:
                'Pain that may be sharp or dull occurring on the side where the cyst is located.',
            severity: 'Varies from mild discomfort to severe pain',
            whenToSeekHelp:
                'If pain is sudden, severe, or accompanied by fever',
          ),
          const SizedBox(height: 16),
          _buildSymptomCard(
            symptom: 'Bloating or Swelling',
            description: 'Feeling of fullness or pressure in the abdomen.',
            severity: 'Usually mild to moderate',
            whenToSeekHelp: 'If severe or rapidly worsening',
          ),
          const SizedBox(height: 16),
          _buildSymptomCard(
            symptom: 'Irregular Periods',
            description:
                'Changes in menstrual cycle, spotting, or heavier/lighter periods than normal.',
            severity: 'Varies based on cyst type and size',
            whenToSeekHelp:
                'If bleeding is very heavy or periods stop completely',
          ),
          const SizedBox(height: 16),
          _buildWarningSection(),
        ],
      ),
    );
  }

  Widget _buildSymptomCard({
    required String symptom,
    required String description,
    required String severity,
    required String whenToSeekHelp,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              symptom,
              style: AppStyles.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(description, style: AppStyles.bodyMedium),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Severity:',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        severity,
                        style: AppStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'When to seek help:',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        whenToSeekHelp,
                        style: AppStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Warning Signs',
                style: AppStyles.headingMedium.copyWith(
                  color: Colors.red.shade700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Seek immediate medical attention if you experience:',
            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildWarningItem('Sudden, severe abdominal or pelvic pain'),
          _buildWarningItem('Pain with fever or vomiting'),
          _buildWarningItem('Dizziness, weakness, or rapid breathing'),
          _buildWarningItem(
            'Heavy menstrual bleeding or bleeding after menopause',
          ),
          const SizedBox(height: 12),
          Text(
            'These could indicate a ruptured cyst or other serious condition requiring immediate medical care.',
            style: AppStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppStyles.bodyMedium),
          Expanded(child: Text(text, style: AppStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class TreatmentTab extends StatelessWidget {
  const TreatmentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTreatmentCard(
            title: 'Watchful Waiting',
            description:
                'Many cysts go away on their own within a few months without treatment.',
            details:
                'Your doctor may recommend periodic ultrasounds to monitor the cyst for changes in size or appearance.',
            icon: Icons.remove_red_eye,
          ),
          const SizedBox(height: 16),
          _buildTreatmentCard(
            title: 'Medication',
            description:
                'Hormonal contraceptives (birth control pills) may be prescribed to prevent new cysts from forming.',
            details:
                'Pain relievers such as ibuprofen or acetaminophen can help manage discomfort associated with ovarian cysts.',
            icon: Icons.medication,
          ),
          const SizedBox(height: 16),
          _buildTreatmentCard(
            title: 'Surgery',
            description:
                'May be recommended if cysts are large, causing symptoms, or potentially cancerous.',
            details:
                'Types include:\n• Laparoscopy: Minimally invasive removal of the cyst\n• Laparotomy: Larger incision for larger cysts\n• Oophorectomy: Removal of affected ovary if necessary',
            icon: Icons.medical_services,
          ),
          const SizedBox(height: 16),
          _buildHolisticSection(),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard({
    required String title,
    required String description,
    required String details,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppStyles.headingMedium.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: AppStyles.bodyMedium),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(details, style: AppStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHolisticSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(51), // 0.2 * 255
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Holistic Approaches',
                style: AppStyles.headingMedium.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'While not replacements for medical treatment, some complementary approaches may help manage symptoms:',
            style: AppStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          _buildHolisticItem(
            'Heat therapy',
            'Applying a heating pad to the lower abdomen may help relieve pain.',
          ),
          _buildHolisticItem(
            'Regular exercise',
            'Moderate activity may help reduce pain and bloating.',
          ),
          _buildHolisticItem(
            'Stress management',
            'Practices like yoga or meditation can help reduce stress which may worsen symptoms.',
          ),
          _buildHolisticItem(
            'Anti-inflammatory diet',
            'Foods rich in omega-3 fatty acids, fruits, and vegetables may help reduce inflammation.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Always discuss complementary approaches with your healthcare provider before trying them.',
                    style: AppStyles.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolisticItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(description, style: AppStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NutritionTab extends StatelessWidget {
  const NutritionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(26), // 0.1 * 255
                    AppColors.accent.withAlpha(26), // 0.1 * 255
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nutrition Guidelines',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A balanced diet plays a crucial role in managing ovarian cysts and overall reproductive health.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildNutritionSection(
            'Recommended Foods',
            'Include these nutrient-rich foods in your daily diet:',
            [
              'Dark leafy greens (spinach, kale) - Rich in iron and antioxidants',
              'Fatty fish (salmon, mackerel) - High in omega-3 fatty acids',
              'Lean proteins (chicken, legumes, tofu) - Essential for healing',
              'Whole grains (quinoa, brown rice) - For sustained energy',
              'Nuts and seeds (almonds, flaxseeds) - Rich in healthy fats',
              'Colorful fruits (berries, citrus) - High in vitamins and antioxidants',
              'Probiotic foods (yogurt, kefir) - For gut health',
              'Green tea - Rich in antioxidants',
            ],
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 24),
          _buildNutritionSection(
            'Foods to Limit',
            'Minimize these foods to reduce inflammation and symptoms:',
            [
              'Processed foods - High in unhealthy fats and preservatives',
              'Sugary drinks and snacks - Can increase inflammation',
              'Caffeine - May worsen hormone imbalances',
              'Alcohol - Can affect hormone levels',
              'High-sodium foods - May increase bloating and water retention',
              'Red meat - Can increase inflammation',
              'Refined carbohydrates - May affect blood sugar levels',
            ],
            Icons.remove_circle,
            Colors.red,
          ),
          const SizedBox(height: 24),
          _buildNutritionSection(
            'Helpful Tips',
            'Maintain these healthy eating habits:',
            [
              'Eat small, frequent meals throughout the day',
              'Stay well hydrated with water and herbal teas',
              'Consider taking doctor-recommended supplements',
              'Plan your meals ahead to ensure balanced nutrition',
              'Listen to your body and identify trigger foods',
            ],
            Icons.lightbulb,
            AppColors.accent,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(
    String title,
    String subtitle,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26), // 0.1 * 255
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class ExerciseTab extends StatelessWidget {
  const ExerciseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Safe Exercise Guidelines',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildExerciseSection(
            'Recommended Activities',
            [
              ExerciseItem(
                title: 'Walking',
                description:
                    'Start with 10-15 minutes daily, gradually increase',
                icon: Icons.directions_walk,
              ),
              ExerciseItem(
                title: 'Swimming',
                description: 'Low-impact cardio, excellent for overall fitness',
                icon: Icons.pool,
              ),
              ExerciseItem(
                title: 'Yoga',
                description: 'Gentle stretching and stress relief',
                icon: Icons.self_improvement,
              ),
              ExerciseItem(
                title: 'Light Cycling',
                description:
                    'Stationary bike or outdoor cycling on flat terrain',
                icon: Icons.pedal_bike,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildWarningSection(),
        ],
      ),
    );
  }

  Widget _buildExerciseSection(String title, List<ExerciseItem> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...exercises.map((exercise) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        exercise.icon,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exercise.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Important Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Always consult your healthcare provider before starting any exercise routine. Stop any activity that causes pain or discomfort.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ExerciseItem {
  final String title;
  final String description;
  final IconData icon;

  const ExerciseItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class FAQTab extends StatelessWidget {
  const FAQTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildFAQItem(
          question: 'Can ovarian cysts cause infertility?',
          answer:
              'Most ovarian cysts do not affect fertility. However, certain types like endometriomas or those caused by polycystic ovary syndrome (PCOS) may impact fertility. If you\'re concerned about fertility, consult with a reproductive endocrinologist.',
        ),
        _buildFAQItem(
          question: 'How are ovarian cysts diagnosed?',
          answer:
              'Ovarian cysts are typically diagnosed through:\n• Pelvic examination\n• Ultrasound imaging\n• CT scan or MRI (for complex cases)\n• Blood tests to check for hormonal imbalances or cancer markers',
        ),
        _buildFAQItem(
          question: 'Do ovarian cysts cause weight gain?',
          answer:
              'Most ovarian cysts are too small to cause noticeable weight gain. However, very large cysts might create a sensation of bloating or fullness. If you experience unexplained weight gain, consult your doctor as it may be due to other causes.',
        ),
        _buildFAQItem(
          question: 'Can ovarian cysts become cancerous?',
          answer:
              'Most ovarian cysts are benign (non-cancerous) and disappear on their own. However, in rare cases, some types of cysts may be or become cancerous. Regular check-ups and monitoring are important, especially for postmenopausal women.',
        ),
        _buildFAQItem(
          question: 'Can I prevent ovarian cysts?',
          answer:
              'While you cannot prevent functional ovarian cysts entirely, regular pelvic examinations can help detect cysts early. Hormonal birth control may reduce the likelihood of developing new cysts.',
        ),
        _buildFAQItem(
          question: 'Will I need surgery for my ovarian cyst?',
          answer:
              'Surgery is typically recommended only if:\n• The cyst is very large (greater than 5-10 cm)\n• It doesn\'t go away after several menstrual cycles\n• It causes severe symptoms\n• There\'s concern it could be cancerous\nMost cysts can be monitored or treated with medication.',
        ),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        iconColor: AppColors.primary,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer, style: AppStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class AnatomyPart {
  final String name;
  final String description;
  final Rect region;

  const AnatomyPart({
    required this.name,
    required this.description,
    required this.region,
  });
}
