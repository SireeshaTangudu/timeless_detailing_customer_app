import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_interactive_detail_screen.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
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

  Widget _buildChildServiceIcon(DetailService service) {
    const baseUrl =
        'https://keerthan-lfi-lfi-timeless-detailing-uat-36441944.dev.odoo.com';

    Widget imageWidget;

    // 1. Base64 mobileImage string from Odoo API
    if (service.mobileImage != null &&
        service.mobileImage!.length > 100 &&
        !service.mobileImage!.startsWith('http')) {
      try {
        final bytes = base64Decode(service.mobileImage!);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
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
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackChildServiceAsset(service),
        );
      } else if (service.odooProductId != null) {
        final odooImgUrl =
            '$baseUrl/web/image?model=product.template&id=${service.odooProductId}&field=mobile_image';
        imageWidget = Image.network(
          odooImgUrl,
          fit: BoxFit.contain,
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
        fit: BoxFit.contain,
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
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, size: 30, color: const Color(0xFFC4913F)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ServicesController>(context);
    final selectedCategoryName = controller.selectedCategory;
    final displayServices = controller.filteredServices;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Circular Back Button matching Figma
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedPressable(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else if (widget.onMenuTap != null) {
                          widget.onMenuTap!();
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFAB8C5A),
                            width: 1.2,
                          ),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Color(0xFFAB8C5A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Parent Service / Category Title in Elegant Serif
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  selectedCategoryName == 'All'
                      ? 'Services'
                      : selectedCategoryName,
                  style: GoogleFonts.lora(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3A2F1E),
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2-Column Child Services Grid
              Expanded(
                child: controller.isLoading
                    ? const FourRotatingDotsLoader()
                    : controller.errorMessage != null
                    ? Center(
                        child: Text(
                          controller.errorMessage!,
                          style: GoogleFonts.outfit(
                            color: AppTheme.error,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : displayServices.isEmpty
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBE7DF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Right Illustration / Icon (Matching Figma)
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 98,
                height: 78,
                child: _buildChildServiceIcon(service),
              ),
            ),
            const Spacer(),

            // Service Title at Bottom Left in Elegant Serif
            Text(
              service.name,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3A2F1E),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC4913F),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
