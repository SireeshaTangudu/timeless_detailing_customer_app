import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';

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
    xFraction: 0.65,
    yFraction: 0.25,
  ),
  CarFocusPoint(
    id: 'driver_seat',
    title: 'Driver & Front Passenger',
    description:
        'Driver and front passenger seats, headrests, and adjustment controls are shampooed, extracted, and conditioned. Door panels, armrests, and grab handles are steam sanitized and dressed with premium interior protection.',
    xFraction: 0.29,
    yFraction: 0.46,
  ),
  CarFocusPoint(
    id: 'passenger_seat',
    title: 'Front Passenger Zone',
    description:
        'Passenger seat bolster, seams, floor mat, and footwell are deep-cleaned. Glove box, storage bins, and center console are wiped and sanitized. Cup holders receive dedicated stain-lifting treatment.',
    xFraction: 0.72,
    yFraction: 0.46,
  ),
  CarFocusPoint(
    id: 'rear_bench',
    title: 'Rear Passengers',
    description:
        'Rear bench seats, headrests, and armrests are shampooed and extracted. Rear vents, window controls, seat-back pockets, and door bins are steam-cleaned; carpet and floor mats are pressure-washed and dried.',
    xFraction: 0.50,
    yFraction: 0.64,
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
    return Scaffold(
      backgroundColor: AppTheme.isDark
          ? const Color(0xFF0C0C0E)
          : const Color(0xFFF9F9FB),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: Container(
                  margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color:
                        (AppTheme.isDark
                                ? const Color(0xFF16161A)
                                : Colors.white)
                            .withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFFC4913F),
                      size: 16,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: Text(
                  'Interior Detailing',
                  style: AppTypography.canela(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                backgroundColor: AppTheme.isDark
                    ? const Color(0xFF0C0C0E)
                    : const Color(0xFFF9F9FB),
                elevation: 0,
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interior Detailing',
                        style: AppTypography.canela(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your vehicle\u2019s interior is where you spend every journey, and it deserves the same level of care as its exterior. Our Interior Detail is a multi-stage clean, disinfect, and condition process designed to refresh seats, carpets, textiles, plastics, and leathers using only premium materials.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Using professional techniques and premium products, we meticulously clean every crevice, corner, surface, seam, headliner, panel, vent, cup holder, console, storage area, and passenger compartment\u2014with particular attention to reach-in areas, floor mats, and under-seat environments.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where We Focus Inside',
                        style: AppTypography.canela(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Vehicle',
                        style: AppTypography.canela(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap a gold dot to see what\u2019s detailed in each area.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _CarViewWithHotspots(
                    points: _interiorFocusPoints,
                    selected: _selectedPoint,
                    onPointSelected: (point) {
                      setState(() {
                        _selectedPoint = _selectedPoint?.id == point.id
                            ? null
                            : point;
                      });
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: _SelectedPointCard(point: _selectedPoint),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'And on top of all that, this service will:',
                        style: AppTypography.canela(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ..._buildBulletList(_serviceBenefits),
                      const SizedBox(height: 24),
                      Text(
                        'Techniques We Use',
                        style: AppTypography.canela(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ..._buildBulletList(_professionalTechniques),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.isDark
                    ? const Color(0xFF0C0C0E)
                    : const Color(0xFFF9F9FB),
                border: Border(
                  top: BorderSide(color: AppTheme.divider, width: 1),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'BOOK INTERIOR DETAIL',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                  color: Color(0xFFC4913F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                e,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
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
  final ValueChanged<CarFocusPoint> onPointSelected;

  const _CarViewWithHotspots({
    required this.points,
    required this.selected,
    required this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.isDark
            ? const Color(0xFF16161A)
            : const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ClipRRect(
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
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/car_view.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (selectedPoint != null)
                    _buildFloatingTooltip(
                      point: selectedPoint,
                      canvasWidth: w,
                      canvasHeight: h,
                      onClose: () => onPointSelected(selectedPoint),
                    ),
                  ...points.map((point) {
                    final isSelected = selected?.id == point.id;
                    return _buildHotspot(
                      point: point,
                      isSelected: isSelected,
                      onTap: () => onPointSelected(point),
                    );
                  }),
                ],
              );
            },
          ),
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
            color: const Color(0xFFC4913F).withOpacity(0.96),
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
    if (point == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.isDark ? const Color(0xFF16161A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap a gold dot on the car to see what we detail in that area.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final p = point!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC4913F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC4913F).withOpacity(0.35)),
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
                  style: AppTypography.canela(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
