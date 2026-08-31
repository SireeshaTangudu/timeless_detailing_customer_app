import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_interactive_detail_screen.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/utils/app_animations.dart';

class ServicesListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const ServicesListScreen({super.key, this.onMenuTap});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ServicesController>(
        context,
        listen: false,
      );
      if (controller.services.isEmpty && !controller.isLoading) {
        controller.loadServices(categoryId: controller.selectedCategoryId);
      }
    });
  }

  Widget _buildChildServiceFullBleedImage(DetailService service) {
    final odooService = Provider.of<BaseOdooService>(context, listen: false);
    final baseUrl = odooService.baseUrl;

    Widget imageWidget;

    // 1. Base64 mobileImage string from Odoo API
    if (service.mobileImage != null &&
        service.mobileImage!.length > 100 &&
        !service.mobileImage!.startsWith('http')) {
      try {
        final bytes = base64Decode(service.mobileImage!);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {
        imageWidget = _buildFallbackChildServiceAsset(service);
      }
    } else {
      final rawImgUrl =
          (service.mobileImage != null && service.mobileImage!.isNotEmpty)
          ? service.mobileImage
          : (service.imageUrl.isNotEmpty ? service.imageUrl : null);

      if (rawImgUrl != null && rawImgUrl.isNotEmpty) {
        final fullUrl = rawImgUrl.startsWith('http')
            ? rawImgUrl
            : '$baseUrl$rawImgUrl';
        imageWidget = Image.network(
          fullUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackChildServiceAsset(service),
        );
      } else if (service.odooProductId != null) {
        final odooImgUrl =
            '$baseUrl/web/image?model=product.template&id=${service.odooProductId}&field=mobile_image';
        imageWidget = Image.network(
          odooImgUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackChildServiceAsset(service),
        );
      } else {
        imageWidget = _buildFallbackChildServiceAsset(service);
      }
    }

    return Hero(
      tag: 'service_image_${service.id}',
      child: imageWidget,
    );
  }

  Widget _buildFallbackChildServiceAsset(DetailService service) {
    if (service.assetImagePath != null && service.assetImagePath!.isNotEmpty) {
      return Image.asset(
        service.assetImagePath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(service.name),
      );
    }
    return _buildFallbackIcon(service.name);
  }

  Widget _buildFallbackIcon(String serviceName) {
    final lower = serviceName.toLowerCase();
    IconData iconData = Icons.auto_awesome_outlined;
    if (lower.contains('enhancement') || lower.contains('paint')) {
      iconData = Icons.directions_car_outlined;
    } else if (lower.contains('correction')) {
      iconData = Icons.auto_fix_high_outlined;
    } else if (lower.contains('interior') || lower.contains('seat')) {
      iconData = Icons.airline_seat_recline_extra_outlined;
    } else if (lower.contains('coat') || lower.contains('shield')) {
      iconData = Icons.shield_outlined;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1D1813),
      child: Center(
        child: Icon(iconData, size: 36, color: const Color(0xFFC4913F)),
      ),
    );
  }

  Widget _buildCategorySelectorRow(
    BuildContext context,
    ServicesController controller,
  ) {
    final categories = controller.categories;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final catName = categories[index];
          final isSelected = controller.selectedCategory == catName;

          return AnimatedPressable(
            onTap: () {
              controller.selectCategory(catName);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC4913F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFC4913F)
                      : const Color(0xFFEBE7DF),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFC4913F).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  catName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF5A5245),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ServicesController>(context);
    final selectedCategoryName = controller.selectedCategory;
    final displayServices = controller.filteredServices;

    return FullPageLoadingOverlay(
      isLoading: controller.isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F7F4),
        body: Column(
          children: [
            CustomAppBar(
              title: selectedCategoryName == 'All'
                  ? 'Services'
                  : selectedCategoryName,
              showBackButton: Navigator.canPop(context) || widget.onMenuTap != null,
              onBackPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (widget.onMenuTap != null) {
                  widget.onMenuTap!();
                }
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                // Category Selector Chips Row
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: _buildCategorySelectorRow(context, controller),
                ),
                const SizedBox(height: 20),

                // 2-Column Child Services Grid
                Expanded(
                  child: controller.errorMessage != null
                      ? Center(
                          child: Text(
                            controller.errorMessage!,
                            style: GoogleFonts.outfit(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : (displayServices.isEmpty && !controller.isLoading)
                      ? Center(
                          child: Text(
                            'No services available in this category.',
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              color: const Color(0xFF7A6F5D),
                            ),
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: displayServices.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.72,
                              ),
                          itemBuilder: (context, index) {
                            final childService = displayServices[index];
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 200 + (index * 60)),
                              slideOffset: const Offset(0, 0.1),
                              child: _buildChildServiceCard(context, childService),
                            );
                          },
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

  Widget _buildChildServiceCard(BuildContext context, DetailService service) {
    return AnimatedPressable(
      onTap: () {
        debugPrint(
          '🔵 [ServicesListScreen] Tapped child service "${service.name}", opening ServiceInteractiveDetailScreen...',
        );
        Navigator.push(
          context,
          FadeSlidePageRoute(
            page: ServiceInteractiveDetailScreen(service: service),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Full-bleed Service Image from Odoo API / Fallback
            Positioned.fill(
              child: _buildChildServiceFullBleedImage(service),
            ),

            // 2. Bottom Dark Gradient Overlay matching Dashboard
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(0xCC000000), // Dark gradient for white text legibility
                    ],
                  ),
                ),
              ),
            ),

            // 3. Service Title and Price at Bottom Left over dark gradient
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.name,
                    style: GoogleFonts.lora(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.price > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\$${service.price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC4913F),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
