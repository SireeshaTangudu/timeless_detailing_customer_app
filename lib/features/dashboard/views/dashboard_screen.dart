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
import 'package:timeless_detailing_customer_app/features/services/views/interior_detailing_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_detail_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/bookings_history_screen.dart';

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

  const DashboardScreen({
    super.key,
    this.tabController,
    this.onMenuTap,
  });

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

                // Upcoming Appointment Card (if any active booking exists)
                Consumer<BookingsController>(
                  builder: (context, bookingsController, child) {
                    final upcoming = bookingsController.bookings;
                    if (upcoming.isEmpty) return const SizedBox.shrink();
                    final b = upcoming.first;
                    return _buildUpcomingAppointmentCard(context, b);
                  },
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

  Widget _buildUpcomingAppointmentCard(
    BuildContext context,
    Booking booking,
  ) {
    final serviceTitle = booking.service.name;
    final dateStr = DateFormat('d MMMM, yyyy').format(booking.bookingDateTime);
    final startStr = DateFormat('hh:mm a').format(booking.bookingDateTime);
    final stopStr = booking.stopDateTime != null
        ? DateFormat('hh:mm a').format(booking.stopDateTime!)
        : '01:00 PM';
    final timeStr = '$startStr - $stopStr';
    final priceStr = 'R ${booking.totalPrice.toStringAsFixed(0)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1813),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4CAF50),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 7,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'UPCOMING APPOINTMENT',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF81C784),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                priceStr,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC4913F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            serviceTitle,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Color(0xFFC5B7A1),
              ),
              const SizedBox(width: 6),
              Text(
                '$dateStr • $timeStr',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: const Color(0xFFC5B7A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancelAppointment(context, booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF5350),
                      side: const BorderSide(color: Color(0xFFE57373), width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewEstimateScreen(bookingItem: booking),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4913F),
                      foregroundColor: const Color(0xFF1C1C1E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      final controller = Provider.of<BookingsController>(context, listen: false);
      final bookingId = booking.odooSaleOrderId ?? int.tryParse(booking.id) ?? 20;
      final success = await controller.cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Appointment cancelled successfully'
                  : 'Failed to cancel appointment',
            ),
            backgroundColor:
                success ? const Color(0xFF1D1813) : const Color(0xFFB71C1C),
          ),
        );
      }
    }
  }
}
