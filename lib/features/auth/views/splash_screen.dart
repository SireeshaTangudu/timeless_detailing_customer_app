import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/onboarding_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/core/utils/app_animations.dart';

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

  Future<void>? _authFuture;

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

    final auth = Provider.of<AuthController>(context, listen: false);
    _authFuture = auth.checkAuthStatus();

    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    const minSplashDuration = Duration(milliseconds: 2200);
    final minSplashFuture = Future.delayed(minSplashDuration);

    await Future.wait([
      minSplashFuture,
      _authFuture ?? Future.value(false),
    ]);

    if (!mounted) return;

    if (widget.onSplashComplete != null) {
      widget.onSplashComplete!();
      return;
    }

    final auth = Provider.of<AuthController>(context, listen: false);

    int retries = 0;
    while (auth.isLoading && retries < 40) {
      await Future.delayed(const Duration(milliseconds: 150));
      retries++;
    }

    if (!mounted) return;

    // Check if user is logged in (either via auth status or saved session profile)
    if (auth.isAuthenticated || auth.userProfile != null) {
      Navigator.pushReplacement(
        context,
        FadeSlidePageRoute(page: const MainNavigationScaffold()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        FadeSlidePageRoute(page: const OnboardingScreen()),
      );
    }
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
                                const FourRotatingDotsLoader(size: 30),
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
