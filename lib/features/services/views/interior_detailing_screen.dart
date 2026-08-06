import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_footer.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/book_service_screen.dart';

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

const List<CarFocusPoint> _interiorFocusPoints = [
  CarFocusPoint(
    id: 'dashboard',
    title: 'Dashboard',
    description:
        'Dashboard, vents, AC controls, door panels, steering, trunk, floor mats, carpet, headlining, and all interior touchpoints. Every detail is carefully addressed to ensure a clean, fresh, and refined cabin environment.',
    xFraction: 0.50,
    yFraction: 0.36,
  ),
  CarFocusPoint(
    id: 'center_console',
    title: 'Center Console',
    description:
        'Center console, gear shifter, cup holders, and storage compartments are deep cleaned, steam sanitized, and dressed with non-greasy UV protection.',
    xFraction: 0.50,
    yFraction: 0.44,
  ),
  CarFocusPoint(
    id: 'front_seats',
    title: 'Front Seats',
    description:
        'Driver and front passenger seats, headrests, and adjustment controls are shampooed, extracted, and conditioned with pH-balanced leather/fabric care.',
    xFraction: 0.54,
    yFraction: 0.50,
  ),
  CarFocusPoint(
    id: 'side_door',
    title: 'Door Panels',
    description:
        'Door panels and interior plastics are cleaned and restored, removing grime from every touchpoint.',
    xFraction: 0.28,
    yFraction: 0.58,
  ),
  CarFocusPoint(
    id: 'rear_bench',
    title: 'Rear Passengers',
    description:
        'Rear bench seats, headrests, and armrests are shampooed and extracted. Rear vents, window controls, seat-back pockets, and door bins are steam-cleaned; carpet and floor mats are pressure-washed and dried.',
    xFraction: 0.50,
    yFraction: 0.62,
  ),
];

class InteriorDetailingScreen extends StatefulWidget {
  const InteriorDetailingScreen({super.key});

  @override
  State<InteriorDetailingScreen> createState() =>
      _InteriorDetailingScreenState();
}

class _InteriorDetailingScreenState extends State<InteriorDetailingScreen> {
  CarFocusPoint? _selectedPoint;

  List<String> _serviceBenefits = [
    'Restores your vehicle\u2019s interior to a clean, showroom-quality finish',
    'Removes built-up dirt, oils, dust, and contaminants',
    'Treats leather, vinyl, plastics, and fabrics with pH-balanced products',
    'Deodorizes the cabin and removes minor smells',
    'Protects trim and upholstery from sun damage, fading, and cracking',
  ];

  List<String> _professionalTechniques = [
    'High-suction HEPA extraction carpet shampoo',
    'Hot water extractor with stain-lifting pre-sprays',
    'Interior steam clean on vinyl, plastic, and trim',
    'Leather conditioning, microfiber dressing, and satin finishes',
    'Air pressure detailing for vents, buttons, and crevices',
  ];

