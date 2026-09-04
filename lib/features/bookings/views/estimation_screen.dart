import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/utils/map_launcher_util.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/garage_location_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';

class EstimationScreen extends StatefulWidget {
  final EstimationModel? estimation;

  const EstimationScreen({super.key, this.estimation});

  @override
  State<EstimationScreen> createState() => _EstimationScreenState();
}

class _EstimationScreenState extends State<EstimationScreen> {
  String _status = 'pending'; // 'pending', 'accepted', 'declined'

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
          address:
              '7 Crystal Crescent, Golden Crest Country Estate, Parkrand, Boksburg, 1459',
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
        address:
            '7 Crystal Crescent, Golden Crest Country Estate, Parkrand, Boksburg, 1459',
        phone: '',
        latitude: -25.933578,
        longitude: 28.18122,
      );
      await MapLauncherUtil.openGoogleMapsDirections(fallbackGarage);
    }
  }

  void _showAcceptAndSignModal(BuildContext context, EstimationModel data) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final initialName = authController.userName != 'Guest Customer'
        ? authController.userName
        : '';
    final nameController = TextEditingController(text: initialName);
    final GlobalKey<_SignaturePadWidgetState> signatureKey =
        GlobalKey<_SignaturePadWidgetState>();

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1D1813),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3E30),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Title & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accept & Sign Estimate',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close, color: Color(0xFF8C8273)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please verify your name and draw your signature below to approve quotation #${data.id}.',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      color: const Color(0xFFC5B7A1),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name Label & Input
                  Text(
                    'Full Name',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC4913F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      hintStyle: GoogleFonts.montserrat(
                        color: const Color(0xFF7A7063),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A231C),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF4A3E30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC4913F)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Signature Pad Label & Clear Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Digital Signature',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC4913F),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => signatureKey.currentState?.clear(),
                        icon: const Icon(
                          Icons.clear,
                          size: 14,
                          color: Color(0xFF8C8273),
                        ),
                        label: Text(
                          'Clear',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF8C8273),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Signature Pad Canvas Widget
                  SignaturePadWidget(key: signatureKey),

                  const SizedBox(height: 24),

                  // Action Buttons: Accept & Decline
                  if (isSubmitting)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC4913F),
                      ),
                    )
                  else
                    Row(
                      children: [
                        // Decline Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () async {
                                final nav = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                setModalState(() => isSubmitting = true);
                                try {
                                  final odooService =
                                      Provider.of<BaseOdooService>(
                                        context,
                                        listen: false,
                                      );
                                  final orderId =
                                      int.tryParse(
                                        data.id.replaceAll(
                                          RegExp(r'[^\d]'),
                                          '',
                                        ),
                                      ) ??
                                      23;
                                  final partnerId =
                                      odooService.currentPartnerId ??
                                      odooService.currentUid ??
                                      28;
                                  await odooService.cancelBooking(
                                    bookingId: orderId,
                                    partnerIds: [partnerId],
                                  );
                                } catch (_) {}
                                if (mounted) {
                                  setState(() => _status = 'declined');
                                  nav.pop();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Quotation declined.'),
                                      backgroundColor: Color(0xFFB71C1C),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Decline',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE57373),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Accept Button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter your full name.',
                                      ),
                                      backgroundColor: Color(0xFFB71C1C),
                                    ),
                                  );
                                  return;
                                }

                                final nav = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                final odooService =
                                    Provider.of<BaseOdooService>(
                                      context,
                                      listen: false,
                                    );

                                setModalState(() => isSubmitting = true);
                                bool isSuccess = false;
                                try {
                                  final sigB64 = await signatureKey.currentState
                                      ?.toBase64Png();
                                  final orderId = data.odooSaleOrderId ??
                                      int.tryParse(
                                        data.id.replaceAll(
                                          RegExp(r'[^\d]'),
                                          '',
                                        ),
                                      );
                                  if (orderId == null || orderId <= 0) {
                                    throw Exception('Dynamic quotation ID missing or invalid.');
                                  }
                                  isSuccess = await odooService.acceptQuotation(
                                    orderId: orderId,
                                    name: name,
                                    signatureBase64: sigB64,
                                  );
                                  if (context.mounted && isSuccess) {
                                    Provider.of<BookingsController>(context, listen: false).loadBookings();
                                  }
                                } catch (e) {
                                  debugPrint('Error accepting quotation: $e');
                                }

                                if (mounted) {
                                  setModalState(() => isSubmitting = false);
                                  if (isSuccess) {
                                    setState(() => _status = 'accepted');
                                    nav.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Quotation accepted & signed successfully!',
                                        ),
                                        backgroundColor: Color(0xFF2E7D32),
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not confirm quotation in Odoo. Please try again or contact support.',
                                        ),
                                        backgroundColor: Color(0xFFC62828),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC4913F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Accept',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
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
            ),
          );
        },
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScaffold(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.estimation ?? EstimationModel.defaultStatic();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),
        body: Column(
          children: [
            CustomAppBar(
              title: 'Your Estimate',
              onBackPressed: () => _handleBack(context),
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

                  // Next steps timeline container
                  _buildNextStepsCard(context, data),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Two-tone ticket card
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLightDetailRow('Quotation Ref', data.id),
                const SizedBox(height: 12),
                _buildLightDetailRow('Selected Car', data.vehicleName),
                if (data.vehicleRegistration != null && data.vehicleRegistration!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildLightDetailRow('Registration', data.vehicleRegistration!),
                ],
                if (data.vehicleVin != null && data.vehicleVin!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildLightDetailRow('VIN', data.vehicleVin!),
                ],
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
                if (data.validityDate != null && data.validityDate!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildLightDetailRow('Valid Until', data.validityDate!),
                ],

                if (data.lineItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Breakdown',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D1813),
                        ),
                      ),
                      Text(
                        '${data.lineItems.length} item(s)',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF8C8273),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...data.lineItems.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEBE7DF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1D1813),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${data.currencySymbol} ${item.priceTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC4913F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qty: ${item.quantity.toInt()} × ${data.currencySymbol} ${item.priceUnit.toStringAsFixed(2)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 11.5,
                                color: const Color(0xFF7A7063),
                              ),
                            ),
                            if (item.discount > 0)
                              Text(
                                'Discount: ${item.discount}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11.5,
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],

                if (data.amountUntaxed != null || data.amountTax != null) ...[
                  const SizedBox(height: 14),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                  ),
                  const SizedBox(height: 14),
                  if (data.amountUntaxed != null) ...[
                    _buildLightDetailRow(
                      'Subtotal (Untaxed)',
                      '${data.currencySymbol} ${data.amountUntaxed!.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (data.amountTax != null) ...[
                    _buildLightDetailRow(
                      'Tax / VAT',
                      '${data.currencySymbol} ${data.amountTax!.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildLightDetailRow(
                    'Total Amount',
                    '${data.currencySymbol} ${data.estimatedAmount.toStringAsFixed(2)}',
                  ),
                ],

                const SizedBox(height: 22),

                // Status or Action Buttons
                if (_status == 'accepted' || data.state == 'sale')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quotation Accepted & Signed',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_status == 'declined' || data.state == 'cancel')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE57373)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cancel,
                          color: Color(0xFFC62828),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quotation Declined',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      if (!data.isQuotationSent) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled_rounded,
                                color: Color(0xFFF57F17),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Draft Estimate Created',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFF57F17),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Our detailer will inspect your vehicle and send a finalized quotation. Accept & Sign will be enabled once quotation is sent by technician.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11.5,
                                        color: const Color(0xFF5D4037),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Accept & Sign Button (Enabled if quotation sent by technician, Disabled otherwise)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: data.isQuotationSent
                              ? () => _showAcceptAndSignModal(context, data)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC4913F),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE5DFD5),
                            disabledForegroundColor: const Color(0xFF8C8273),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.draw_outlined,
                            size: 20,
                            color: data.isQuotationSent
                                ? Colors.white
                                : const Color(0xFF8C8273),
                          ),
                          label: Text(
                            data.isQuotationSent
                                ? 'Accept & Sign'
                                : 'Accept & Sign (Disabled - Waiting for Quotation)',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: data.isQuotationSent
                                  ? Colors.white
                                  : const Color(0xFF8C8273),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Get Directions to Garage Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _openGoogleMapsDirections(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1D1813),
                            side: const BorderSide(
                              color: Color(0xFFD6C8B4),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.near_me_outlined,
                            size: 16,
                            color: Color(0xFF1D1813),
                          ),
                          label: Text(
                            'Get Directions to Garage',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1813),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Light Detail Row
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

/// Digital Signature Canvas Pad Widget
class SignaturePadWidget extends StatefulWidget {
  const SignaturePadWidget({super.key});

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<String?> toBase64Png() async {
    if (isEmpty) return null;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0, 0), const Offset(400, 180)),
      );

      final paint = Paint()
        ..color = const Color(0xFF1D1813)
        ..strokeCap = ui.StrokeCap.round
        ..strokeWidth = 3.0;

      // Fill background
      canvas.drawColor(Colors.white, ui.BlendMode.src);

      for (final stroke in _strokes) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      }
      for (int i = 0; i < _currentStroke.length - 1; i++) {
        canvas.drawLine(_currentStroke[i], _currentStroke[i + 1], paint);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 180);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error generating signature base64: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC4913F).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _strokes.add(List.from(_currentStroke));
                  _currentStroke.clear();
                });
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _SignaturePainter(_strokes, _currentStroke),
              ),
            ),
            if (isEmpty)
              IgnorePointer(
                child: Center(
                  child: Text(
                    'Sign with your finger here',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: const Color(0xFFAAA59B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1D1813)
      ..strokeCap = ui.StrokeCap.round
      ..strokeWidth = 3.0;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
    for (int i = 0; i < currentStroke.length - 1; i++) {
      canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

/// Sawtooth Ticket Painter
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

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

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

/// Dashed Line Painter
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
