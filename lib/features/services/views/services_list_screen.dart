import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_variants_screen.dart';

class ServicesListScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const ServicesListScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<ServicesController>(context);

    return Container(
      color: const Color(0xFFF9F7F4),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomAppBar(
              title: 'Services',
              subtitle: 'Explore our premium detailing packages',
              showBackButton: true,
              backIcon: Icons.arrow_back_sharp,
              onBackPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (onMenuTap != null) {
                  onMenuTap!();
                }
              },
            ),
            const SizedBox(height: 10),
            // Category chips
            if (controller.services.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: controller.categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = controller.categories[index];
                    final isSelected = controller.selectedCategory == cat;

                    return GestureDetector(
                      onTap: () => controller.selectCategory(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppTheme.background
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Catalog Listing
            Expanded(
              child: controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : controller.errorMessage != null
                  ? Center(
                      child: Text(
                        controller.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    )
                  : controller.filteredServices.isEmpty
                  ? const Center(
                      child: Text(
                        'No detailing services found in this category.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: controller.filteredServices.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final service = controller.filteredServices[index];
                        return GestureDetector(
                          onTap: () {
                            final templateId =
                                service.odooProductId ??
                                int.tryParse(service.id) ??
                                4;
                            debugPrint(
                              '🔵 [ServicesListScreen] Tapped service "${service.name}", opening ServiceVariantsScreen for templateId=$templateId',
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceVariantsScreen(
                                  parentService: service,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image top border rounded
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child:
                                      service.assetImagePath != null &&
                                          service.assetImagePath!.isNotEmpty
                                      ? Image.asset(
                                          service.assetImagePath!,
                                          height: 160,
                                          fit: BoxFit.cover,
                                        )
                                      : (service.imageUrl.startsWith('http')
                                            ? Image.network(
                                                service.imageUrl,
                                                height: 160,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      height: 160,
                                                      color:
                                                          AppTheme.surfaceLight,
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                        color: AppTheme.primary,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                height: 160,
                                                color: AppTheme.surfaceLight,
                                                child: const Icon(
                                                  Icons
                                                      .cleaning_services_rounded,
                                                  color: AppTheme.primary,
                                                  size: 40,
                                                ),
                                              )),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              service.name,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          ),
                                          Text(
                                            '\$${service.price.toStringAsFixed(2)}',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        service.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_filled,
                                            size: 16,
                                            color: AppTheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Est: ${service.durationHours} hrs',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Text(
                                                'Details',
                                                style: theme
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(fontSize: 12),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 10,
                                                color: AppTheme.primary,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
