import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/widgets/sawtooth_ticket_painter.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/live_tracking_screen.dart';

class UpcomingAppointmentDetailsScreen extends StatefulWidget {
  final Booking booking;

  const UpcomingAppointmentDetailsScreen({super.key, required this.booking});

  @override
  State<UpcomingAppointmentDetailsScreen> createState() =>
      _UpcomingAppointmentDetailsScreenState();
}

class _UpcomingAppointmentDetailsScreenState
    extends State<UpcomingAppointmentDetailsScreen> {
  Future<void> _openDirections() async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Timeless+Detailing+Garage',
    );
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Timeless Detailing garage location...'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timeless Detailing Garage Location'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _confirmCancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Appointment?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to cancel your appointment for "${widget.booking.service.name}"?',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF555555),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'No, Keep It',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF8C8273),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
          widget.booking.odooSaleOrderId ??
          int.tryParse(widget.booking.id) ??
          20;
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
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final String serviceTitle = b.service.name;
    final String priceStr = 'R ${b.totalPrice.toStringAsFixed(0)}';
    final String selectedCar = b.vehicleName.isNotEmpty
        ? b.vehicleName
        : 'Client Vehicle';
    final String carType = b.vehicleModel.isNotEmpty
        ? b.vehicleModel
        : 'Hatch Back';
    final String dateDayStr = DateFormat('d MMMM').format(b.bookingDateTime);
    final String fullDateStr = DateFormat(
      'd MMMM, yyyy',
    ).format(b.bookingDateTime);
    final String slotTimeStr = DateFormat('hh:mm a').format(b.bookingDateTime);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Upcoming Appointment Details',
            onBackPressed: () => Navigator.pop(context),
            titleStyle: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3A2F1E),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Two-tone saw-tooth ticket card matching NewEstimateScreen & Figma
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEBE7E0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Top Dark Price Header
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF1D1813),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A231C),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFC4913F).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.cleaning_services_outlined,
                                    color: Color(0xFFC4913F),
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Estimated cost for your $serviceTitle service',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: const Color(0xFFC5B7A1),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                priceStr,
                                style: GoogleFonts.outfit(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sawtooth Ticket Serrated Teeth Transition
                        CustomPaint(
                          size: const Size(double.infinity, 12),
                          painter: SawtoothTicketPainter(
                            darkColor: const Color(0xFF1D1813),
                            lightColor: Colors.white,
                          ),
                        ),

                        // Bottom Light Details Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildLightDetailRow('Selected Car', selectedCar),
                              const SizedBox(height: 12),
                              _buildLightDetailRow('Car Type', carType),
                              const SizedBox(height: 12),
                              _buildLightDetailRow('Service', serviceTitle),
                              const SizedBox(height: 14),

                              // Dashed Divider Line
                              CustomPaint(
                                size: const Size(double.infinity, 1),
                                painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                              ),

                              const SizedBox(height: 14),
                              _buildLightDetailRow('Service Date', fullDateStr),
                              const SizedBox(height: 12),
                              _buildLightDetailRow('Slot', slotTimeStr),

                              const SizedBox(height: 20),

                              // Button: Get Directions to Garage
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _openDirections,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE8DBCA),
                                    foregroundColor: const Color(0xFF1D1813),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Color(0xFF1D1813),
                                  ),
                                  label: Text(
                                    'Get Directions to Garage',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Explanatory note below dark card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'The above mentioned amount is the base price. We will share the final pricing after completing our inspection on $dateDayStr at $slotTimeStr.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        color: const Color(0xFF7A7063),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timeline Card: "What will happen next" (Figma Screen 2)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1813),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What will happen next',
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        _buildTimelineStep(
                          1,
                          'Book your slot with us',
                          isDone: true,
                        ),
                        _buildTimelineStep(
                          2,
                          'Inspection of your car on the booked slot',
                          isCurrent: true,
                        ),
                        _buildTimelineStep(
                          3,
                          'New quote with the updated amount post inspection',
                        ),
                        _buildTimelineStep(4, 'Accept the quote'),
                        _buildTimelineStep(
                          5,
                          'Get your car serviced!',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _confirmCancelAppointment,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB71C1C),
                              side: const BorderSide(
                                color: Color(0xFFE57373),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LiveTrackingScreen(booking: b),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC4913F),
                              foregroundColor: const Color(0xFF1D1813),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.radar_outlined, size: 16),
                            label: Text(
                              'Track Live',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF8C8273),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: const Color(0xFF1C1C1E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    int stepNumber,
    String text, {
    bool isDone = false,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isCurrent
                      ? const Color(0xFFC4913F)
                      : Colors.transparent,
                  border: Border.all(
                    color: isDone || isCurrent
                        ? const Color(0xFFC4913F)
                        : const Color(0xFF554A3D),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDone || isCurrent
                          ? const Color(0xFF1D1813)
                          : const Color(0xFF8C8273),
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isDone
                        ? const Color(0xFFC4913F)
                        : const Color(0xFF443A2F),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: isDone || isCurrent
                      ? FontWeight.bold
                      : FontWeight.w400,
                  color: isDone || isCurrent
                      ? Colors.white
                      : const Color(0xFF8C8273),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
