import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/bookings_controller.dart';
import '../models/booking_model.dart';
import 'estimation_screen.dart';

class BookingsHistoryScreen extends StatefulWidget {
  const BookingsHistoryScreen({super.key});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  int _selectedTabIndex = 0; // 0: Completed Orders, 1: Upcoming Bookings

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

    // Default static items if controller list is empty for initial prototype testing matching Figma
    final displayList = _selectedTabIndex == 0
        ? (completedList.isNotEmpty ? completedList : _getStaticCompleted())
        : (upcomingList.isNotEmpty ? upcomingList : _getStaticUpcoming());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0), // Warm light cream matching Figma
      body: Column(
        children: [
          CustomAppBar(
            title: 'My Orders and Bookings',
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
        ],
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
        ? DateFormat('dth MMMM, yyyy').format(item.bookingDateTime)
        : item['date'];
    final String priceStr = item is Booking
        ? 'R ${item.totalPrice.toStringAsFixed(0)}'
        : item['price'];

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
              width: 42,
              height: 42,
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
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Service Title & Date
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
                    dateStr,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF8C8273),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
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

  // Static items for prototype matching Figma
  List<Map<String, String>> _getStaticCompleted() {
    return [
      {'title': 'Interior Detailing', 'date': '10th July, 2026', 'price': 'R 2800'},
      {'title': 'Interior Detailing', 'date': '12th July, 2026', 'price': 'R 2800'},
      {'title': 'Interior Detailing', 'date': '15th July, 2026', 'price': 'R 2800'},
    ];
  }

  List<Map<String, String>> _getStaticUpcoming() {
    return [
      {'title': 'Paint Enhancement', 'date': '12th August, 2026', 'price': 'R 3800'},
    ];
  }
}

/// Screen 2 in Figma: "Your New Estimate" (Updated Quote Breakdown & Invoice)
class NewEstimateScreen extends StatelessWidget {
  final dynamic bookingItem;

  const NewEstimateScreen({
    super.key,
    this.bookingItem,
  });

  @override
  Widget build(BuildContext context) {
    final String serviceTitle = bookingItem is Booking
        ? bookingItem.service.name
        : (bookingItem?['title'] ?? 'Interior Detailing');

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
                                'Below is the final cost for your interior detailing service',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: const Color(0xFFC5B7A1),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'R 3800',
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

                        // Middle Details Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildDetailRow('Selected Car', 'Volkswagen Polo TDI 2.0'),
                              const SizedBox(height: 12),
                              _buildDetailRow('Car Type', 'Hatch Back'),
                              const SizedBox(height: 12),
                              _buildDetailRow('Service', serviceTitle),
                              const SizedBox(height: 12),
                              _buildDetailRow('Service Date', '12th August'),
                              const SizedBox(height: 12),
                              _buildDetailRow('Time', '12:00 PM'),
                              const SizedBox(height: 12),
                              
                              // Car Drop-off Status with Green badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Car Drop-off Status',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: const Color(0xFF8C8273),
                                    ),
                                  ),
                                  Text(
                                    'Dropped Off',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32), // Green status matching Figma
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
                              _buildDetailRow('Estimated Cost', 'R 2800.00'),
                              const SizedBox(height: 10),
                              _buildDetailRow('Add on 1', 'R 100.00'),
                              const SizedBox(height: 10),
                              _buildDetailRow('Add on 2', 'R 100.00'),
                              const SizedBox(height: 10),
                              _buildDetailRow('Add on 3', 'R 100.00'),
                              
                              const SizedBox(height: 14),

                              CustomPaint(
                                size: const Size(double.infinity, 1),
                                painter: DashedLinePainter(color: const Color(0xFFE5DFD5)),
                              ),

                              const SizedBox(height: 14),

                              _buildDetailRow('Total Amount to be Paid', 'R 3100.00', isBold: true),
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
