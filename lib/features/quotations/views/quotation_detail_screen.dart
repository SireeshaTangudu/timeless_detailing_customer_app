import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/services/currency_service.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/quotations/models/quotation_model.dart';

class QuotationDetailScreen extends StatelessWidget {
  final QuotationModel quotation;

  const QuotationDetailScreen({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: quotation.name,
              backIcon: Icons.arrow_back_sharp,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                quotation.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: quotation.stateBackgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  quotation.stateLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: quotation.stateColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFEBE7DF)),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Order Date',
                            value: quotation.formattedDateOrder,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.event_available_outlined,
                            label: 'Expiration / Validity',
                            value: quotation.formattedValidityDate,
                          ),
                          if (quotation.partnerName != null &&
                              quotation.partnerName!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.person_outline,
                              label: 'Customer Name',
                              value: quotation.partnerName!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subscription Info if applicable
                    if (quotation.isSubscription) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF3E8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.card_membership_outlined,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Subscription Details',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (quotation.planName != null)
                              _buildDetailRow(
                                icon: Icons.repeat_outlined,
                                label: 'Plan',
                                value: quotation.planName!,
                              ),
                            if (quotation.nextInvoiceDate != null &&
                                quotation.nextInvoiceDate!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Next Invoice Date',
                                value: quotation.nextInvoiceDate!,
                              ),
                            ],
                            if (quotation.recurringTotal > 0) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                icon: Icons.payments_outlined,
                                label: 'Recurring Total',
                                value: CurrencyService.instance.format(
                                  quotation.recurringTotal,
                                  currencyId: quotation.currencyId,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Summary Breakdown Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary Breakdown',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPriceRow('Untaxed Amount', quotation.amountUntaxed),
                          const SizedBox(height: 10),
                          _buildPriceRow('Taxes', quotation.amountTax),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFEBE7DF)),
                          ),
                          _buildPriceRow(
                            'Total Amount',
                            quotation.amountTotal,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7A7A7E)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF7A7A7E),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF1C1C1E) : const Color(0xFF7A7A7E),
          ),
        ),
        Text(
          CurrencyService.instance.format(
            amount,
            currencyId: quotation.currencyId,
          ),
          style: GoogleFonts.outfit(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primary : const Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}
