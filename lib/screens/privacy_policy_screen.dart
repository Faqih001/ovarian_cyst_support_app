import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: May 18, 2025',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Introduction'),
            _buildParagraph(
              'OvaCare is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and disclose information about you when you use our mobile application.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Information We Collect'),
            _buildParagraph(
              'We collect information you provide directly to us, such as when you create an account, update your profile, use the interactive features of our app, participate in surveys, contests, or promotions, seek customer support, or otherwise communicate with us.',
            ),
            _buildParagraph(
              'This information may include your name, email address, password, phone number, date of birth, health information including symptoms, medications, appointment details, and any other information you choose to provide.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'How We Use Your Information'),
            _buildParagraph(
              'We use the information we collect to provide, maintain, and improve our services, including to:',
            ),
            _buildBulletPoint('Provide and deliver the services you request'),
            _buildBulletPoint(
              'Send you technical notices and support messages',
            ),
            _buildBulletPoint('Respond to your comments and questions'),
            _buildBulletPoint('Personalize your experience'),
            _buildBulletPoint('Monitor and analyze trends and usage'),
            _buildBulletPoint('Develop new products and services'),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Data Security'),
            _buildParagraph(
              'We take reasonable measures to help protect your personal information from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Contact Us'),
            _buildParagraph(
              'If you have any questions about this Privacy Policy, please contact us at:',
            ),
            _buildParagraph('Email: privacy@ovacare.com'),
            _buildParagraph('Phone: +1 (555) 123-4567'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
