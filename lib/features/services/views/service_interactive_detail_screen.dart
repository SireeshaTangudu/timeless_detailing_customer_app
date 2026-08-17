import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/book_service_screen.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_footer.dart';
import 'package:timeless_detailing_customer_app/features/services/views/interior_detailing_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';

class CarFocusPoint {
  final String id;
  final String title;
  final String description;
  final double xFraction;
  final double yFraction;
  final String? viewImageUrl;
  final String? view;
  final int? productId;

  const CarFocusPoint({
    required this.id,
    required this.title,
    required this.description,
    required this.xFraction,
    required this.yFraction,
    this.viewImageUrl,
    this.view,
    this.productId,
  });
}

class ServiceInteractiveDetailScreen extends StatefulWidget {
  final DetailService service;
  final List<CarFocusPoint>? focusPoints;

  const ServiceInteractiveDetailScreen({
    super.key,
    required this.service,
    this.focusPoints,
  });

  @override
  State<ServiceInteractiveDetailScreen> createState() =>
      _ServiceInteractiveDetailScreenState();
}

class _ServiceInteractiveDetailScreenState
    extends State<ServiceInteractiveDetailScreen> {
  CarFocusPoint? _selectedPoint;
  int? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    if (widget.service.variants.isNotEmpty) {
      _selectedVariantId = widget.service.variants.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final templateId =
            widget.service.odooProductId ??
            int.tryParse(widget.service.id) ??
            4;
        debugPrint(
          '🔵 [ServiceInteractiveDetailScreen] Fetching variants for "${widget.service.name}" (templateId=$templateId)...',
        );
        final controller = Provider.of<ServicesController>(
          context,
          listen: false,
        );
        controller.fetchVariants(templateId).then((_) {
          if (mounted && _selectedVariantId == null) {
            final fetched = controller.getVariantsForTemplate(templateId);
            if (fetched.isNotEmpty) {
              setState(() {
                _selectedVariantId = fetched.first.id;
              });
            }
          }
        });
      }
    });
  }

  List<CarFocusPoint> get _activeFocusPoints {
    if (widget.focusPoints != null && widget.focusPoints!.isNotEmpty) {
      return widget.focusPoints!;
    }
    if (widget.service.coverageLines.isNotEmpty) {
      final selectedVarId = _selectedVariantId;
      var lines = widget.service.coverageLines.where((line) {
        if (selectedVarId != null && line.productId != null) {
          return line.productId == selectedVarId;
        }
        return true;
      }).toList();

      if (lines.isEmpty && widget.service.coverageLines.isNotEmpty) {
        lines = widget.service.coverageLines;
      }

      return lines.map((line) {
        return CarFocusPoint(
          id: line.id.toString(),
          title: line.title,
          description:
              line.description ?? '${line.title} is covered by this treatment.',
          xFraction: line.xPercent / 100.0,
          yFraction: line.yPercent / 100.0,
          viewImageUrl: line.viewImageUrl,
          view: line.view,
          productId: line.productId,
        );
      }).toList();
    }
    return const [];
  }

  String _cleanHtml(String rawHtml) {
    return rawHtml
        .replaceAll(RegExp(r'<p[^>]*>'), '')
        .replaceAll('</p>', '\n\n')
        .replaceAll(RegExp(r'<div[^>]*>'), '')
        .replaceAll('</div>', '\n')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final servicesController = Provider.of<ServicesController>(context);
    final fetchedVariants = servicesController.getVariantsForTemplate(
      service.odooProductId ?? int.tryParse(service.id) ?? 4,
    );
    final allVariants = service.variants.isNotEmpty
        ? service.variants
        : fetchedVariants;

    if (allVariants.isNotEmpty) {
      if (_selectedVariantId == null ||
          !allVariants.any((v) => v.id == _selectedVariantId)) {
        _selectedVariantId = allVariants.first.id;
      }
    }

    final selectedVariant = allVariants.firstWhere(
      (v) => v.id == _selectedVariantId,
      orElse: () => allVariants.isNotEmpty
          ? allVariants.first
          : ProductVariant(
              id: 0,
              name: service.name,
              displayName: service.name,
              lstPrice: service.price,
              variantValues: [],
            ),
    );

    final isExterior =
        !service.name.toLowerCase().contains('interior') &&
        !service.name.toLowerCase().contains('leather');

    final focusPoints = _activeFocusPoints;
    final selectedPoint = _selectedPoint;

    // Determine features to show
    final featuresToShow = selectedVariant.featureLines.isNotEmpty
        ? selectedVariant.featureLines
        : service.whatsIncluded;

    // Intro text extraction matching Figma
    String introText = '';
    if (selectedVariant.pageIntro != null &&
        selectedVariant.pageIntro!.isNotEmpty) {
      introText = _cleanHtml(selectedVariant.pageIntro!);
    } else if (selectedVariant.pageTagline != null &&
        selectedVariant.pageTagline!.isNotEmpty) {
      introText = selectedVariant.pageTagline!;
    } else if (service.description.isNotEmpty) {
      introText = _cleanHtml(service.description);
    }

    final displayPrice = selectedVariant.lstPrice > 0
        ? selectedVariant.lstPrice
        : service.price;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_selectedPoint != null) {
          setState(() {
            _selectedPoint = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F7F4),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar with Circular Back Button matching Figma
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
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

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title in Elegant Serif (matching Figma)
                      Text(
                        service.name,
                        style: GoogleFonts.lora(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3A2F1E),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Dynamic Intro Paragraphs matching Figma
                      if (introText.isNotEmpty) ...[
                        Text(
                          introText,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF5A5245),
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Parts where it effects Section (Variant Package Chips if multiple variants)
                      if (allVariants.length > 1) ...[
                        Text(
                          'Where We Focus Inside Your Vehicle',
                          style: GoogleFonts.lora(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3A2F1E),
                          ),
                        ),
                        const SizedBox(height: 14),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: allVariants.map((v) {
                              final isSel = _selectedVariantId == v.id;
                              String cleanName = v.displayName;
                              if (cleanName.contains('(') &&
                                  cleanName.endsWith(')')) {
                                final parts = cleanName.split('(');
                                if (parts.length >= 3) {
                                  cleanName = parts.last
                                      .replaceAll(')', '')
                                      .trim();
                                } else if (parts.length == 2) {
                                  cleanName = parts[1]
                                      .replaceAll(')', '')
                                      .trim();
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    cleanName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: isSel
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSel
                                          ? Colors.white
                                          : const Color(0xFF3A2F1E),
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: const Color(0xFFC4913F),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSel
                                          ? const Color(0xFFC4913F)
                                          : const Color(0xFFEBE7DF),
                                    ),
                                  ),
                                  showCheckmark: false,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedVariantId = v.id;
                                        _selectedPoint = null;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Hotspot Car Diagram with view_image_url Key
                      if (focusPoints.isNotEmpty) ...[
                        _CarViewWithHotspots(
                          points: focusPoints,
                          selected: selectedPoint,
                          isExterior: isExterior,
                          onPointSelected: (point) {
                            setState(() {
                              _selectedPoint = point;
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Dynamic Feature Benefits Section from Odoo API
                      if (featuresToShow.isNotEmpty) ...[
                        Text(
                          'Why Choose ${service.name}',
                          style: GoogleFonts.lora(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3A2F1E),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._buildBulletList(featuresToShow),
                        const SizedBox(height: 28),
                      ],

                      // Other Protection Services Carousel matching Figma
                      _buildOtherServicesCarousel(context, service),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomFooter(
          backgroundColor: const Color(0xFF1D1813),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          leading: Text(
            displayPrice > 0
                ? 'Prices starting from \$${displayPrice.toStringAsFixed(0)}'
                : 'Price on enquiry',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          trailing: SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookServiceScreen(initialService: service),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4913F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Book Now!',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherServicesCarousel(
    BuildContext context,
    DetailService currentService,
  ) {
    final controller = Provider.of<ServicesController>(context, listen: false);
    final otherServices = controller.filteredServices
        .where((s) => s.id != currentService.id)
        .toList();

    if (otherServices.isEmpty) return const SizedBox.shrink();

    final categoryTitle = controller.selectedCategory != 'All'
        ? controller.selectedCategory.toLowerCase()
        : 'paint care';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other $categoryTitle services\nyou can explore',
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3A2F1E),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: otherServices.length,
            itemBuilder: (context, index) {
              final other = otherServices[index];
              return GestureDetector(
                onTap: () {
                  if (other.name.toLowerCase().contains('interior')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InteriorDetailingScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ServiceInteractiveDetailScreen(service: other),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEBE7DF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: SizedBox(
                          width: 60,
                          height: 45,
                          child: _buildOtherServiceImage(other),
                        ),
                      ),
                      Text(
                        other.name,
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3A2F1E),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        other.price > 0
                            ? '\$${other.price.toStringAsFixed(0)}'
                            : 'Enquire',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC4913F),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtherServiceImage(DetailService service) {
    const baseUrl =
        'https://keerthan-lfi-lfi-timeless-detailing-uat-36441944.dev.odoo.com';

    // 1. Base64 mobileImage string from Odoo API
    if (service.mobileImage != null &&
        service.mobileImage!.length > 100 &&
        !service.mobileImage!.startsWith('http')) {
      try {
        final bytes = base64Decode(service.mobileImage!);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {}
    }

    // 2. Relative / Absolute image URL from API response
    final rawImgUrl =
        (service.mobileImage != null && service.mobileImage!.isNotEmpty)
        ? service.mobileImage
        : (service.imageUrl.isNotEmpty ? service.imageUrl : null);

    if (rawImgUrl != null && rawImgUrl.isNotEmpty) {
      final fullUrl = rawImgUrl.startsWith('http')
          ? rawImgUrl
          : '$baseUrl$rawImgUrl';
      return Image.network(
        fullUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackOtherServiceIcon(service),
      );
    }

    // 3. Odoo product.template REST endpoint
    if (service.odooProductId != null) {
      final odooImgUrl =
          '$baseUrl/web/image?model=product.template&id=${service.odooProductId}&field=mobile_image';
      return Image.network(
        odooImgUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackOtherServiceIcon(service),
      );
    }

    return _buildFallbackOtherServiceIcon(service);
  }

  Widget _buildFallbackOtherServiceIcon(DetailService service) {
    if (service.assetImagePath != null && service.assetImagePath!.isNotEmpty) {
      return Image.asset(
        service.assetImagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.directions_car_outlined,
          size: 24,
          color: Color(0xFFC4913F),
        ),
      );
    }
    return const Icon(
      Icons.directions_car_outlined,
      size: 24,
      color: Color(0xFFC4913F),
    );
  }

  List<Widget> _buildBulletList(List<String> items) {
    return items.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF3A2F1E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                e,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF3A2F1E),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _CarViewWithHotspots extends StatelessWidget {
  final List<CarFocusPoint> points;
  final CarFocusPoint? selected;
  final ValueChanged<CarFocusPoint?> onPointSelected;
  final bool isExterior;

  const _CarViewWithHotspots({
    required this.points,
    required this.selected,
    required this.onPointSelected,
    this.isExterior = true,
  });

  Widget _buildVehicleImage(String? rawViewImageUrl, double w, double h) {
    if (rawViewImageUrl != null && rawViewImageUrl.isNotEmpty) {
      final fullUrl = rawViewImageUrl.startsWith('http')
          ? rawViewImageUrl
          : 'https://keerthan-lfi-lfi-timeless-detailing-uat-36441944.dev.odoo.com$rawViewImageUrl';

      return Image.network(
        fullUrl,
        fit: BoxFit.contain,
        width: w,
        height: h,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(w, h),
      );
    }
    return _buildFallbackAsset(w, h);
  }

  Widget _buildFallbackAsset(double w, double h) {
    return Image.asset(
      isExterior
          ? 'assets/services/paint_care/paint_care.png'
          : 'assets/services/interior/interior_detailing.png',
      fit: BoxFit.contain,
      width: w * 0.52,
      height: h * 0.85,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          isExterior ? Icons.directions_car : Icons.airline_seat_recline_extra,
          size: 110,
          color: const Color(0xFFC4913F).withValues(alpha: 0.3),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String? viewImageUrl;
    if (selected?.viewImageUrl != null && selected!.viewImageUrl!.isNotEmpty) {
      viewImageUrl = selected!.viewImageUrl;
    } else if (points.isNotEmpty) {
      for (final p in points) {
        if (p.viewImageUrl != null && p.viewImageUrl!.isNotEmpty) {
          viewImageUrl = p.viewImageUrl;
          break;
        }
      }
    }

    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE7DF), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Tapping anywhere on vehicle container closes the callout box if open
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPointSelected(null),
                ),
              ),

              // Vehicle Diagram rendered using view_image_url key from Odoo API
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _buildVehicleImage(viewImageUrl, w, h),
                ),
              ),

              // Interactive Hotspot Coordinate Dots (x_percent, y_percent) over view_image_url
              ...points.map((p) {
                final isSel = selected?.id == p.id;
                final left = p.xFraction * w - 10;
                final top = p.yFraction * h - 10;

                return Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onTap: () => onPointSelected(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSel ? 22 : 18,
                      height: isSel ? 22 : 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC4913F),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Gold Overlay Callout Box matching Figma (anchored outside vehicle image)
              if (selected != null)
                Builder(
                  builder: (context) {
                    const calloutWidth = 145.0;
                    final dotX = selected!.xFraction * w;
                    final dotY = selected!.yFraction * h;

                    // Place callout panel in outer margin outside of vehicle image
                    double calloutLeft;
                    if (dotX > w * 0.7) {
                      calloutLeft = 10.0;
                    } else {
                      calloutLeft = w - calloutWidth - 10.0;
                    }

                    double calloutTop = (dotY - 20.0).clamp(10.0, h - 140.0);

                    return Positioned(
                      left: calloutLeft,
                      top: calloutTop,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: calloutWidth,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB58A4C),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selected!.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selected!.description,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  height: 1.35,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
