import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_variant_model.dart';
import 'package:timeless_detailing_customer_app/features/services/views/service_interactive_detail_screen.dart';

class ServiceVariantsScreen extends StatefulWidget {
  final DetailService parentService;

  const ServiceVariantsScreen({
    super.key,
    required this.parentService,
  });

  @override
  State<ServiceVariantsScreen> createState() => _ServiceVariantsScreenState();
}

class _ServiceVariantsScreenState extends State<ServiceVariantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final templateId = widget.parentService.odooProductId ??
            int.tryParse(widget.parentService.id) ??
            4;
        debugPrint(
          '🔵 [ServiceVariantsScreen] Fetching variants for "${widget.parentService.name}" (templateId=$templateId)...',
        );
        Provider.of<ServicesController>(context, listen: false)
            .fetchVariants(templateId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final servicesController = Provider.of<ServicesController>(context);
    final templateId = widget.parentService.odooProductId ??
        int.tryParse(widget.parentService.id) ??
        4;

    // Get fetched variants from Odoo for this templateId
    final rawVariants = servicesController.getVariantsForTemplate(templateId);

    // Dynamic list of sub-services / variants
    final List<DetailService> displaySubServices = rawVariants.isNotEmpty
        ? rawVariants.map((v) => _mapVariantToDetailService(v, widget.parentService)).toList()
        : _generateDefaultSubServices(widget.parentService);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF3A2F1E),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),

              // Service Title ( Seriff Font matching Figma )
              Text(
                widget.parentService.name,
                style: GoogleFonts.lora(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3A2F1E),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              // Service Description / Subtitle
              Text(
                widget.parentService.description.isNotEmpty
                    ? widget.parentService.description
                    : 'Precision paint refinement services, tailored to your vehicle\'s condition. You can choose from below to look at what service you are looking for.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7A6F5D),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Grid of Sub-Service Variant Cards
              Expanded(
                child: servicesController.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      )
                    : GridView.builder(
                        itemCount: displaySubServices.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (context, index) {
                          final subService = displaySubServices[index];
                          return _buildVariantCard(context, subService);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantCard(BuildContext context, DetailService subService) {
    return GestureDetector(
      onTap: () {
        // On click of sub-service variant card, open dynamic interactive detailing screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceInteractiveDetailScreen(service: subService),
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / Art at Top Right (matching Figma)
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 70,
                height: 60,
                child: _buildSubServiceIcon(subService),
              ),
            ),
            const Spacer(),

            // Variant Sub-service Title at Bottom
            Text(
              subService.name,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3A2F1E),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subService.price > 0) ...[
              const SizedBox(height: 4),
              Text(
                '\$${subService.price.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubServiceIcon(DetailService subService) {
    if (subService.assetImagePath != null && subService.assetImagePath!.isNotEmpty) {
      return Image.asset(
        subService.assetImagePath!,
        fit: BoxFit.contain,
      );
    }
    return Icon(
      _getIconForServiceName(subService.name),
      size: 40,
      color: AppTheme.primary,
    );
  }

  IconData _getIconForServiceName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ppf') || lower.contains('protect')) {
      return Icons.shield_outlined;
    }
    if (lower.contains('paint') || lower.contains('enhancement') || lower.contains('correction')) {
      return Icons.auto_awesome_outlined;
    }
    if (lower.contains('interior')) {
      return Icons.airline_seat_recline_extra_outlined;
    }
    return Icons.directions_car_outlined;
  }

  DetailService _mapVariantToDetailService(ProductVariant v, DetailService parent) {
    return DetailService(
      id: v.id.toString(),
      name: v.displayName.isNotEmpty ? v.displayName : v.name,
      description: v.appointmentType?.messageIntro.isNotEmpty == true
          ? v.appointmentType!.messageIntro
          : parent.description,
      price: v.lstPrice > 0 ? v.lstPrice : parent.price,
      durationHours: v.appointmentType != null
          ? (v.appointmentType!.appointmentDuration / 60.0)
          : parent.durationHours,
      imageUrl: parent.imageUrl,
      category: parent.category,
      whatsIncluded: parent.whatsIncluded,
      odooProductId: v.id,
      appointmentTypeId: v.appointmentType?.id ?? parent.appointmentTypeId,
      assetImagePath: parent.assetImagePath,
    );
  }

  List<DetailService> _generateDefaultSubServices(DetailService parent) {
    final lower = parent.name.toLowerCase();
    if (lower.contains('paint') || lower.contains('enhancement')) {
      return [
        DetailService(
          id: '${parent.id}_1',
          name: 'Paint Enhancement',
          description: 'Single stage paint refinement removing light oxidation and fine swirls for maximum shine.',
          price: parent.price,
          durationHours: 3.0,
          imageUrl: '',
          category: parent.category,
          whatsIncluded: parent.whatsIncluded,
          odooProductId: parent.odooProductId,
          assetImagePath: 'assets/services/paint_care/paint_care.png',
        ),
        DetailService(
          id: '${parent.id}_2',
          name: 'Enhancement Plus',
          description: 'Dual stage polish eliminating up to 80% swirl defects and restoring mirror depth.',
          price: parent.price * 1.2,
          durationHours: 4.5,
          imageUrl: '',
          category: parent.category,
          whatsIncluded: parent.whatsIncluded,
          odooProductId: parent.odooProductId,
          assetImagePath: 'assets/services/paint_care/paint_care.png',
        ),
        DetailService(
          id: '${parent.id}_3',
          name: 'Paint Correction',
          description: 'Multi-stage deep compound and finish polish eliminating isolated scratches and heavy oxidation.',
          price: parent.price * 1.5,
          durationHours: 6.0,
          imageUrl: '',
          category: parent.category,
          whatsIncluded: parent.whatsIncluded,
          odooProductId: parent.odooProductId,
          assetImagePath: 'assets/services/paint_care/paint_care.png',
        ),
      ];
    }

    return [
      parent,
    ];
  }
}
