import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
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
import 'package:timeless_detailing_customer_app/features/bookings/views/bookings_history_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/upcoming_appointment_details_screen.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/live_tracking_screen.dart';

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
    const baseUrl = 'https://keerthan-lfi-lfi-timeless-detailing-uat-36441944.dev.odoo.com';

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
    final rawImgUrl = (service.mobileImage != null && service.mobileImage!.isNotEmpty)
        ? service.mobileImage
        : (service.imageUrl.isNotEmpty ? service.imageUrl : null);

    if (rawImgUrl != null && rawImgUrl.isNotEmpty) {
      final fullUrl = rawImgUrl.startsWith('http') ? rawImgUrl : '$baseUrl$rawImgUrl';
      return Image.network(
        fullUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) => _buildFallbackServiceAsset(service),
      );
    }

    // 3. Odoo REST image endpoint for product template
    if (service.odooProductId != null) {
      final odooImgUrl = '$baseUrl/web/image?model=product.template&id=${service.odooProductId}&field=mobile_image';
      return Image.network(
        odooImgUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) => _buildFallbackServiceAsset(service),
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
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        debugPrint('🔵 [DashboardScreen] Menu button clicked!');
                        if (widget.onMenuTap != null) {
                          widget.onMenuTap!();
                        } else {
                          try {
                            Scaffold.of(context).openDrawer();
                          } catch (e) {
                            debugPrint('Error opening drawer: $e');
                          }
                        }
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
                const SizedBox(height: 24),

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

                // Cue Label: "Swipe to view all categories »"
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Swipe to view all categories',
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

                // Horizontal Scrollable Cards View for Product Categories
                SizedBox(
                  height: 200,
                  child: (servicesController.isLoading &&
                          servicesController.productCategories.isEmpty)
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC4913F),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: servicesController.productCategories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final category =
                                servicesController.productCategories[index];
                            return _buildProductCategoryCard(
                              context,
                              category,
                              servicesController,
                            );
                          },
                        ),
                ),

                const SizedBox(height: 18),

                // Upcoming Appointment Card placed BELOW Services (matching Figma Image 1)
                Consumer<BookingsController>(
                  builder: (context, bookingsController, child) {
                    final upcoming = bookingsController.bookings;
                    if (upcoming.isEmpty) return const SizedBox.shrink();
                    final b = upcoming.first;
                    return _buildUpcomingAppointmentCard(context, b);
                  },
                ),
              ],
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

    final dateDayStr = DateFormat('d MMMM').format(booking.bookingDateTime);
    final timeStr = DateFormat('hh:mm a').format(booking.bookingDateTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121212),
            Color(0xFF22190C),
          ],
        ),
        borderRadius: BorderRadius.circular(8), // Figma Radius 8px
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
          // Title in Gold Serif (Figma)
          Text(
            isQuoteReceived ? 'New Quote Received' : 'Upcoming Appointment',
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFC4913F),
            ),
          ),
          const SizedBox(height: 8),

          // Line 4 Divider (Figma)
          const Divider(
            color: Color(0xFF332A1F),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 12),

          // Subtitle (Figma)
          Text(
            isQuoteReceived
                ? 'Based on our inspection, we\'ve share you the updated quote, please have a review.'
                : 'You have an appointment booked for $dateDayStr, $timeStr',
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9384),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // View Details Button at Bottom Right (Figma Filled Gold Button with White Text)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 38,
              child: ElevatedButton(
                onPressed: () {
                  if (isQuoteReceived) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NewEstimateScreen(bookingItem: booking),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UpcomingAppointmentDetailsScreen(booking: booking),
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
                  'View Details',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

  Widget _buildCategoryImage(ProductCategory category, String? assetImg, IconData iconData) {
    const baseUrl = 'https://keerthan-lfi-lfi-timeless-detailing-uat-36441944.dev.odoo.com';

    // 1. Base64 image string
    if (category.image != null &&
        category.image!.length > 100 &&
        !category.image!.startsWith('http')) {
      try {
        final bytes = base64Decode(category.image!);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {}
    }

    // 2. Relative or absolute image URL
    if (category.image != null && category.image!.isNotEmpty) {
      final fullUrl = category.image!.startsWith('http')
          ? category.image!
          : '$baseUrl${category.image}';
      return Image.network(
        fullUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackCategoryAsset(assetImg, iconData),
      );
    }

    // 3. Odoo web image REST endpoint for category model
    final odooCategoryUrl =
        '$baseUrl/web/image?model=timeless.product.category&id=${category.id}&field=image';
    return Image.network(
      odooCategoryUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _buildFallbackCategoryAsset(assetImg, iconData),
    );
  }

  Widget _buildFallbackCategoryAsset(String? assetImg, IconData iconData) {
    if (assetImg != null && assetImg.isNotEmpty) {
      return _AssetServiceImage(
        assetPath: assetImg,
        fallback: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, size: 28, color: AppTheme.primary),
        ),
        backgroundColor: Colors.transparent,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, size: 28, color: AppTheme.primary),
    );
  }

  Widget _buildProductCategoryCard(
    BuildContext context,
    ProductCategory category,
    ServicesController controller,
  ) {
    final lowerName = category.name.toLowerCase();
    String? assetImg;
    IconData iconData = Icons.auto_awesome_outlined;

    if (lowerName.contains('protection') || lowerName.contains('ppf')) {
      assetImg = 'assets/services/paint_care/paint_care.png';
      iconData = Icons.shield_outlined;
    } else if (lowerName.contains('paint') || lowerName.contains('care')) {
      assetImg = 'assets/services/paint_care/paint_care.png';
      iconData = Icons.directions_car_outlined;
    } else if (lowerName.contains('interior')) {
      assetImg = 'assets/services/interior/interior_detailing.png';
      iconData = Icons.airline_seat_recline_extra_outlined;
    } else if (lowerName.contains('maintenance')) {
      iconData = Icons.calendar_month_outlined;
    }

    return GestureDetector(
      onTap: () {
        controller.selectCategoryById(category.id, category.name);
        if (lowerName.contains('interior')) {
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
              builder: (context) => const ServicesListScreen(),
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
            // Category Image or Icon at top right (API response image with fallback)
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 100,
                height: 86,
                child: _buildCategoryImage(category, assetImg, iconData),
              ),
            ),
            const Spacer(),

            // Category Name
            Text(
              category.name,
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
