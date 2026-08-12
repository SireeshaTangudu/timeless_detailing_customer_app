import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_footer.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/book_service_screen.dart';
import 'package:timeless_detailing_customer_app/features/services/controllers/services_controller.dart';

class CarFocusPoint {
  final String id;
  final String title;
  final String description;
  final double xFraction;
  final double yFraction;

  const CarFocusPoint({
    required this.id,
    required this.title,
    required this.description,
    required this.xFraction,
    required this.yFraction,
  });
}

const List<CarFocusPoint> _defaultInteriorFocusPoints = [
  CarFocusPoint(
    id: 'dashboard',
    title: 'Dashboard & Vents',
    description:
        'Dashboard, vents, AC controls, door panels, steering, trunk, floor mats, carpet, headlining, and all interior touchpoints.',
    xFraction: 0.50,
    yFraction: 0.36,
  ),
  CarFocusPoint(
    id: 'center_console',
    title: 'Center Console',
    description:
        'Center console, gear shifter, cup holders, and storage compartments are deep cleaned, steam sanitized, and dressed with UV protection.',
    xFraction: 0.50,
    yFraction: 0.44,
  ),
  CarFocusPoint(
    id: 'front_seats',
    title: 'Seats & Upholstery',
    description:
        'Driver and passenger seats, headrests, and adjustment controls are shampooed, extracted, and conditioned with leather care.',
    xFraction: 0.54,
    yFraction: 0.50,
  ),
  CarFocusPoint(
    id: 'side_door',
    title: 'Door Panels & Trim',
    description:
        'Door panels and interior plastics are cleaned and restored, removing grime from every touchpoint.',
    xFraction: 0.28,
    yFraction: 0.58,
  ),
  CarFocusPoint(
    id: 'rear_bench',
    title: 'Rear Cabin & Trunk',
    description:
        'Rear bench seats, headrests, rear vents, window controls, and floor mats are pressure-washed, extracted, and dried.',
    xFraction: 0.50,
    yFraction: 0.62,
  ),
];

