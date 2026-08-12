import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/bookings_controller.dart';
import '../models/booking_model.dart';
import 'estimation_screen.dart';

class BookingsHistoryScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const BookingsHistoryScreen({super.key, this.onMenuTap});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  int _selectedTabIndex = 0; // 0: Completed Orders, 1: Upcoming Bookings

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingsController>(context, listen: false).loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<BookingsController>(context);

    // Filter bookings based on selected tab
    final completedList = controller.bookings
        .where((b) => b.status == BookingStatus.completed)
        .toList();
    final upcomingList = controller.bookings
        .where((b) => b.status != BookingStatus.completed)
        .toList();

    final displayList = _selectedTabIndex == 0 ? completedList : upcomingList;

    return Container(
      color: const Color(0xFFF7F5F0), // Warm light cream matching Figma
      child: SafeArea(
        child: Column(
        children: [
          CustomAppBar(
            title: 'My Orders and Bookings',
            backIcon: widget.onMenuTap != null ? Icons.menu : Icons.arrow_back,
            onBackPressed: () {
              if (widget.onMenuTap != null) {
                widget.onMenuTap!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadBookings(),
              color: const Color(0xFFC4913F),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Segmented Pill Tab Bar (Completed Orders / Upcoming Bookings)
                  Row(
                    children: [
                      Expanded(child: _buildTabPill(0, 'Completed Orders')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTabPill(1, 'Upcoming Bookings')),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Orders / Bookings List View
                  if (displayList.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = displayList[index];
                        return _buildBookingRowCard(context, item);
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  /// Segmented Tab Pill matching Figma
  Widget _buildTabPill(int index, String label) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF3E8) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFC4913F) : const Color(0xFFE5E0D8),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC4913F).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFFA17730) : const Color(0xFF8C8273),
          ),
        ),
      ),
    );
  }

  /// White booking item row card matching Figma
  Widget _buildBookingRowCard(BuildContext context, dynamic item) {
    final String title = item is Booking ? item.service.name : item['title'];
    final String dateStr = item is Booking
        ? DateFormat('d MMMM, yyyy').format(item.bookingDateTime)
        : item['date'];
    final String priceStr = item is Booking
        ? 'R ${item.totalPrice.toStringAsFixed(0)}'
        : item['price'];
    final String? vehicleStr = item is Booking ? item.vehicleName : null;
    final String? apptType = item is Booking ? item.appointmentTypeName : null;
    final String? resourceName = item is Booking ? item.appointmentResourceName : null;

    return GestureDetector(
      onTap: () {
        // Opens Screen 2 "Your New Estimate" / Detailed receipt matching Figma
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewEstimateScreen(bookingItem: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEBE7DF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gold Icon inside soft warm beige container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC4913F).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.cleaning_services_outlined,
                color: Color(0xFFC4913F),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Service Title & Date/Vehicle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (vehicleStr != null && vehicleStr.isNotEmpty && vehicleStr != 'Client Vehicle')
                        ? '$vehicleStr • $dateStr'
                        : dateStr,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF8C8273),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (resourceName != null && resourceName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        resourceName,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC4913F),
                        ),
                      ),
                    ),
                  ] else if (apptType != null && apptType.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      apptType,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF8C8273),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price Display
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFFBCAE9B),
            ),
            const SizedBox(height: 12),
            Text(
              'No Bookings Found',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have no detailing orders in this section.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF8C8273),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 2 in Figma: "Your New Estimate" (Updated Quote Breakdown & Invoice)
class NewEstimateScreen extends StatefulWidget {
  final dynamic bookingItem;
  final int? bookingId;

  const NewEstimateScreen({
    super.key,
    this.bookingItem,
    this.bookingId,
  });

  @override
  State<NewEstimateScreen> createState() => _NewEstimateScreenState();
}

class _NewEstimateScreenState extends State<NewEstimateScreen> {
  Booking? _fetchedBooking;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    final int? idToFetch = widget.bookingId ??
        (widget.bookingItem is int
            ? widget.bookingItem as int
            : (widget.bookingItem is Booking
                ? (widget.bookingItem as Booking).odooSaleOrderId
                : int.tryParse(widget.bookingItem?.toString() ?? '')));

