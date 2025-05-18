import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/onboarding_screen.dart';
import 'package:ovarian_cyst_support_app/screens/home_screen.dart';
import 'package:ovarian_cyst_support_app/screens/auth/login_screen.dart';
import 'package:ovarian_cyst_support_app/services/preferences_service.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

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

    // Check if onboarding is completed and auth status before navigating
    final authService = Provider.of<AuthService>(context, listen: false);
    Timer(const Duration(seconds: 3), () async {
      final bool onboardingComplete =
          await PreferencesService.isOnboardingComplete();

      if (mounted) {
        // If onboarding is not complete, show onboarding
        if (!onboardingComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
        // If user is already authenticated, go to home
        else if (authService.status == AuthStatus.authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        // Otherwise, go to login
        else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
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
