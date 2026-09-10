import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/services/currency_service.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_shimmer_loading.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/views/main_navigation_scaffold.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/estimation_screen.dart';
import 'package:timeless_detailing_customer_app/features/quotations/controllers/quotations_controller.dart';
import 'package:timeless_detailing_customer_app/features/quotations/models/quotation_model.dart';

class QuotationsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const QuotationsScreen({super.key, this.onMenuTap});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuotationsController>(
        context,
        listen: false,
      ).loadQuotations();
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

  List<QuotationModel> _filterQuotations(List<QuotationModel> list) {
    if (_selectedFilter == 'All') return list;
    if (_selectedFilter == 'Sent') {
      return list.where((q) => q.state.toLowerCase() == 'sent').toList();
    }
    if (_selectedFilter == 'Sales Order') {
      return list.where((q) => q.state.toLowerCase() == 'sale').toList();
    }
    if (_selectedFilter == 'Cancelled') {
      return list.where((q) => q.state.toLowerCase() == 'cancel').toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<QuotationsController>(context);
    final filteredList = _filterQuotations(controller.quotations);

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
                title: 'Quotations',
                backIcon: Icons.arrow_back_sharp,
                onBackPressed: () => _handleBack(context),
              ),

              // Filter Chips
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Sent'),
                    _buildFilterChip('Sales Order'),
                    _buildFilterChip('Cancelled'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: controller.isLoading
                    ? const ShimmerListLoader()
                    : RefreshIndicator(
                        onRefresh: () => controller.loadQuotations(),
                        color: const Color(0xFFC4913F),
                        child: filteredList.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                itemCount: filteredList.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final item = filteredList[index];
                                  return _buildQuotationCard(context, item);
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

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = filter;
            });
          }
        },
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF3A2F1E),
        ),
        selectedColor: AppTheme.primary,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary
                : const Color(0xFFEBE7DF),
          ),
        ),
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
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
                Icons.request_quote_outlined,
                color: Color(0xFFC4913F),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Quotations Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'You currently have no quotations on record.'
                  : 'No quotations found under status "$_selectedFilter".',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF7A7A7E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationCard(BuildContext context, QuotationModel item) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _onQuotationCardTap(context, item),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF3E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.request_quote_outlined,
                            color: Color(0xFFC4913F),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 50),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFEBE7DF)),
                    const SizedBox(height: 14),

                    // Details Grid / Info
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7A7A7E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.formattedDateOrder,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Validity Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7A7A7E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.formattedValidityDate,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Subscription Plan if applicable
                    if (item.isSubscription && item.planName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.repeat,
                              size: 14,
                              color: Color(0xFFC4913F),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Subscription: ${item.planName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A2F1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Bottom Row: Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7A7A7E),
                          ),
                        ),
                        Text(
                          CurrencyService.instance.format(
                            item.amountTotal,
                            currencyId: item.currencyId,
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Corner Ribbon Status Tag matching Invoice screen design
        Positioned(
          top: -8,
          right: -4,
          child: CornerRibbonTag(
            text: item.stateLabel,
            color: item.stateColor,
            foldColor: item.foldColor,
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
        // Main Ribbon Banner
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

        // Folded ribbon corner shadow triangle
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

  Future<void> _onQuotationCardTap(BuildContext context, QuotationModel item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: FourRotatingDotsLoader(size: 32, color: AppTheme.primary),
      ),
    );

    try {
      final odooService = Provider.of<BaseOdooService>(context, listen: false);
      final detailJson = await odooService.getQuotationDetails(item.id);

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loader
        final dataToParse = detailJson ?? {
          'id': item.id,
          'name': item.name,
          'date_order': item.dateOrder,
          'validity_date': item.validityDate,
          'amount_untaxed': item.amountUntaxed,
          'amount_tax': item.amountTax,
          'amount_total': item.amountTotal,
          'state': item.state,
          'is_subscription': item.isSubscription,
          'subscription_state': item.subscriptionState,
          'plan_id': item.planName != null ? {'id': item.planId, 'name': item.planName} : false,
          'recurring_total': item.recurringTotal,
        };

        final estimationObj = EstimationModel.fromOdooJson(dataToParse);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EstimationScreen(estimation: estimationObj),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening estimation screen for quotation ${item.id}: $e');
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loader
        final estimationObj = EstimationModel.fromOdooJson({
          'id': item.id,
          'name': item.name,
          'date_order': item.dateOrder,
          'validity_date': item.validityDate,
          'amount_untaxed': item.amountUntaxed,
          'amount_tax': item.amountTax,
          'amount_total': item.amountTotal,
          'state': item.state,
          'is_subscription': item.isSubscription,
          'subscription_state': item.subscriptionState,
          'plan_id': item.planName != null ? {'id': item.planId, 'name': item.planName} : false,
          'recurring_total': item.recurringTotal,
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EstimationScreen(estimation: estimationObj),
          ),
        );
      }
    }
  }
