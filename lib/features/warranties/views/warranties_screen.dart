import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_shimmer_loading.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/features/warranties/controllers/warranties_controller.dart';
import 'package:timeless_detailing_customer_app/features/warranties/models/warranty_model.dart';

class WarrantiesScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const WarrantiesScreen({super.key, this.onMenuTap});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WarrantiesController>(
        context,
        listen: false,
      ).loadWarranties();
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
    final controller = Provider.of<WarrantiesController>(context);
    final warranties = controller.warranties;

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
                title: 'My Warranties',
                backIcon: Icons.arrow_back_sharp,
                onBackPressed: () => _handleBack(context),
              ),
              Expanded(
                child: controller.isLoading
                    ? const ShimmerListLoader()
                    : RefreshIndicator(
                        onRefresh: () => controller.loadWarranties(),
                        color: const Color(0xFFC4913F),
                        child: warranties.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.all(20),
                                itemCount: warranties.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final item = warranties[index];
                                  return _buildWarrantyCard(context, item);
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
                Icons.verified_user_outlined,
                color: Color(0xFFC4913F),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Warranties Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Active warranty certificates will appear here.',
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

  Widget _buildWarrantyCard(BuildContext context, WarrantyModel item) {
    final String startFormatted = item.warrantyStart.isNotEmpty
        ? (DateTime.tryParse(item.warrantyStart) != null
              ? DateFormat(
                  'd MMM yyyy',
                ).format(DateTime.parse(item.warrantyStart))
              : item.warrantyStart)
        : 'N/A';

    final String endFormatted = item.warrantyEnd.isNotEmpty
        ? (DateTime.tryParse(item.warrantyEnd) != null
              ? DateFormat(
                  'd MMM yyyy',
                ).format(DateTime.parse(item.warrantyEnd))
              : item.warrantyEnd)
        : 'N/A';

    final String statusText = item.formattedStatus;
    final Color badgeColor = item.isExpiring
        ? const Color(0xFFFB8C00)
        : (item.isActive ? const Color(0xFF4CAF50) : const Color(0xFFE53935));
    final Color foldColor = item.isExpiring
        ? const Color(0xFFE65100)
        : (item.isActive ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C));

    return Stack(
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
              // Top Header: Cert Name & Order Name
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(
                          0xFFC4913F,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_user,
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
                          item.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C1C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.saleOrderName != null &&
                            item.saleOrderName!.isNotEmpty)
                          Text(
                            'Order: ${item.saleOrderName}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: const Color(0xFF8C8273),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: Color(0xFFEBE7DF), height: 1),
              const SizedBox(height: 14),

              // Product & Vehicle Info
              if (item.productName.isNotEmpty) ...[
                Text(
                  item.productName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C1E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              if (item.vehicleTitle.isNotEmpty ||
                  item.vehicleRegistration.isNotEmpty) ...[
                Text(
                  '${item.vehicleTitle}${item.vehicleTitle.isNotEmpty && item.vehicleRegistration.isNotEmpty ? " • " : ""}${item.vehicleRegistration}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF8C8273),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
              ],

              // Validity Date Range Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEBE7DF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Color(0xFFC4913F),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Coverage Period:',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7A7063),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$startFormatted – $endFormatted',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Ribbon Status Chip
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
