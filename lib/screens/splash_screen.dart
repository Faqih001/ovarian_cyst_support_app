import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/onboarding_screen.dart';
import 'package:ovarian_cyst_support_app/services/migration_service.dart';
import 'package:logger/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    try {
      // Wait for animation and loading
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check if migration is needed before navigation
      await MigrationService.checkAndShowMigrationScreen(context);

      _logger.i('Migration check completed');

      if (!mounted) return;

      // Navigate to onboarding screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } catch (e) {
      _logger.e('Error during splash navigation: $e');

      if (!mounted) return;

      // Fall back to onboarding screen in case of error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo with Lottie animation
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha((0.2 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Lottie.asset(
                    'assets/animations/heart_pulse.json',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 30),

                // App name
                Text(
                  'OvaCare',
                  style: AppStyles.headingLarge.copyWith(
                    color: AppColors.primary,
                    fontSize: 36,
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Support & Care for Ovarian Health',
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
