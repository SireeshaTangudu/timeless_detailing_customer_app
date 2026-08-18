import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/login_screen.dart';
import 'package:timeless_detailing_customer_app/core/utils/app_animations.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'Paint\nCorrection',
      description:
          'Paint Correction is the highest level of paint refinement available before repainting',
      imagePath: 'assets/images/onboarding_screen_1.png',
    ),
    OnboardingItem(
      title: 'Timeless Maintenance\nMemberships',
      description:
          'Our premier maintenance programme for owners who expect their vehicles to remain in exceptional condition all year',
      imagePath: 'assets/images/onboarding_screen_2.png',
    ),
    OnboardingItem(
      title: 'Protection',
      description:
          'Our premier maintenance programme for owners who expect their vehicles to remain in exceptional condition all year',
      imagePath: 'assets/images/onboarding_screen_3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pushReplacement(
        context,
        FadeSlidePageRoute(page: const LoginScreen()),
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen PageView for Background Images
          PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Detailing Photography Background Image
                  Image.asset(
                    _items[index].imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF141416),
                        child: const Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Color(0xFFC59B27),
                          ),
                        ),
                      );
                    },
                  ),

                  // Dark Cinematic Vignette Gradient Overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.black87,
                          Colors.black,
                        ],
                        stops: [0.0, 0.35, 0.70, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Header Bar: Back Button (left) & Skip (right)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back arrow circular button (visible on slide 1 & 2)
                  if (_currentIndex > 0)
                    AnimatedPressable(
                      onTap: _previousPage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),

                  // Skip >> Button
                  AnimatedPressable(
                    onTap: _finishOnboarding,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        'Skip >>',
                        style: GoogleFonts.poppins(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Content & Navigation Bar overlay
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Title & Description Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(_currentIndex),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.canela(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          height: 1.15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.description,
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.primary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Bottom Controls Row: Indicators (left) & Next Button (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Slide Indicator Pills
                    Row(
                      children: List.generate(
                        _items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: _currentIndex == index ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: _currentIndex == index
                                ? AppTheme.primary
                                : Colors.white38,
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started Gold Pill Button
                    AnimatedPressable(
                      onTap: _nextPage,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentIndex == _items.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF141416),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
