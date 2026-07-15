import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/live_tracking_screen.dart';

class BookingsHistoryScreen extends StatelessWidget {
  const BookingsHistoryScreen({super.key});

  void _showBookingDetailsDialog(BuildContext context, Booking booking, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detailing Invoice Receipt',
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 12),
              
              // Invoice Order details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Reference:', style: theme.textTheme.bodyMedium),
                  Text('#SO-${booking.odooSaleOrderId ?? 000}', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Service Date:', style: theme.textTheme.bodyMedium),
                  Text(DateFormat('MMM dd, yyyy - hh:mm a').format(booking.bookingDateTime), style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vehicle:', style: theme.textTheme.bodyMedium),
                  Text('${booking.vehicleName} [${booking.vehicleLicensePlate}]', style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detailer Specialist:', style: theme.textTheme.bodyMedium),
                  Text(booking.technicianName, style: theme.textTheme.bodyLarge),
                ],
              ),
              
              const Divider(color: AppTheme.divider, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(booking.service.name, style: theme.textTheme.titleSmall),
                  Text('\$${booking.totalPrice.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Before After pictures grid
              if (booking.afterImages.isNotEmpty) ...[
                Text(
                  'Before & After Results',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.network(booking.beforeImages.first, height: 100, width: double.infinity, fit: BoxFit.cover),
                              Positioned(
                                bottom: 4, left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: Colors.black87,
                                  child: Text('BEFORE', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.network(booking.afterImages.first, height: 100, width: double.infinity, fit: BoxFit.cover),
                              Positioned(
                                bottom: 4, left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: AppTheme.primary,
                                  child: Text('AFTER', style: GoogleFonts.outfit(color: AppTheme.background, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DISMISS'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<BookingsController>(context);

    // Filter bookings
    final activeBookings = controller.bookings
        .where((b) => b.status != BookingStatus.completed)
        .toList();
    final completedBookings = controller.bookings
        .where((b) => b.status == BookingStatus.completed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BOOKING HISTORY',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 20),
            onPressed: () => controller.loadBookings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadBookings(),
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : controller.bookings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      const Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No Detailing Bookings Found',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Schedule your first appointment in the catalog.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Active detailing section
                      if (activeBookings.isNotEmpty) ...[
                        Text(
                          'Active Service & Scheduled Details',
                          style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.primary),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeBookings.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final booking = activeBookings[index];
                            return _buildBookingCard(context, booking, theme, true);
                          },
                        ),
                        const SizedBox(height: 28),
                      ],

                      // History detailing section
                      if (completedBookings.isNotEmpty) ...[
                        Text(
                          'Completed Services History',
                          style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: completedBookings.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final booking = completedBookings[index];
                            return _buildBookingCard(context, booking, theme, false);
                          },
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, ThemeData theme, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (isActive) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveTrackingScreen(booking: booking),
            ),
          );
        } else {
          _showBookingDetailsDialog(context, booking, theme);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primary.withOpacity(0.3) : AppTheme.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicleName,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.service.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isActive ? AppTheme.primaryLight : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? AppTheme.primary.withOpacity(0.2) : AppTheme.cardBorder,
                    ),
                  ),
                  child: Text(
                    booking.statusTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.divider, height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(booking.bookingDateTime),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  '\$${booking.totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
