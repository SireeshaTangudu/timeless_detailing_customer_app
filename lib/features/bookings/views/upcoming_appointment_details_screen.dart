import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/widgets/sawtooth_ticket_painter.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/live_tracking_screen.dart';
import 'package:timeless_detailing_customer_app/core/utils/map_launcher_util.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/garage_location_model.dart';

import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/odoo_payment_webview_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/features/invoices/views/invoices_screen.dart';

class UpcomingAppointmentDetailsScreen extends StatefulWidget {
  final Booking booking;
  final bool isDownPaymentInvoice;
  final String? title;

  const UpcomingAppointmentDetailsScreen({
    super.key,
    required this.booking,
    this.isDownPaymentInvoice = false,
    this.title,
  });

  @override
  State<UpcomingAppointmentDetailsScreen> createState() =>
      _UpcomingAppointmentDetailsScreenState();
}

class _UpcomingAppointmentDetailsScreenState
    extends State<UpcomingAppointmentDetailsScreen> {
  Booking? _detailedBooking;
  bool _isLoadingInvoiceDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchInvoiceDetailsIfNeeded();
  }

  Future<void> _fetchInvoiceDetailsIfNeeded() async {
    final b = widget.booking;
    final int? invId = b.invoiceId ?? int.tryParse(b.id);
    if (invId != null &&
        (widget.isDownPaymentInvoice || b.isDownPaymentInvoice)) {
      setState(() => _isLoadingInvoiceDetails = true);
      try {
        final odooService = Provider.of<BaseOdooService>(
          context,
          listen: false,
        );
        final detailsMap = await odooService.getInvoiceDetails(invId);
        if (detailsMap != null && mounted) {
          setState(() {
            _detailedBooking = Booking.fromInvoiceJson(detailsMap);
            _isLoadingInvoiceDetails = false;
          });
        } else if (mounted) {
          setState(() => _isLoadingInvoiceDetails = false);
        }
      } catch (e) {
        debugPrint('Error fetching invoice details on load: $e');
        if (mounted) setState(() => _isLoadingInvoiceDetails = false);
      }
    }
  }

  Future<void> _openDirections() async {
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
    } catch (_) {
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

  Future<void> _openInvoicePaymentWebview(
    BuildContext context,
    Booking b,
  ) async {
    String baseUrl =
        'https://keerthan-lfi-lfi-timeless-detailing1-uat-37341397.dev.odoo.com/';
    BaseOdooService? odooService;
    try {
      odooService = Provider.of<BaseOdooService>(context, listen: false);
      if (odooService.baseUrl.isNotEmpty) {
        baseUrl = odooService.baseUrl;
      }
    } catch (_) {}

    int? invId = b.invoiceId;
    String accToken = (b.invoiceAccessToken ?? '').trim();
    if (accToken == 'false' || accToken == 'null') accToken = '';
    String? accessUrl = b.invoiceAccessUrl;

    // Fetch fresh access_token & access_url if missing/invalid
    if ((accToken.isEmpty || accessUrl == null || accessUrl.isEmpty) &&
        invId != null &&
        odooService != null) {
      try {
        final invDetails = await odooService.getInvoiceDetails(invId);
        if (invDetails != null) {
          final rawToken = invDetails['access_token']?.toString() ?? '';
          if (rawToken.isNotEmpty &&
              rawToken != 'false' &&
              rawToken != 'null') {
            accToken = rawToken;
          }
          final rawUrl = invDetails['access_url']?.toString() ?? '';
          if (rawUrl.isNotEmpty && rawUrl != 'false' && rawUrl != 'null') {
            accessUrl = rawUrl;
          }
        }
      } catch (e) {
        debugPrint('Error fetching invoice details for payment webview: $e');
      }
    }

    // Extract access_token from accessUrl if access_token field was empty
    if (accToken.isEmpty &&
        accessUrl != null &&
        accessUrl.contains('access_token=')) {
      final match = RegExp(r'access_token=([^&]+)').firstMatch(accessUrl);
      if (match != null && match.group(1) != 'false') {
        accToken = match.group(1)!;
      }
    }

    // Fallback invId if null
    invId ??= int.tryParse(b.id.replaceAll(RegExp(r'[^\d]'), ''));

    String payUrl;
    if (accessUrl != null &&
        accessUrl.isNotEmpty &&
        accessUrl.startsWith('/my/invoices/')) {
      payUrl = accessUrl.startsWith('http') ? accessUrl : '$baseUrl$accessUrl';
      if (accToken.isNotEmpty &&
          accToken != 'false' &&
          !payUrl.contains('access_token=')) {
        payUrl += payUrl.contains('?')
            ? '&access_token=$accToken'
            : '?access_token=$accToken';
      }
    } else {
      payUrl = '$baseUrl/my/invoices/$invId';
      if (accToken.isNotEmpty && accToken != 'false') {
        payUrl += '?access_token=$accToken';
      }
    }

    debugPrint('🌐 [Payment] Launching payment webview URL: $payUrl');

    if (!context.mounted) return;

    final bool? paymentDone = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => OdooPaymentWebviewScreen(
          url: payUrl,
          title: b.notes.isNotEmpty
              ? 'Invoice (${b.notes})'
              : 'Invoice Payment',
          onPaymentSuccess: () {
            debugPrint('🟢 [Payment] Payment detected! Refreshing bookings...');
            try {
              final controller = Provider.of<BookingsController>(
                context,
                listen: false,
              );
              controller.loadBookings();
            } catch (_) {}
          },
        ),
      ),
    );

    if (paymentDone == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment completed successfully! Redirecting to Invoices.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InvoicesScreen()),
      );
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

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScaffold()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _detailedBooking ?? widget.booking;
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

    final bool showInvoiceView =
        widget.isDownPaymentInvoice || b.isDownPaymentInvoice;
    final String appBarTitle = widget.title ?? (showInvoiceView ? 'Invoice Details' : 'Appointment Details');

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
              title: appBarTitle,
              onBackPressed: () => _handleBack(context),
            ),
            Expanded(
              child: _isLoadingInvoiceDetails
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC4913F),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: showInvoiceView
                          ? _buildDownPaymentInvoiceBody(
                              context,
                              b,
                              selectedCar,
                              carType,
                              fullDateStr,
                              slotTimeStr,
                            )
                          : Column(
                              children: [
                                // Two-tone saw-tooth ticket card matching NewEstimateScreen & Figma
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFEBE7E0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
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
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          24,
                                          20,
                                          18,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2A231C),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFC4913F,
                                                  ).withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons
                                                      .cleaning_services_outlined,
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
                                            _buildLightDetailRow(
                                              'Selected Car',
                                              selectedCar,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLightDetailRow(
                                              'Car Type',
                                              carType,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLightDetailRow(
                                              'Service',
                                              serviceTitle,
                                            ),
                                            const SizedBox(height: 14),

                                            // Dashed Divider Line
                                            CustomPaint(
                                              size: const Size(
                                                double.infinity,
                                                1,
                                              ),
                                              painter: DashedLinePainter(
                                                color: const Color(0xFFE5DFD5),
                                              ),
                                            ),

                                            const SizedBox(height: 14),
                                            _buildLightDetailRow(
                                              'Service Date',
                                              fullDateStr,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLightDetailRow(
                                              'Slot',
                                              slotTimeStr,
                                            ),

                                            const SizedBox(height: 20),

                                            // Button: Get Directions to Garage
                                            SizedBox(
                                              width: double.infinity,
                                              height: 46,
                                              child: ElevatedButton.icon(
                                                onPressed: _openDirections,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFE8DBCA,
                                                  ),
                                                  foregroundColor: const Color(
                                                    0xFF1D1813,
                                                  ),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            foregroundColor: const Color(
                                              0xFFB71C1C,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFE57373),
                                              width: 1.2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                            size: 16,
                                          ),
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
                                                    LiveTrackingScreen(
                                                      booking: b,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFC4913F,
                                            ),
                                            foregroundColor: const Color(
                                              0xFF1D1813,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.radar_outlined,
                                            size: 16,
                                          ),
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
      ),
    );
  }

  Widget _buildDownPaymentInvoiceBody(
    BuildContext context,
    Booking b,
    String selectedCar,
    String carType,
    String fullDateStr,
    String slotTimeStr,
  ) {
    final double addOnsTotal = b.addOns.fold(
      0.0,
      (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0.0),
    );
    final double totalToPay = b.pendingAmount + addOnsTotal;
    final bool hasAddOns = b.addOns.isNotEmpty;

    // Payment button wording:
    // When timeless_is_down_payment_invoice == true & remaining amount / residual is 0.0 (or paid) -> "Pay Balance"
    // Otherwise -> "Accept and Pay Amount"
    final bool isDownPayment = b.isDownPaymentInvoice;
    final String paymentState = (b.invoicePaymentState ?? '').toLowerCase();
    final bool isPaid = paymentState == 'paid' || paymentState == 'in_payment';
    final bool isResidualZero = b.pendingAmount <= 0.0;

    final String actionButtonText = (isDownPayment && (isPaid || isResidualZero))
        ? 'Pay Balance'
        : (isPaid ? 'Pay Balance' : 'Accept and Pay Amount');

    final String vMake = b.vehicleMake.isNotEmpty ? b.vehicleMake : selectedCar;
    final String vModel = b.vehicleModel.isNotEmpty ? b.vehicleModel : carType;
    final String vReg = b.vehicleLicensePlate.isNotEmpty
        ? b.vehicleLicensePlate
        : 'N/A';
    final String? warranty = b.warrantyLabel;

    return Column(
      children: [
        // 1. Top Appointment & Vehicle Details Card
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEBE7E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warranty != null && warranty.isNotEmpty)
                    const SizedBox(height: 10),

                  _buildLightDetailRow('Vehicle Make', vMake),
                  const SizedBox(height: 12),
                  _buildLightDetailRow('Vehicle Model', vModel),
                  const SizedBox(height: 12),
                  _buildLightDetailRow('Registration Number', vReg),
                  const SizedBox(height: 12),
                  _buildLightDetailRow('Service', b.service.name),
                  const SizedBox(height: 14),

                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                  ),

                  const SizedBox(height: 14),
                  _buildLightDetailRow('Service Date', fullDateStr),
                  const SizedBox(height: 12),
                  _buildLightDetailRow('Slot', slotTimeStr),

                  const SizedBox(height: 20),

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

            // Top-Right Ribbon Warranty Banner matching the design image
            if (warranty != null && warranty.isNotEmpty)
              Positioned(
                top: -10,
                right: -4,
                child: CornerRibbonTag(
                  text: warranty,
                  color: const Color(0xFFC4913F),
                ),
              ),
          ],
        ),

        const SizedBox(height: 18),

        // 2. Financial Breakdown Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBE7E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildLightDetailRow(
                'Estimated Cost',
                'R ${(b.totalPrice > 0 ? b.totalPrice : 2800.0).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _buildLightDetailRow(
                'Percentage Amount Paid',
                '${b.percentageAmountPaid.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 12),
              _buildLightDetailRow(
                'Amount Paid',
                'R ${b.amountPaid.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _buildLightDetailRow('Amount Paid On', b.amountPaidOn),
              const SizedBox(height: 12),
              _buildLightDetailRow(
                'Pending Amount',
                'R ${b.pendingAmount.toStringAsFixed(2)}',
              ),

              if (hasAddOns) ...[
                const SizedBox(height: 12),
                for (final item in b.addOns) ...[
                  _buildLightDetailRow(
                    item['name']?.toString() ?? 'Add on',
                    'R ${((item['price'] as num?)?.toDouble() ?? 100.0).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                ],
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount to be Paid',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      'R ${totalToPay.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Disclaimer Note
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'This price is subject to change if you opt for another add on services suggested by car team',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              color: const Color(0xFF7A7063),
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bottom Action Button: Pay Balance / Accept & Pay Amount
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _openInvoicePaymentWebview(context, b),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC4913F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              actionButtonText,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
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

class CornerRibbonTag extends StatelessWidget {
  final String text;
  final Color color;

  const CornerRibbonTag({
    super.key,
    required this.text,
    this.color = const Color(0xFFC4913F),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Ribbon Rectangle Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              topRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Folded ribbon corner shadow triangle (3D fold effect on bottom-right edge)
        Positioned(
          right: 0,
          bottom: -6,
          child: ClipPath(
            clipper: _RibbonFoldClipper(),
            child: Container(
              width: 6,
              height: 6,
              color: const Color(0xFF7A5820), // Darker shade for folded shadow
            ),
          ),
        ),
      ],
    );
  }
}

class _RibbonFoldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
