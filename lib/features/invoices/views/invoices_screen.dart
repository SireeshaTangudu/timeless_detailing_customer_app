import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/upcoming_appointment_details_screen.dart';

class InvoicesScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const InvoicesScreen({super.key, this.onMenuTap});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final controller = Provider.of<BookingsController>(
        context,
        listen: false,
      );
      await controller.loadInvoices();
    } catch (e) {
      debugPrint('Error calling loadInvoices: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else if (widget.onMenuTap != null) {
      widget.onMenuTap!();
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
    final controller = Provider.of<BookingsController>(context);
    final invoices = controller.userInvoices;
    final bool isBusy = _isLoading || controller.isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0), // Warm light cream
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  CustomAppBar(
                    title: 'My Invoices',
                    backIcon: Icons.arrow_back_sharp,
                    onBackPressed: () => _handleBack(context),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchInvoices,
                      color: const Color(0xFFC4913F),
                      child: invoices.isEmpty && !isBusy
                          ? _buildEmptyInvoicesView()
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.all(20),
                              itemCount: invoices.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final invMap = invoices[index];
                                return _buildInvoiceCard(context, invMap);
                              },
                            ),
                    ),
                  ),
                ],
              ),
              if (isBusy)
                Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC4913F)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInvoicesView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF3E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFFC4913F),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Invoices Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your posted invoices will appear here.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF8C8273),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> invMap) {
    final String invName = invMap['name']?.toString() ?? 'Invoice';
    final String invDateRaw = invMap['invoice_date']?.toString() ?? '';
    DateTime? invDate;
    if (invDateRaw.isNotEmpty) {
      try {
        invDate = DateTime.parse(invDateRaw);
      } catch (_) {}
    }
    final String dateStr = invDate != null
        ? DateFormat('d MMMM, yyyy').format(invDate)
        : invDateRaw;

    final double total = (invMap['amount_total'] as num?)?.toDouble() ?? 0.0;
    final double residual =
        (invMap['amount_residual'] as num?)?.toDouble() ?? 0.0;
    final String paymentState = (invMap['payment_state'] ?? '')
        .toString()
        .toLowerCase();
    final bool isPaid =
        paymentState == 'paid' || paymentState == 'in_payment' || residual <= 0;
    final bool isDownPayment =
        invMap['timeless_is_down_payment_invoice'] == true;

    final String statusText = isPaid ? 'Paid' : 'Pending';
    final Color badgeColor = isPaid
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFB8C00);
    final Color foldColor = isPaid
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);

    return GestureDetector(
      onTap: () {
        // Convert map to Booking object and open detail view
        final bookingObj = Booking.fromInvoiceJson(invMap);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpcomingAppointmentDetailsScreen(
              booking: bookingObj,
              isDownPaymentInvoice: true,
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBE7DF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFC4913F).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFFC4913F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1C1E),
                            ),
                          ),
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFF8C8273),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFF0ECE3), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDownPayment)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF3E8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Down Payment Invoice',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFC4913F),
                              ),
                            ),
                          ),
                        Text(
                          'Total Amount',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF8C8273),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'R ${total.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A2F1E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top-Right Ribbon Status Tag matching reference image design
          Positioned(
            top: -8,
            right: -4,
            child: CornerRibbonTag(
              text: statusText,
              color: badgeColor,
              foldColor: foldColor,
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
  final Color foldColor;

  const CornerRibbonTag({
    super.key,
    required this.text,
    required this.color,
    required this.foldColor,
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
            child: Container(width: 6, height: 6, color: foldColor),
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
