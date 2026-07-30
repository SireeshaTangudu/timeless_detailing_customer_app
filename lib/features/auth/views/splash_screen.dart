import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/onboarding_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onSplashComplete;

  const SplashScreen({super.key, this.onSplashComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Trigger auth check concurrently during splash screen display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false).checkAuthStatus();
    });

    // Automatic navigation after splash animation duration
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;

      if (widget.onSplashComplete != null) {
        widget.onSplashComplete!();
        return;
      }

      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.isLoading) {
        // Give up to 1 second extra if auth check is finishing
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      if (auth.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScaffold(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Logo and Branding rendered from SVG
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // SVG Logo Image render
                          SvgPicture.asset(
                            'assets/svg/splash.svg',
                            width: 205,
                            height: 139,
                            placeholderBuilder: (BuildContext context) =>
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Tagline matching Figma design: "Elevating Automotive Perfection"
            Positioned(
              bottom: 40,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Elevating Automotive Perfection',
                  style: AppTypography.canela(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
