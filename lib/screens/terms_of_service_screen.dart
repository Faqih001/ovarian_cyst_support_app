import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
            _buildSectionTitle(context, 'Acceptance of Terms'),
            _buildParagraph(
              'By accessing or using the OvaCare mobile application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Description of Service'),
            _buildParagraph(
              'OvaCare is a mobile application designed to help women with ovarian cysts manage their condition through symptom tracking, educational resources, community support, and healthcare coordination.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'User Accounts'),
            _buildParagraph(
              'You must create an account to use certain features of our service. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
            ),
            _buildParagraph(
              'You agree to provide accurate and complete information when creating your account and to update your information as necessary to keep it accurate and complete.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Medical Disclaimer'),
            _buildParagraph(
              'OvaCare is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
            ),
            _buildParagraph(
              'The content provided in this application is for informational purposes only and should not be considered medical advice.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'User Content'),
            _buildParagraph(
              'You retain all rights to any content you submit, post, or display on or through our service. By submitting, posting, or displaying content on our service, you grant us a worldwide, non-exclusive, royalty-free license to use, copy, reproduce, process, adapt, modify, publish, transmit, display, and distribute such content.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Termination'),
            _buildParagraph(
              'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Contact Us'),
            _buildParagraph(
              'If you have any questions about these Terms, please contact us at:',
            ),
            _buildParagraph('Email: terms@ovacare.com'),
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
}