const List<CarFocusPoint> _defaultExteriorFocusPoints = [
  CarFocusPoint(
    id: 'hood_paint',
    title: 'Hood & Front Bumper',
    description:
        'Multi-stage decontamination wash, clay bar paint purification, and swirl-reduction machine polishing.',
    xFraction: 0.50,
    yFraction: 0.25,
  ),
  CarFocusPoint(
    id: 'roof_glass',
    title: 'Roof & Windshield',
    description:
        'Hydrophobic glass rain-shield treatment and high-gloss paint correction removing oxidation.',
    xFraction: 0.50,
    yFraction: 0.45,
  ),
  CarFocusPoint(
    id: 'wheels_tires',
    title: 'Wheels & Ceramic Coating',
    description:
        'Brake dust decontamination, iron remover bath, high-temp ceramic coating, and tire satin dressing.',
    xFraction: 0.25,
    yFraction: 0.65,
  ),
  CarFocusPoint(
    id: 'rear_bumper',
    title: 'Rear Trunk & Diffuser',
    description:
        'Tailgate polishing, emblem detailing, exhaust tip restoration, and ceramic paint protection film layer.',
    xFraction: 0.50,
    yFraction: 0.80,
  ),
];

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final templateId = widget.service.odooProductId ??
            int.tryParse(widget.service.id) ??
            4;
        debugPrint(
          '🔵 [ServiceInteractiveDetailScreen] Fetching variants for "${widget.service.name}" (templateId=$templateId)...',
        );
        Provider.of<ServicesController>(context, listen: false)
            .fetchVariants(templateId);
      }
    });
  }

  List<CarFocusPoint> get _activeFocusPoints {
    if (widget.focusPoints != null && widget.focusPoints!.isNotEmpty) {
      return widget.focusPoints!;
    }
    final lowerName = widget.service.name.toLowerCase();
    if (lowerName.contains('paint') ||
        lowerName.contains('ppf') ||
        lowerName.contains('exterior') ||
        lowerName.contains('care') ||
        lowerName.contains('protection')) {
      return _defaultExteriorFocusPoints;
    }
    return _defaultInteriorFocusPoints;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final isExterior = widget.service.category.toLowerCase().contains('exterior') ||
        widget.service.name.toLowerCase().contains('paint') ||
        widget.service.name.toLowerCase().contains('ppf') ||
        widget.service.name.toLowerCase().contains('protection');

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_selectedPoint != null) {
          setState(() {
            _selectedPoint = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F7F4),
        body: Column(
          children: [
            CustomAppBar(
              title: service.name,
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Service Description
                    Text(
                      service.description.isNotEmpty
                          ? service.description
                          : 'Comprehensive professional detailing treatment for exceptional vehicle restoration and protection.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF3A2F1E),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Heading
                    Text(
                      isExterior
                          ? 'Where We Focus On Your Vehicle'
                          : 'Where We Focus Inside Your Vehicle',
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3A2F1E),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Hotspot interactive Car diagram
                    _CarViewWithHotspots(
                      points: _activeFocusPoints,
                      selected: _selectedPoint,
                      isExterior: isExterior,
                      onPointSelected: (point) {
                        setState(() {
                          if (_selectedPoint?.id == point?.id) {
                            _selectedPoint = null;
                          } else {
                            _selectedPoint = point;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedPoint != null)
                      _SelectedPointCard(point: _selectedPoint!),
                    const SizedBox(height: 28),

                    // Dynamic What's Included / Benefits Header
                    Text(
                      'What\'s Included in This Treatment',
                      style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3A2F1E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._buildBulletList(service.whatsIncluded.isNotEmpty
                        ? service.whatsIncluded
                        : [
                            'Restores your vehicle to a clean, showroom-quality finish',
                            'Removes built-up dirt, oils, dust, and contaminants',
                            'Treats sensitive vehicle materials with pH-balanced products',
                            'Deodorizes the cabin and removes minor smells',
                            'Protects surfaces from UV sun damage, fading, and cracking',
                          ]),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomFooter(
          title: service.price > 0
              ? 'Fares starting from \$${service.price.toStringAsFixed(0)}'
              : 'Fares starting from R 2800',
          subtitle: 'View breakup\'s',
          buttonText: 'BOOK NOW',
          backgroundColor: const Color(0xFF121212),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookServiceScreen(initialService: service),
              ),
            );
          },
        ),
      ),
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
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF9E8A78),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                e,
                style: GoogleFonts.inter(
                  fontSize: 14,
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
    this.isExterior = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.45,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFE9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5DDD0),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                Center(
                  child: Image.asset(
                    isExterior
                        ? 'assets/services/paint_care/paint_care.png'
                        : 'assets/services/interior/interior_detailing.png',
                    fit: BoxFit.contain,
                    width: w * 0.85,
                    height: h * 0.85,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        isExterior ? Icons.directions_car : Icons.airline_seat_recline_extra,
                        size: 100,
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      );
                    },
                  ),
                ),
                ...points.map((p) {
                  final isSel = selected?.id == p.id;
                  final left = p.xFraction * w - 16;
                  final top = p.yFraction * h - 16;

                  return Positioned(
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onTap: () => onPointSelected(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSel ? 36 : 30,
                        height: isSel ? 36 : 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel
                              ? const Color(0xFFB8976C)
                              : const Color(0xFF9E8A78).withValues(alpha: 0.85),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isSel ? Icons.check : Icons.add,
                            size: isSel ? 18 : 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectedPointCard extends StatelessWidget {
  final CarFocusPoint point;

  const _SelectedPointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECE5DA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD3C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.center_focus_strong,
                color: Color(0xFF9E8A78),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                point.title,
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A2F1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            point.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF5A4D3B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
