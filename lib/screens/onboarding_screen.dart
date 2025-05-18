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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: 20,
              right: 20,
              child:
                  _currentPage < _numPages - 1
                      ? TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            _numPages - 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        },
                        child: Text(
                          'Skip',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      : const SizedBox(),
            ),

            // Content
            Column(
              children: [
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
                      return _buildOnboardingPage(
                        image: _onboardingData[index].image,
                        title: _onboardingData[index].title,
                        description: _onboardingData[index].description,
                      );
                    },
                  ),
                ),

                // Page indicator and buttons
                Container(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _numPages,
                        effect: WormEffect(
                          dotHeight: 10,
                          dotWidth: 10,
                          activeDotColor: AppColors.primary,
                          dotColor: AppColors.secondary,
                        ),
                      ),

                      // Next/Get Started button
                      ElevatedButton(
                        onPressed: () async {
                          if (_currentPage < _numPages - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.ease,
                            );
                          } else {
                            // Mark onboarding as completed
                            await PreferencesService.setOnboardingComplete();

                            // Store context before async gap
                            final currentContext = context;
                            
                            if (mounted) {
                              Navigator.of(currentContext).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          }
                        },
                        style: AppStyles.primaryButton,
                        child: Text(
                          _currentPage < _numPages - 1 ? 'Next' : 'Get Started',
                          style: AppStyles.buttonText,
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

  Widget _buildOnboardingPage({
    required String image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(image, width: 200, height: 200),
          const SizedBox(height: 40),
          Text(
            title,
            style: AppStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: AppStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
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
