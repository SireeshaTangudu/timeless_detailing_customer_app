import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:intl/intl.dart';
import 'package:timeless_detailing_customer_app/features/services/models/product_category_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/services_list_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/views/interior_detailing_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_detail_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/upcoming_appointment_details_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/estimation_screen.dart';
import 'package:timeless_detailing_customer_app/features/notifications/views/notifications_screen.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/core/utils/app_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
          color: Colors.transparent,
          child: const FourRotatingDotsLoader(size: 20),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final TabController? tabController;
  final VoidCallback? onMenuTap;

  const DashboardScreen({super.key, this.tabController, this.onMenuTap});

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
    final odooService = Provider.of<BaseOdooService>(context, listen: false);
    final baseUrl = odooService.baseUrl;

    // 1. Base64 mobileImage
    if (service.mobileImage != null &&
        service.mobileImage!.length > 100 &&
        !service.mobileImage!.startsWith('http')) {
      try {
        final bytes = base64Decode(service.mobileImage!);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {}
    }

    // 2. Relative / Absolute image URL from API response
    final rawImgUrl =
        (service.mobileImage != null && service.mobileImage!.isNotEmpty)
        ? service.mobileImage
        : (service.imageUrl.isNotEmpty ? service.imageUrl : null);

    if (rawImgUrl != null && rawImgUrl.isNotEmpty) {
      final fullUrl = rawImgUrl.startsWith('http')
          ? rawImgUrl
          : '$baseUrl$rawImgUrl';
      return Image.network(
        fullUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackServiceAsset(service),
      );
    }

    // 3. Odoo REST image endpoint for product template
    if (service.odooProductId != null) {
      final odooImgUrl =
          '$baseUrl/web/image?model=product.template&id=${service.odooProductId}&field=mobile_image';
      return Image.network(
        odooImgUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackServiceAsset(service),
      );
    }

    return _buildFallbackServiceAsset(service);
  }

  Widget _buildFallbackServiceAsset(DetailService service) {
    final assetPath = service.assetImagePath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return _AssetServiceImage(
        assetPath: assetPath,
        fallback: _buildFallbackIcon(service),
        backgroundColor: Colors.transparent,
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
    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;

    return FullPageLoadingOverlay(
      isLoading: servicesController.isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F7F4),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: const Color(0xFFC4913F),
            backgroundColor: Colors.white,
            onRefresh: () async {
              debugPrint(
                '🔄 Manual pull-to-refresh triggered on Home page! Fetching product categories...',
              );
              await servicesController.fetchProductCategories();
              if (context.mounted) {
                await Provider.of<BookingsController>(
                  context,
                  listen: false,
                ).loadBookings();
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: safeBottom + 24,
                      ),
                      child: Consumer<BookingsController>(
                        builder: (context, bookingsController, child) {
                          final upcoming = bookingsController.bookings;
                          final hasUpcoming = upcoming.isNotEmpty;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Section: Greeting Header & Headline
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 100),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Hello ',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: const Color(
                                                        0xFF3A2F1E,
                                                      ),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        auth.userName.isNotEmpty
                                                        ? auth.userName
                                                        : 'John Doe',
                                                    style: AppTypography.canela(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                        0xFF3A2F1E,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Top Right Action Buttons: Notifications Bell + Drawer Menu
                                            Row(
                                              children: [
                                                // Notifications Bell Icon Button
                                                AnimatedPressable(
                                                  onTap: () {
                                                    debugPrint(
                                                      '🔔 Notifications bell button tapped on Home page!',
                                                    );
                                                    Navigator.push(
                                                      context,
                                                      FadeSlidePageRoute(
                                                        page:
                                                            const NotificationsScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 38,
                                                    height: 38,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFAB8C5A,
                                                        ),
                                                        width: 1.2,
                                                      ),
                                                      color: Colors.white,
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons
                                                            .notifications_outlined,
                                                        color: Color(
                                                          0xFFAB8C5A,
                                                        ),
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Circular Menu Icon Button (Opening Side Drawer)
                                                AnimatedPressable(
                                                  onTap: () {
                                                    debugPrint(
                                                      '🔵 [DashboardScreen] Menu button clicked!',
                                                    );
                                                    if (widget.onMenuTap !=
                                                        null) {
                                                      widget.onMenuTap!();
                                                    } else {
                                                      try {
                                                        Scaffold.of(
                                                          context,
                                                        ).openDrawer();
                                                      } catch (e) {
                                                        debugPrint(
                                                          'Error opening drawer: $e',
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFAB8C5A,
                                                        ),
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
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 34),

                                  // Welcome Subheading & Headline
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 200),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Bottom Section: Swipe Cue, Cards, and Optional Upcoming Card
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cue Label: "Swipe to view all categories »" with repeating arrow nudge
                                    FadeSlideIn(
                                      delay: const Duration(milliseconds: 300),
                                      child: Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                            bottom: 12,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Swipe to view all categories',
                                                style: GoogleFonts.lora(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF000000,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                    Icons.double_arrow_rounded,
                                                    size: 14,
                                                    color: Color(0xFFC4913F),
                                                  )
                                                  .animate(
                                                    onPlay: (controller) =>
                                                        controller.repeat(),
                                                  )
                                                  .moveX(
                                                    begin: 0,
                                                    end: 4,
                                                    duration: 800.ms,
                                                    curve: Curves.easeInOut,
                                                  ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Horizontal Scrollable Cards View for Product Categories
                                    FadeSlideIn(
                                      delay: const Duration(milliseconds: 400),
                                      child: Transform.translate(
                                        offset: const Offset(-24, 0),
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.width,
                                          height: 220,
                                          child:
                                              (servicesController.isLoading &&
                                                  servicesController
                                                      .productCategories
                                                      .isEmpty)
                                              ? const FourRotatingDotsLoader()
                                              : ListView.separated(
                                                  clipBehavior: Clip.none,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                      ),
                                                  itemCount:
                                                      servicesController
                                                          .productCategories
                                                          .length,
                                                  separatorBuilder: (
                                                    context,
                                                    index,
                                                  ) => const SizedBox(width: 16),
                                                  itemBuilder: (context, index) {
                                                    final category =
                                                        servicesController
                                                            .productCategories[index];
                                                    return FadeSlideIn(
                                                      delay: Duration(
                                                        milliseconds:
                                                            400 + (index * 80),
                                                      ),
                                                      slideOffset:
                                                          const Offset(0.15, 0),
                                                      child:
                                                          _buildProductCategoryCard(
                                                            context,
                                                            category,
                                                            servicesController,
                                                            width: 160.0,
                                                          ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                    ),

                                    if (hasUpcoming) ...[
                                      const SizedBox(height: 18),
                                      // Upcoming Appointment Card placed BELOW Services
                                      FadeSlideIn(
                                        delay: const Duration(
                                          milliseconds: 500,
                                        ),
                                        child: _buildUpcomingAppointmentCard(
                                          context,
                                          upcoming.first,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context, Booking booking) {
    final bool isQuoteReceived =
        booking.status == BookingStatus.received ||
        booking.notes.toLowerCase().contains('quote') ||
        booking.notes.toLowerCase().contains('estimate');

    final bool isDraft =
        booking.status == BookingStatus.confirmed &&
        (booking.notes.toLowerCase().contains('draft') ||
            booking.notes.toLowerCase().contains('inspection'));

    final bool isAccepted =
        booking.status == BookingStatus.completed ||
        booking.notes.toLowerCase().contains('accepted') ||
        booking.notes.toLowerCase().contains('signed');

    final dateDayStr = DateFormat('d MMMM').format(booking.bookingDateTime);
    final timeStr = DateFormat('hh:mm a').format(booking.bookingDateTime);

    String stageTitle = 'Upcoming Appointment';
    String stageSubtitle =
        'You have an appointment booked for $dateDayStr, $timeStr';
    String buttonText = 'View Details';
    Color badgeColor = const Color(0xFFC4913F);

    final bool isDownPaymentInvoice =
        booking.isDownPaymentInvoice ||
        booking.notes.toLowerCase().contains('invoice') ||
        booking.notes.toLowerCase().contains('down payment');

    if (isDownPaymentInvoice) {
      stageTitle = 'Down Payment Invoice Received';
      stageSubtitle =
          'Down payment invoice generated for ${booking.service.name}. Tap to view breakdown and pay balance.';
      buttonText = 'Pay Balance';
      badgeColor = const Color(0xFFC4913F);
    } else if (isQuoteReceived) {
      stageTitle = 'New Quote Received';
      stageSubtitle =
          'Our technician completed inspection and updated your quote for ${booking.service.name}. Tap to review & accept.';
      buttonText = 'Review & Accept';
      badgeColor = const Color(0xFFC4913F);
    } else if (isDraft) {
      stageTitle = 'Draft Estimate Created';
      stageSubtitle =
          'Base estimate generated. Technician inspection scheduled for $dateDayStr, $timeStr.';
      buttonText = 'View Draft Estimate';
      badgeColor = const Color(0xFFF57F17);
    } else if (isAccepted) {
      stageTitle = 'Quotation Accepted & Signed';
      stageSubtitle =
          'Your estimate is confirmed and signed. Detailing appointment set for $dateDayStr at $timeStr.';
      buttonText = 'View Details';
      badgeColor = const Color(0xFF2E7D32);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF121212), Color(0xFF22190C)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Pulsing Glow Dot and Stage Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PulseGlow(
                    child: Icon(Icons.circle, size: 8, color: badgeColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stageTitle,
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isDownPaymentInvoice
                      ? 'INVOICE READY'
                      : isQuoteReceived
                      ? 'ACTION REQUIRED'
                      : isDraft
                      ? 'PENDING INSPECTION'
                      : 'CONFIRMED',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Divider
          const Divider(color: Color(0xFF332A1F), height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Stage Subtitle
          Text(
            stageSubtitle,
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9384),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Stage Action Button
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 38,
              child: AnimatedPressable(
                onTap: null,
                child: ElevatedButton(
                  onPressed: () {
                    if (isDownPaymentInvoice) {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(
                          page: UpcomingAppointmentDetailsScreen(
                            booking: booking,
                            isDownPaymentInvoice: true,
                          ),
                        ),
                      );
                    } else if (isQuoteReceived || isDraft) {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(
                          page: EstimationScreen(
                            estimation: EstimationModel.fromBooking(
                              booking,
                              isDraft: isDraft,
                            ),
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(
                          page: UpcomingAppointmentDetailsScreen(
                            booking: booking,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4913F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelAppointment(
    BuildContext context,
    Booking booking,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9F7F4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Appointment?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel "${booking.service.name}"? This will trigger calendar.event/action_cancel_meeting.',
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, Keep It',
              style: GoogleFonts.montserrat(color: const Color(0xFF7A7A7E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = Provider.of<BookingsController>(
        context,
        listen: false,
      );
      final bookingId =
          booking.odooSaleOrderId ?? int.tryParse(booking.id) ?? 20;
      final success = await controller.cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Appointment cancelled successfully'
                  : 'Failed to cancel appointment',
            ),
            backgroundColor: success
                ? const Color(0xFF1D1813)
                : const Color(0xFFB71C1C),
          ),
        );
      }
    }
  }

  Widget _buildCategoryFullBleedImage(ProductCategory category) {
    final odooService = Provider.of<BaseOdooService>(context, listen: false);
    final baseUrl = odooService.baseUrl;

    // 1. Base64 image string from Odoo
    if (category.image != null &&
        category.image!.length > 100 &&
        !category.image!.startsWith('http')) {
      try {
        final bytes = base64Decode(category.image!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {}
    }

    // 2. Relative or absolute image URL from Odoo
    if (category.image != null && category.image!.isNotEmpty) {
      final fullUrl = category.image!.startsWith('http')
          ? category.image!
          : '$baseUrl${category.image}';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildCategoryFallbackImage(category),
      );
    }

    // 3. Odoo web image REST endpoint for category model
    final odooCategoryUrl =
        '$baseUrl/web/image?model=timeless.product.category&id=${category.id}&field=image';
    return Image.network(
      odooCategoryUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          _buildCategoryFallbackImage(category),
    );
  }

  Widget _buildCategoryFallbackImage(ProductCategory category) {
    final lowerName = category.name.toLowerCase();

    if (lowerName.contains('interior')) {
      return Image.asset(
        'assets/services/interior/interior_detailing.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildDarkFallbackIcon(Icons.airline_seat_recline_extra_outlined),
      );
    } else if (lowerName.contains('paint')) {
      return Image.asset(
        'assets/services/paint_care/paint_care.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildDarkFallbackIcon(Icons.directions_car_outlined),
      );
    }

    return _buildDarkFallbackIcon(Icons.auto_awesome_outlined);
  }

  Widget _buildDarkFallbackIcon(IconData icon) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1D1813),
      child: Center(
        child: Icon(icon, size: 36, color: const Color(0xFFC4913F)),
      ),
    );
  }

  Widget _buildProductCategoryCard(
    BuildContext context,
    ProductCategory category,
    ServicesController controller, {
    double? width,
  }) {
    final lowerName = category.name.toLowerCase();
    final cardWidth = width ?? 150.0;

    return AnimatedPressable(
      onTap: () {
        controller.selectCategoryById(category.id, category.name);
        if (lowerName.contains('interior')) {
          Navigator.push(
            context,
            FadeSlidePageRoute(page: const InteriorDetailingScreen()),
          );
        } else {
          Navigator.push(
            context,
            FadeSlidePageRoute(page: const ServicesListScreen()),
          );
        }
      },
      child: Container(
        width: cardWidth,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Full-bleed Category Image from Odoo / Fallback
            Positioned.fill(child: _buildCategoryFullBleedImage(category)),

            // 2. Bottom Dark Gradient Overlay matching Figma
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(
                        0xCC000000,
                      ), // Dark gradient for white text legibility
                    ],
                  ),
                ),
              ),
            ),

            // 3. Category Name at Bottom-Left matching Figma
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: Text(
                category.name,
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, DetailService item) {
    return GestureDetector(
      onTap: () {
        if (item.name.toLowerCase().contains('interior')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InteriorDetailingScreen(),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(service: item),
            ),
          );
        }
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBE7DF), width: 1),
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
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 100,
                height: 86,
                child: _buildServiceImage(item),
              ),
            ),
            const Spacer(),
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
  }
}
