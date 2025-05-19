import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Last updated: May 19, 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Information We Collect',
              'We collect information that you provide directly to us, including personal information such as name, email address, and health-related data you choose to share.',
            ),
            _buildSection(
              context,
              'How We Use Your Information',
              'We use the information we collect to provide and improve our services, personalize your experience, and communicate with you.',
            ),
            _buildSection(
              context,
              'Data Storage and Security',
              'We implement appropriate security measures to protect your personal information. Your data is stored securely in compliance with applicable data protection laws.',
            ),
            _buildSection(
              context,
              'Information Sharing',
              'We do not sell or share your personal information with third parties except as described in this policy or with your consent.',
            ),
            _buildSection(
              context,
              'Your Rights',
              'You have the right to access, update, or delete your personal information. You can also opt out of certain data collection and use.',
            ),
            _buildSection(
              context,
              'Data Retention',
              'We retain your information for as long as necessary to provide our services and comply with legal obligations.',
            ),
            _buildSection(
              context,
              'Children\'s Privacy',
              'Our service is not directed to children under 13. We do not knowingly collect information from children under 13.',
            ),
            _buildSection(
              context,
              'Changes to Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
