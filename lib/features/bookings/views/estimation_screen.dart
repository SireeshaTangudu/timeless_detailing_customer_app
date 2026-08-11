import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';

class EstimationScreen extends StatelessWidget {
  final EstimationModel? estimation;

  const EstimationScreen({
    super.key,
    this.estimation,
  });

  Future<void> _openGoogleMapsDirections(BuildContext context) async {
    const String queryLocation = 'Durgam Cheruvu, Hyderabad';
    const double garageLat = 17.4399;
    const double garageLng = 78.3846;

    // 1. Android geo intent: opens Google Maps app in Place Pin view (Image 1)
    final Uri geoUri = Uri.parse(
      'geo:$garageLat,$garageLng?q=${Uri.encodeComponent(queryLocation)}',
    );

    // 2. Google Maps Place Search URL: opens place card showing [ Directions ], [ Start ], [ Share ] (Image 1)
    final Uri googleMapsSearchUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(queryLocation)}',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      if (await canLaunchUrl(googleMapsSearchUrl)) {
        await launchUrl(
          googleMapsSearchUrl,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      await launchUrl(
        googleMapsSearchUrl,
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      debugPrint('Could not launch Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to static default data matching Figma if no estimate passed
    final data = estimation ?? EstimationModel.defaultStatic();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Your Estimate',
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Estimation Ticket Card
                  _buildEstimateTicketCard(context, data),

                  const SizedBox(height: 14),

                  // Disclaimer notice
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      data.disclaimerText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF7E786D),
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section Title: What will happen next
                  Text(
                    'What will happen next',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1E),
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Next steps timeline container
                  _buildNextStepsCard(context, data),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dark luxury ticket card with top price display, serrated edge, details, and direction button
  Widget _buildEstimateTicketCard(BuildContext context, EstimationModel data) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A16), // Dark luxury background matching Figma
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF3B3227),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Top Price Header Box
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Column(
              children: [
                // Top Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C241B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC4913F).withValues(alpha: 0.4),
                      width: 1,
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
                const SizedBox(height: 14),

                // Description text
                Text(
                  '${data.serviceDescription} only at',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: const Color(0xFFBCAE9B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),

                // Price display
                Text(
                  data.formattedPrice,
                  style: GoogleFonts.outfit(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Ticket serrated divider edge
          CustomPaint(
            size: const Size(double.infinity, 16),
            painter: TicketSerratedPainter(
              color: const Color(0xFF1E1A16),
              borderColor: const Color(0xFF3B3227),
            ),
          ),

          // Details List Box
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _buildDetailRow('Selected Car', data.vehicleName),
                const SizedBox(height: 12),
                _buildDetailRow('Car Type', data.vehicleType),
                const SizedBox(height: 12),
                _buildDetailRow('Service', data.serviceName),
                const SizedBox(height: 12),
                _buildDetailRow('Service Date', data.serviceDate),
                const SizedBox(height: 12),
                _buildDetailRow('Time', data.serviceTime),
                const SizedBox(height: 22),

                // Button: Get Directions to Garage
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _openGoogleMapsDirections(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4913F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Get Directions to Garage',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF9E9484),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Timeline section showing 5 sequential steps inside dark luxury container
  Widget _buildNextStepsCard(BuildContext context, EstimationModel data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B3227),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(data.nextSteps.length, (index) {
          final step = data.nextSteps[index];
          final isLast = index == data.nextSteps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Number Circle & Connecting Vertical Line
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isCompleted
                            ? const Color(0xFFC4913F)
                            : Colors.transparent,
                        border: Border.all(
                          color: const Color(0xFFC4913F),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${step.stepNumber}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: step.isCompleted
                                ? Colors.white
                                : const Color(0xFFC4913F),
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: const Color(0xFF4A3F31),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Step Title Text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    child: Text(
                      step.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Custom painter to draw scalloped / ticket serrated edge with side cutouts matching Figma ticket design
class TicketSerratedPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  TicketSerratedPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dashPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Side semicircular cutouts (left and right)
    const radius = 8.0;
    
    // Left notch
    path.moveTo(0, 0);
    path.arcToPoint(
      Offset(0, size.height),
      radius: const Radius.circular(radius),
      clockwise: true,
    );

    // Bottom line across
    path.lineTo(size.width, size.height);

    // Right notch
    path.arcToPoint(
      Offset(size.width, 0),
      radius: const Radius.circular(radius),
      clockwise: true,
    );

    // Top line back
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Draw dashed separator line in middle of ticket divider
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = radius + 4;
    final endX = size.width - radius - 4;
    final y = size.height / 2;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(startX, endX), y),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TicketSerratedPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
