import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/utils/map_launcher_util.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/garage_location_model.dart';

class EstimationScreen extends StatelessWidget {
  final EstimationModel? estimation;

  const EstimationScreen({super.key, this.estimation});

  Future<void> _openGoogleMapsDirections(BuildContext context) async {
    try {
      final odooService = Provider.of<BaseOdooService>(context, listen: false);
      final compMap = await odooService.getCompanyLocationDetails();
      GarageLocation garage;
      if (compMap != null) {
        garage = GarageLocation.fromJson(compMap);
      } else {
        garage = const GarageLocation(
          id: '1',
          name: 'Timeless Detailing',
          address: '7 Crystal Crescent, Golden Crest Country Estate, Parkrand, Boksburg, 1459',
          phone: '',
          latitude: -25.933578,
          longitude: 28.18122,
        );
      }
      await MapLauncherUtil.openGoogleMapsDirections(garage);
    } catch (e) {
      debugPrint('Error getting company coordinates: $e');
      const fallbackGarage = GarageLocation(
        id: '1',
        name: 'Timeless Detailing',
        address: '7 Crystal Crescent, Golden Crest Country Estate, Parkrand, Boksburg, 1459',
        phone: '',
        latitude: -25.933578,
        longitude: 28.18122,
      );
      await MapLauncherUtil.openGoogleMapsDirections(fallbackGarage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = estimation ?? EstimationModel.defaultStatic();

    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F5F0,
      ), // Warm light cream background matching Figma
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
                  // Main Estimation Ticket Card (Top Dark, Bottom Light matching Figma)
                  _buildEstimateTicketCard(context, data),

                  const SizedBox(height: 16),

                  // Disclaimer notice
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      data.disclaimerText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        color: const Color(0xFF7E7667),
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

                  // Next steps timeline container (Dark Luxury Container)
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

  /// Two-tone ticket card matching Figma: Top Dark Price Box with Serrated teeth, Bottom White Details Box
  Widget _buildEstimateTicketCard(BuildContext context, EstimationModel data) {
    const darkBoxColor = Color(0xFF1D1813);
    const lightBoxColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: lightBoxColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEBE7E0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Dark Price Container
          Container(
            width: double.infinity,
            color: darkBoxColor,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Column(
              children: [
                // Gold Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A231C),
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
                const SizedBox(height: 12),

                // Subtitle description
                Text(
                  '${data.serviceDescription} only at',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFFC5B7A1),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),

                // Price
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

          // Sawtooth Ticket Serrated Edge Transition (Dark to Light)
          CustomPaint(
            size: const Size(double.infinity, 12),
            painter: SawtoothTicketPainter(
              darkColor: darkBoxColor,
              lightColor: lightBoxColor,
            ),
          ),

          // Bottom Light Details Container
          Container(
            width: double.infinity,
            color: lightBoxColor,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _buildLightDetailRow('Selected Car', data.vehicleName),
                const SizedBox(height: 12),
                _buildLightDetailRow('Car Type', data.vehicleType),
                const SizedBox(height: 12),
                _buildLightDetailRow('Service', data.serviceName),

                const SizedBox(height: 14),

                // Thin Dotted Divider Line
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                ),

                const SizedBox(height: 14),

                _buildLightDetailRow('Service Date', data.serviceDate),
                const SizedBox(height: 12),
                _buildLightDetailRow('Slot', data.serviceTime),

                const SizedBox(height: 22),

                // Get Directions to Garage Button
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
                          Icons.near_me_outlined,
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

  /// Light Detail Row with Grey Label left, Bold Dark Text right
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
              color: const Color(0xFF1C1C1E),
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
        color: const Color(0xFF1D1813),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B3227), width: 1),
      ),
      child: Column(
        children: List.generate(data.nextSteps.length, (index) {
          final step = data.nextSteps[index];
          final isLast = index == data.nextSteps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Step Number Circle with Vertical Connector Line
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A231C),
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
                          color: const Color(0xFFC4913F),
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 36,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF4A3E30),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Right Step Description Text
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 16),
                  child: Text(
                    step.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Custom painter to draw triangular sawtooth serrated ticket edge between dark top and light bottom
class SawtoothTicketPainter extends CustomPainter {
  final Color darkColor;
  final Color lightColor;

  SawtoothTicketPainter({required this.darkColor, required this.lightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    // Fill background with light color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    // Draw dark top portion with triangular sawtooth teeth at bottom
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - 10);

    const toothWidth = 22.0;
    const toothHeight = 8.0;
    final teethCount = (size.width / toothWidth).ceil();

    for (int i = 0; i < teethCount; i++) {
      final startX = i * toothWidth;
      final midX = startX + (toothWidth / 2);
      final endX = startX + toothWidth;
      path.lineTo(midX, size.height);
      path.lineTo(endX, size.height - toothHeight);
    }

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, darkPaint);
  }

  @override
  bool shouldRepaint(covariant SawtoothTicketPainter oldDelegate) {
    return oldDelegate.darkColor != darkColor ||
        oldDelegate.lightColor != lightColor;
  }
}

/// Custom painter for thin dashed line divider
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
