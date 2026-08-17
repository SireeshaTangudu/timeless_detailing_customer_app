import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_button.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_footer.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/book_service_screen.dart';

import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';

class ServiceDetailScreen extends StatefulWidget {
  final DetailService service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final templateId = widget.service.odooProductId ??
            int.tryParse(widget.service.id) ??
            4;
        debugPrint(
          '🔵 [ServiceDetailScreen] On click of service "${widget.service.name}", calling Endpoint 2 (product.product/web_search_read) for templateId=$templateId...',
        );
        Provider.of<ServicesController>(context, listen: false)
            .fetchVariants(templateId);
      }
    });
  }

  Widget _buildHeaderImage(DetailService service) {
    if (service.assetImagePath != null && service.assetImagePath!.isNotEmpty) {
      return Image.asset(
        service.assetImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF2A2318),
          child: const Center(
            child: Icon(Icons.cleaning_services_rounded, size: 64, color: AppTheme.primary),
          ),
        ),
      );
    }
    if (service.imageUrl.startsWith('http')) {
      return Image.network(
        service.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF2A2318),
          child: const Center(
            child: Icon(Icons.cleaning_services_rounded, size: 64, color: AppTheme.primary),
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFF2A2318),
      child: const Center(
        child: Icon(Icons.cleaning_services_rounded, size: 64, color: AppTheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final theme = Theme.of(context);
    final controller = Provider.of<ServicesController>(context);
    final templateId = service.odooProductId ?? int.tryParse(service.id) ?? 4;
    final variants = controller.services; // Or variants state

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                leading: Container(
                  margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'srv_img_${service.id}',
                    child: _buildHeaderImage(service),
                  ),
                ),
              ),

              // Content details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100), // extra padding for bottom button
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          service.category.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Service Title & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontSize: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '\$${service.price.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Duration & Booking indicators
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated Time: ${service.durationHours} hrs',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.shield_outlined, color: AppTheme.success, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Odoo Certified',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: AppTheme.divider, height: 32),

                      // Description
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        service.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Divider(color: AppTheme.divider, height: 32),

                      // Checklist Section
                      Text(
                        "What's Included",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (service.whatsIncluded.isEmpty)
                        Text(
                          'Detailed multi-stage wash process and quality inspection.',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: service.whatsIncluded.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    service.whatsIncluded[index],
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomFooter(
        title: 'Est. ${service.durationHours} Hours',
        subtitle: '\$${service.price.toStringAsFixed(2)}',
        buttonText: 'BOOK THIS SERVICE',
        onPressed: () {
          final templateId = service.odooProductId ?? int.tryParse(service.id) ?? 4;
          final variants = controller.getVariantsForTemplate(templateId);
          final firstVar = variants.isNotEmpty ? variants.first : null;
          final targetService = service.copyWith(
            odooProductId: firstVar?.id ?? service.odooProductId,
            appointmentTypeId: firstVar?.appointmentType?.id ?? service.appointmentTypeId,
            appointmentResourceId: firstVar?.appointmentResource?.id ?? service.appointmentResourceId,
            price: (firstVar != null && firstVar.lstPrice > 0) ? firstVar.lstPrice : service.price,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookServiceScreen(initialService: targetService),
            ),
          );
        },
      ),
    );
  }
}