  @override
  Widget build(BuildContext context) {
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
              title: 'Interior Detailing',
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
                    // Intro Description Paragraph 1
                    Text(
                      "Your vehicle's interior is where you spend every journey, and it deserves the same level of care as its exterior. Our Interior Detailing is a comprehensive restoration service designed to deep clean, sanitize, and rejuvenate every interior surface while preserving the original materials.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF3A2F1E),
                        height: 1.5,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Intro Description Paragraph 2
                    Text(
                      "Using professional techniques and premium products, we meticulously clean carpets, upholstery, leather, plastics, trim, vents, cup holders, door panels, headlining, and all interior touchpoints. Every detail is carefully addressed to restore a clean, fresh, and refined cabin environment.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF3A2F1E),
                        height: 1.5,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Where We Focus Inside Your Vehicle Heading
                    Text(
                      'Where We Focus Inside Your Vehicle',
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3A2F1E),
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Hotspot interactive Car diagram
                    _CarViewWithHotspots(
                      points: _interiorFocusPoints,
                      selected: _selectedPoint,
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
                      _SelectedPointCard(point: _selectedPoint),
                    const SizedBox(height: 28),

                    // Service Benefits Header
                    Text(
                      'And on top of all that, this service will...',
                      style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        color: const Color(0xFF3A2F1E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._buildBulletList(_serviceBenefits),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomFooter(
          title: 'Fares starting from R 2800',
          subtitle: 'View breakup’s',
          buttonText: 'BOOK Now',
          backgroundColor: const Color(0XFF121212),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookServiceScreen(
                  initialService: DetailService(
                    id: '1',
                    name: 'Interior Detailing',
                    description:
                        'Comprehensive interior restoration and deep steam clean service.',
                    price: 199.0,
                    durationHours: 3.5,
                    imageUrl: '',
                    category: 'Interior',
                    whatsIncluded: [
                      'Carpets & Upholstery Deep Steam Cleaning',
                      'Leather Conditioning & UV Protection',
                      'Dashboard, Vents & Console Sanitization',
                      'Door Jambs, Trim & Cup Holder Detailing',
                      'Odor Elimination & Air Refreshener',
                    ],
                    assetImagePath:
                        'assets/services/interior/interior_detailing.png',
                  ),
                ),
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
            Padding(
              padding: const EdgeInsets.only(top: 4.5),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF3A2F1E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                e,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Color(0XFF3A2F1E),
                  height: 1.45,
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

  const _CarViewWithHotspots({
    required this.points,
    required this.selected,
    required this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 3 / 4.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final selectedPoint = selected;
            return Stack(
              children: [
                // Background Car Image with Tap Outside Listener
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPointSelected(null),
                    child: Image.asset(
                      'assets/images/car_view.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Render ALL hotspot dots (All dots remain visible when a card is selected)
                ...points.map((point) {
                  final isSelected = selected?.id == point.id;
                  return _buildHotspot(
                    point: point,
                    isSelected: isSelected,
                    onTap: () => onPointSelected(isSelected ? null : point),
                  );
                }),
                // Floating tooltip card on top of image
                if (selectedPoint != null)
                  _buildFloatingTooltip(
                    point: selectedPoint,
                    canvasWidth: w,
                    canvasHeight: h,
                    onClose: () => onPointSelected(null),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingTooltip({
    required CarFocusPoint point,
    required double canvasWidth,
    required double canvasHeight,
    required VoidCallback onClose,
  }) {
    const tooltipWidth = 180.0;
    const tooltipHeight = 140.0;
    const dotCenterOffset = 22.0;

    var left = point.xFraction * canvasWidth + dotCenterOffset;
    var top = point.yFraction * canvasHeight - tooltipHeight * 0.5;

    if (left + tooltipWidth > canvasWidth - 8) {
      left = point.xFraction * canvasWidth - tooltipWidth - dotCenterOffset;
    }
    if (left < 8) left = 8;
    if (top < 8) top = 8;
    if (top + tooltipHeight > canvasHeight - 8) {
      top = canvasHeight - tooltipHeight - 8;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFAB8C5A).withOpacity(0.96),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
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
                point.title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                point.description,
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.92),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotspot({
    required CarFocusPoint point,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Align(
        alignment: FractionalOffset(point.xFraction, point.yFraction),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: _HotspotDot(
            key: ValueKey('hotspot_${point.id}'),
            label: point.title,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}

class _HotspotDot extends StatefulWidget {
  final String label;
  final bool isSelected;

  const _HotspotDot({super.key, required this.label, required this.isSelected});

  @override
  State<_HotspotDot> createState() => _HotspotDotState();
}

class _HotspotDotState extends State<_HotspotDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);
    _pulse = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!widget.isSelected)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Transform.scale(
                  scale: 1 + (t * 1.4),
                  child: Opacity(
                    opacity: (1 - t) * 0.45,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC4913F),
                      ),
                    ),
                  ),
                );
              },
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: widget.isSelected ? 22 : 14,
            height: widget.isSelected ? 22 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isSelected
                  ? const Color(0xFFC4913F)
                  : const Color(0xFFC4913F),
              border: Border.all(
                color: Colors.white,
                width: widget.isSelected ? 3.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPointCard extends StatelessWidget {
  final CarFocusPoint? point;

  const _SelectedPointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    if (point == null) return const SizedBox.shrink();
    final p = point!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC4913F).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC4913F).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC4913F),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.title,
                  style: GoogleFonts.lora(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A2F1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF5A5245),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
