import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_detail_screen.dart';

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
    }
    return Icons.auto_awesome_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final servicesController = Provider.of<ServicesController>(context);
    final displayServices = servicesController.services;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: "Hello John Doe" & Circular Profile Icon Button
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
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                        TextSpan(
                          text: auth.userName.isNotEmpty ? auth.userName : 'John Doe',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Icon Button in Circular Border
                  GestureDetector(
                    onTap: () {
                      widget.tabController.animateTo(3); // Profile tab index
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E0D8),
                          width: 1.2,
                        ),
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Color(0xFFC4913F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Welcome Subheading
              Text(
                'Welcome to Timeless Detailing',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7A7A7E),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Main Display Headline: "What are you looking for today?"
              Text(
                'What are you\nlooking for today?',
                style: AppTypography.canela(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1C1E),
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 36),

              // Cue Label: "Swipe to view all services »"
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Swipe to view all services',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF7A7A7E),
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

              // Horizontal Scrollable Cards View
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayServices.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = displayServices[index];
                    final icon = _getServiceIcon(item.name);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceDetailScreen(service: item),
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(20),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Gold Outlined Line Icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFBF9F5),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                size: 30,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Service Title
                            Text(
                              item.name,
                              style: AppTypography.canela(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C1C1E),
                              ),
                              textAlign: TextAlign.center,
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
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
