import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              'Acceptance of Terms',
              'By accessing and using OvaCare, you agree to be bound by these Terms of Service.',
            ),
            _buildSection(
              context,
              'User Registration',
              'Users must provide accurate and complete information during registration. You are responsible for maintaining the confidentiality of your account.',
            ),
            _buildSection(
              context,
              'Medical Disclaimer',
              'OvaCare is not a substitute for professional medical advice. Always consult with qualified healthcare providers for medical decisions.',
            ),
            _buildSection(
              context,
              'User Content',
              'By posting content, you grant OvaCare a non-exclusive license to use, modify, and display that content.',
            ),
            _buildSection(
              context,
              'Privacy',
              'Your use of OvaCare is also governed by our Privacy Policy.',
            ),
            _buildSection(
              context,
              'Termination',
              'We reserve the right to terminate or suspend access to our service immediately, without prior notice or liability.',
            ),
            _buildSection(
              context,
              'Changes to Terms',
              'We reserve the right to modify or replace these terms at any time. Users will be notified of any changes.',
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