    // If a specific booking ID is available and we haven't received full Endpoint 6 fields, query Endpoint 6 (`calendar.event/web_read`)
    if (idToFetch != null &&
        (widget.bookingItem is! Booking ||
            (widget.bookingItem as Booking).appointmentTypeName == null)) {
      _fetchDetails(idToFetch);
    }
  }

  Future<void> _fetchDetails(int bookingId) async {
    setState(() => _isLoadingDetails = true);
    final controller = Provider.of<BookingsController>(context, listen: false);
    final result = await controller.fetchBookingDetails(bookingId);
    if (mounted) {
      setState(() {
        _fetchedBooking = result;
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _confirmCancel(BuildContext context, Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to cancel your detailing appointment for ${booking.service.name}?',
          style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Appointment',
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
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetails) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),
        body: Column(
          children: [
            CustomAppBar(
              title: 'Your New Estimate',
              onBackPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFC4913F),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Booking? b = _fetchedBooking ??
        (widget.bookingItem is Booking ? widget.bookingItem as Booking : null);

    final String serviceTitle = b != null
        ? b.service.name
        : (widget.bookingItem?['title'] ?? 'Car Detailing');
    final String priceStr = b != null
        ? 'R ${b.totalPrice.toStringAsFixed(0)}'
        : (widget.bookingItem?['price'] ?? 'R 0');
    final String selectedCar = b != null
        ? (b.vehicleName.isNotEmpty ? b.vehicleName : 'Client Vehicle')
        : (widget.bookingItem?['car'] ?? 'Client Vehicle');
    final String serviceDate = b != null
        ? DateFormat('d MMMM, yyyy').format(b.bookingDateTime)
        : (widget.bookingItem?['date'] ?? '');
    final String startFormatted = b != null
        ? DateFormat('hh:mm a').format(b.bookingDateTime)
        : '12:00 PM';
    final String stopFormatted = b != null && b.stopDateTime != null
        ? DateFormat('hh:mm a').format(b.stopDateTime!)
        : '01:00 PM';
    final String serviceTime = '$startFormatted - $stopFormatted';
    final String statusText = b != null ? b.statusTitle : 'Confirmed';

    final String? apptType = b?.appointmentTypeName;
    final String? apptResource = b?.appointmentResourceName;
    final String? phone = b?.bookingPhone;
    final bool collectorRequired = b?.bookingCollectorRequired ?? false;
    final String? collectorName = b?.bookingCollectorName;
    final String? collectorLicense = b?.bookingCollectorLicense;
    final String? oppName = b?.opportunityName;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0), // Warm light cream
      body: Column(
        children: [
          CustomAppBar(
            title: 'Your New Estimate',
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Two-tone card matching Screen 2 in Figma
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEBE7E0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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
                                'Below is the final cost for your detailing service',
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

                        // Sawtooth Ticket Teeth Painter
                        CustomPaint(
                          size: const Size(double.infinity, 12),
                          painter: SawtoothTicketPainter(
                            darkColor: const Color(0xFF1D1813),
                            lightColor: Colors.white,
                          ),
                        ),

                        // Middle Details Section with Odoo Endpoint 5 Keys
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildDetailRow('Service Name', serviceTitle, isBold: true),
                              if (apptType != null && apptType.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildDetailRow('Appointment Type', apptType),
                              ],
                              if (apptResource != null && apptResource.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildDetailRow('Detailing Resource', apptResource),
                              ],
                              const SizedBox(height: 12),
                              _buildDetailRow('Selected Vehicle', selectedCar),
                              if (phone != null && phone.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildDetailRow('Contact Phone', phone),
                              ],
                              const SizedBox(height: 12),
                              _buildDetailRow('Service Date', serviceDate),
                              const SizedBox(height: 12),
                              _buildDetailRow('Time Slot', serviceTime),
                              
                              if (collectorRequired) ...[
                                const SizedBox(height: 12),
                                _buildDetailRow('Collector Required', 'Yes'),
                                if (collectorName != null && collectorName.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Collector Name', collectorName),
                                ],
                                if (collectorLicense != null && collectorLicense.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Collector License', collectorLicense),
                                ],
                              ],

                              if (oppName != null && oppName.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildDetailRow('Opportunity Ref', oppName),
                              ],

                              const SizedBox(height: 12),

                              // Booking Status with Green badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Booking Status',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: const Color(0xFF8C8273),
                                    ),
                                  ),
                                  Text(
                                    statusText,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Dotted Divider Line
                              CustomPaint(
                                size: const Size(double.infinity, 1),
                                painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                              ),

                              const SizedBox(height: 16),

                              // Cost Breakdown Table
                              _buildDetailRow('Estimated Cost', priceStr),
                              const SizedBox(height: 14),

                              CustomPaint(
                                size: const Size(double.infinity, 1),
                                painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                              ),

                              const SizedBox(height: 14),

                              _buildDetailRow('Total Amount', priceStr, isBold: true),
                              const SizedBox(height: 10),
                              
                              // Payment Status Paid Green
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Payment Status',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: const Color(0xFF8C8273),
                                    ),
                                  ),
                                  Text(
                                    'Paid',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Download Invoice Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Downloading invoice receipt...'),
                                        backgroundColor: Color(0xFF1D1813),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1C1C1E),
                                    side: const BorderSide(color: Color(0xFFC4913F), width: 1.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFFC4913F)),
                                  label: Text(
                                    'Download Invoice',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1C1C1E),
                                    ),
                                  ),
                                ),
                              ),

                              // Cancel Appointment Button (ENDPOINT 7: calendar.event/action_cancel_meeting)
                              if (b != null) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _confirmCancel(context, b),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFB71C1C),
                                      side: const BorderSide(color: Color(0xFFE57373), width: 1.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFB71C1C)),
                                    label: Text(
                                      'Cancel Appointment',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF8C8273),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF1C1C1E),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
