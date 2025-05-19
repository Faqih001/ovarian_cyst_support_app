import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/screens/auth/login_screen.dart';
import 'package:ovarian_cyst_support_app/services/preferences_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      image: 'assets/images/onboarding/welcome.svg',
      title: 'Welcome to OvaCare',
      description:
          'Your personal companion for ovarian cyst management, support, and education.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding/tracking.svg',
      title: 'Track Your Health',
      description:
          'Monitor symptoms, appointments, and medication with personalized tracking tools.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding/community.svg',
      title: 'Community Support',
      description:
          'Connect with others on similar journeys and access expert-backed resources.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboardingAndNavigate() async {
    await PreferencesService.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button - always visible
            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboardingAndNavigate,
                child: Text(
                  'Skip',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),

            // Main content
            Column(
              children: [
                const SizedBox(height: 60), // Space for skip button
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _numPages,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image
                            SvgPicture.asset(
                              _onboardingData[index].image,
                              height: MediaQuery.of(context).size.height * 0.3,
                            ),
                            const SizedBox(height: 32),
                            // Title
                            Text(
                              _onboardingData[index].title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // Description
                            Text(
                              _onboardingData[index].description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom section with page indicator and button
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Page indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _numPages,
                        effect: ExpandingDotsEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          spacing: 8,
                          activeDotColor: AppColors.primary,
                          dotColor: Color.fromRGBO(
                            AppColors.primary.r.toInt(),
                            AppColors.primary.g.toInt(),
                            AppColors.primary.b.toInt(),
                            0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Get Started button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _numPages - 1) {
                              _completeOnboardingAndNavigate();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == _numPages - 1
                                ? 'Get Started'
                                : 'Next',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
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
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
