import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/interior_detailing_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_detail_screen.dart';

class _AssetServiceImage extends StatefulWidget {
  final String assetPath;
  final Widget fallback;
  final Color backgroundColor;

  const _AssetServiceImage({
    required this.assetPath,
    required this.fallback,
    required this.backgroundColor,
  });

  @override
  State<_AssetServiceImage> createState() => _AssetServiceImageState();
}

class _AssetServiceImageState extends State<_AssetServiceImage> {
  late Future<Widget> _loader;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<Widget> _load() async {
    try {
      await rootBundle.load(widget.assetPath);
      return Image.asset(
        widget.assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => widget.fallback,
      );
    } catch (_) {
      return widget.fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }
        return Container(
          color: widget.backgroundColor,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final TabController tabController;

  const DashboardScreen({super.key, required this.tabController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  IconData _getServiceIcon(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('interior')) {
      return Icons.airline_seat_recline_extra_outlined;
    } else if (lower.contains('paint')) {
      return Icons.directions_car_outlined;
    } else if (lower.contains('protect')) {
      return Icons.shield_outlined;
    } else if (lower.contains('maintenance') || lower.contains('member')) {
      return Icons.calendar_month_outlined;
    }
    return Icons.auto_awesome_outlined;
  }

  Widget _buildServiceImage(DetailService service) {
    final assetPath = service.assetImagePath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return _AssetServiceImage(
        assetPath: assetPath,
        fallback: _buildFallbackIcon(service),
        backgroundColor: Colors.transparent,
      );
    }
    if (service.imageUrl.startsWith('http')) {
      return Image.network(
        service.imageUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(service),
      );
    }
    return _buildFallbackIcon(service);
  }

  Widget _buildFallbackIcon(DetailService service) {
    final icon = _getServiceIcon(service.name);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 28, color: AppTheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final servicesController = Provider.of<ServicesController>(context);
    final displayServices = servicesController.services;
    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: safeBottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Greeting on Left & Circular Menu Icon Button on Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hello ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF3A2F1E),
                            ),
                          ),
                          TextSpan(
                            text: auth.userName.isNotEmpty
                                ? auth.userName
                                : 'John Doe',
                            style: AppTypography.canela(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3A2F1E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Circular Menu Icon Button on Top Right (Opening Side Drawer)
                    GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFAB8C5A),
                            width: 1.2,
                          ),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.menu,
                          size: 20,
                          color: Color(0xFFAB8C5A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Welcome Subheading
                Text(
                  'Welcome to Timeless Detailing',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3A2F1E),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Main Display Headline: "What are you looking for today?"
                Text(
                  'What are you\nlooking for today?',
                  style: GoogleFonts.lora(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A2F1E),
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),

                // Cue Label: "Swipe to view all services »"
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Swipe to view all services',
                          style: GoogleFonts.lora(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Color(0xFF7A7A7E),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal Scrollable Cards View (aligned at screen bottom)
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayServices.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final item = displayServices[index];

                      return GestureDetector(
                        onTap: () {
                          if (item.name.toLowerCase().contains('interior')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const InteriorDetailingScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ServiceDetailScreen(service: item),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEBE7DF),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Service PNG image / icon placed at TOP of card (matching Figma 100x86)
                              Align(
                                alignment: Alignment.topRight,
                                child: SizedBox(
                                  width: 100,
                                  height: 86,
                                  child: _buildServiceImage(item),
                                ),
                              ),
                              const Spacer(),

                              // Service Title at the BOTTOM of the card (matching Figma)
                              Text(
                                item.name,
                                style: GoogleFonts.lora(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF3A2F1E),
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.left,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
