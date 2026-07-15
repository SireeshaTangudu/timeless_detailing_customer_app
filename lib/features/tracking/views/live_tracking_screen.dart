import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/tracking_controller.dart';

class LiveTrackingScreen extends StatefulWidget {
  final Booking booking;

  const LiveTrackingScreen({super.key, required this.booking});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize tracking status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TrackingController>(context, listen: false)
          .fetchTrackingStatus(widget.booking.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracking = Provider.of<TrackingController>(context);
    final activeBooking = tracking.trackedBooking ?? widget.booking;

    // Detailing Stepper Stages
    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Scheduled & Confirmed',
        'subtitle': 'Appointment verified in Odoo ERP',
        'icon': Icons.calendar_today_outlined,
      },
      {
        'title': 'Vehicle Checked In',
        'subtitle': 'Key handed over & condition recorded',
        'icon': Icons.fact_check_outlined,
      },
      {
        'title': 'Pre-Wash & Prep',
        'subtitle': 'Foam wash, clay bar, and paint taping',
        'icon': Icons.local_car_wash_outlined,
      },
      {
        'title': 'Detailing Bay Correction',
        'subtitle': 'Paint correction & coating application',
        'icon': Icons.cleaning_services_outlined,
      },
      {
        'title': 'Ready for Pickup',
        'subtitle': 'Final inspection completed. Pristine state.',
        'icon': Icons.star_border_outlined,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SERVICE BAY TRACKER',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        actions: [
          // Simulated status button for demonstration
          TextButton.icon(
            onPressed: () {
              tracking.simulateNextStatusStep();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulating status update in Odoo backend...'),
                  duration: Duration(milliseconds: 800),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
            icon: const Icon(Icons.science_outlined, size: 16),
            label: const Text('Simulate'),
          ),
        ],
      ),
      body: tracking.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vehicle overview card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_filled, color: AppTheme.primary, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeBooking.vehicleName,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeBooking.service.name,
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeBooking.statusTitle,
                            style: theme.textTheme.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Detailer Profile Card
                  Text('Detailing Specialist', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: activeBooking.technicianAvatar.isNotEmpty
                              ? NetworkImage(activeBooking.technicianAvatar)
                              : const NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=60'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activeBooking.technicianName, style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: AppTheme.primary, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.9 Star Rating (Odoo Verified)',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_outlined, color: AppTheme.primary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Stepper Title
                  Text('Bay Progress Timeline', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),

                  // Custom visual stepper
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      final currentStep = activeBooking.currentStep;
                      final isCompleted = index < currentStep;
                      final isActive = index == currentStep;

                      Color iconColor = AppTheme.textMuted;
                      Color lineColor = AppTheme.divider;
                      Color titleColor = AppTheme.textMuted;
                      FontWeight titleWeight = FontWeight.normal;

                      if (isCompleted) {
                        iconColor = AppTheme.primary;
                        lineColor = AppTheme.primary;
                        titleColor = AppTheme.textSecondary;
                      } else if (isActive) {
                        iconColor = Colors.white;
                        titleColor = Colors.white;
                        titleWeight = FontWeight.bold;
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left stepper icons & lines
                            Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppTheme.primary
                                        : (isCompleted
                                            ? AppTheme.primary.withOpacity(0.15)
                                            : AppTheme.surfaceLight),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCompleted || isActive
                                          ? AppTheme.primary
                                          : AppTheme.cardBorder,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    isCompleted ? Icons.check : step['icon'] as IconData,
                                    size: 16,
                                    color: iconColor,
                                  ),
                                ),
                                if (index < steps.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: lineColor,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Right content texts
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step['title'] as String,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: titleColor,
                                        fontWeight: titleWeight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      step['subtitle'] as String,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 12,
                                        color: isCompleted || isActive ? AppTheme.textSecondary : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Before / After Comparison Graphics Panel
                  if (activeBooking.beforeImages.isNotEmpty) ...[
                    Text('Detailing Graphics Bay', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        activeBooking.beforeImages.first,
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8, left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'BEFORE DETAIL',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (activeBooking.afterImages.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          activeBooking.afterImages.first,
                                          height: 130,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 8, left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'GLOSS FINISH',
                                              style: GoogleFonts.outfit(
                                                color: AppTheme.background,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activeBooking.afterImages.isNotEmpty
                                      ? 'Coating layer cured. Mirror reflections restored successfully.'
                                      : 'Before pictures uploaded by detailer. Paint depth recorded.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }
}
