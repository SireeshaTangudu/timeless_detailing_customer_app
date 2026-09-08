import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_shimmer_loading.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/upcoming_appointment_details_screen.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/features/subscriptions/controllers/subscriptions_controller.dart';
import 'package:timeless_detailing_customer_app/features/subscriptions/models/subscription_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';

class SubscriptionsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const SubscriptionsScreen({super.key, this.onMenuTap});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionsController>(context, listen: false)
          .loadSubscriptions();
    });
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
    final controller = Provider.of<SubscriptionsController>(context);
    final subscriptions = controller.subscriptions;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0), // Warm light cream
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'My Subscriptions',
                backIcon: Icons.arrow_back_sharp,
                onBackPressed: () => _handleBack(context),
              ),
              Expanded(
                child: controller.isLoading
                    ? const ShimmerListLoader()
                    : RefreshIndicator(
                        onRefresh: () => controller.loadSubscriptions(),
                        color: const Color(0xFFC4913F),
                        child: subscriptions.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.all(20),
                                itemCount: subscriptions.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final item = subscriptions[index];
                                  return _buildSubscriptionCard(context, item);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.card_membership_outlined,
                color: Color(0xFFC4913F),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Subscriptions Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Active maintenance wash plans will appear here.',
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

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionModel item) {
    final bool isActive = item.isActive;
    final String nextInvStr = item.nextInvoiceDate.isNotEmpty
        ? (DateTime.tryParse(item.nextInvoiceDate) != null
            ? DateFormat('d MMMM, yyyy')
                .format(DateTime.parse(item.nextInvoiceDate))
            : item.nextInvoiceDate)
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE7DF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Dark banner with Plan & Price
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            color: const Color(0xFF1D1813),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A231C),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC4913F).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.card_membership,
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
                              item.planName,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Ref: ${item.name}',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: const Color(0xFFC5B7A1),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.currencySymbol} ${item.recurringTotal.toStringAsFixed(0)} / mo',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC4913F),
                  ),
                ),
              ],
            ),
          ),

          // Main Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge & Next Invoice Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.formattedStatus,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Next Invoice: $nextInvStr',
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A7063),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFEBE7DF), height: 1),
                const SizedBox(height: 16),

                // Included Items / Order Lines
                if (item.orderLines.isNotEmpty) ...[
                  Text(
                    'Plan Details & Services',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...item.orderLines.where((l) {
                    final pName = (l['name'] ?? '').toString();
                    return pName.isNotEmpty && !pName.toLowerCase().contains('down payment');
                  }).map((line) {
                    final pName = (line['name'] ?? 'Service').toString();
                    final pQty = (line['product_uom_qty'] as num?)?.toInt() ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Color(0xFFC4913F),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$pQty x $pName',
                              style: GoogleFonts.montserrat(
                                fontSize: 12.5,
                                color: const Color(0xFF3A2F1E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                ],

                // Linked Invoices Section
                if (item.invoiceIds.isNotEmpty) ...[
                  Text(
                    'Linked Invoices',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.invoiceIds.map((inv) {
                      final invId = inv['id'];
                      final invName = (inv['name'] ?? 'Invoice').toString();
                      return ActionChip(
                        avatar: const Icon(
                          Icons.receipt_outlined,
                          size: 14,
                          color: Color(0xFFC4913F),
                        ),
                        label: Text(
                          invName,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                        backgroundColor: const Color(0xFFFAF5ED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: Color(0xFFEBE7DF),
                          ),
                        ),
                        onPressed: () {
                          final int? targetInvoiceId = invId is int
                              ? invId
                              : int.tryParse(invId.toString());
                          if (targetInvoiceId != null) {
                            final invoiceService = DetailService(
                              id: 'inv_$targetInvoiceId',
                              name: invName,
                              description: invName,
                              price: item.recurringTotal > 0
                                  ? item.recurringTotal
                                  : item.amountTotal,
                              durationHours: 1.0,
                              imageUrl: '',
                              category: '',
                              whatsIncluded: const [],
                            );
                            final invoiceBooking = Booking(
                              id: targetInvoiceId.toString(),
                              invoiceId: targetInvoiceId,
                              isDownPaymentInvoice: true,
                              service: invoiceService,
                              vehicleName: item.planName.isNotEmpty ? item.planName : invName,
                              vehicleLicensePlate: '',
                              bookingDateTime:
                                  DateTime.tryParse(item.dateOrder) ??
                                      DateTime.now(),
                              status: BookingStatus.confirmed,
                              currentStep: 1,
                              totalPrice: item.recurringTotal > 0
                                  ? item.recurringTotal
                                  : item.amountTotal,
                              notes: invName,
                              beforeImages: const [],
                              afterImages: const [],
                              technicianName: '',
                              technicianAvatar: '',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UpcomingAppointmentDetailsScreen(
                                  booking: invoiceBooking,
                                  isDownPaymentInvoice: true,
                                  title: 'Invoice Details',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
