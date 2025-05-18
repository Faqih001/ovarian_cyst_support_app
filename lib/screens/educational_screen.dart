import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class EducationalScreen extends StatefulWidget {
  const EducationalScreen({super.key});

  @override
  State<EducationalScreen> createState() => _EducationalScreenState();
}

class _EducationalScreenState extends State<EducationalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Resources'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Basics'),
            Tab(text: 'Symptoms'),
            Tab(text: 'Treatment'),
            Tab(text: 'FAQ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [BasicsTab(), SymptomsTab(), TreatmentTab(), FAQTab()],
      ),
    );
  }
}

class BasicsTab extends StatelessWidget {
  const BasicsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
          _buildImageSection(
            title: 'Ovarian Cyst Anatomy',
            description:
                'Understanding the structure and location of ovarian cysts can help you better communicate with your healthcare provider.',
            imagePath: 'assets/images/education/cyst_anatomy.png',
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

  Widget _buildImageSection({
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyles.headingMedium.copyWith(fontSize: 18)),
        const SizedBox(height: 8),
        Text(description, style: AppStyles.bodyMedium),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200,
                color: AppColors.secondary.withAlpha((0.3 * 255).toInt()),
                child: const Center(
                  child: Text('Image will be displayed here'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SymptomsTab extends StatelessWidget {
  const SymptomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Severity: ',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(severity, style: AppStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'When to seek help: ',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(whenToSeekHelp, style: AppStyles.bodyMedium),
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
      padding: const EdgeInsets.all(16.0),
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
        color: AppColors.secondary.withAlpha((0.2 * 255).toInt()),
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
