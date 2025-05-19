import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Get navigator before any async operations
    if (!mounted) return;
    final navigator = Navigator.of(context);

    // Wait for animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingComplete =
          await PreferencesService.isOnboardingComplete();
      final bool hasCreatedAccount =
          prefs.getBool('has_created_account') ?? false;

      if (!mounted) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      Widget nextScreen;

      if (!onboardingComplete || !hasCreatedAccount) {
        nextScreen = const OnboardingScreen();
      } else if (authService.status == AuthStatus.authenticated) {
        nextScreen = const HomeScreen();
      } else {
        nextScreen = const LoginScreen();
      }

      // Final mounted check before navigation
      if (!mounted) return;

      await navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } catch (e) {
      // Handle any errors during navigation setup
      if (!mounted) return;

      await navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
