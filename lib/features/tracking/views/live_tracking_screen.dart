import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/tracking_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';

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
    // Initialize tracking status dynamically from Odoo backend
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
    final tasksList = tracking.allTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Live Detailing Tracking',
            subtitle: activeBooking.service.name,
          ),
          Expanded(
            child: tracking.isLoading
                ? const FourRotatingDotsLoader()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dynamic Vehicle & Booking Card
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
                                      activeBooking.vehicleName.isNotEmpty
                                          ? activeBooking.vehicleName
                                          : activeBooking.service.name,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                                  color: AppTheme.primary.withValues(alpha: 0.1),
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
                        const SizedBox(height: 24),

                        // Dynamic Detailer Specialist Card (Rendered only if technician data exists in Odoo)
                        if (activeBooking.technicianName.isNotEmpty) ...[
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
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  backgroundImage: activeBooking.technicianAvatar.isNotEmpty
                                      ? NetworkImage(activeBooking.technicianAvatar)
                                      : null,
                                  child: activeBooking.technicianAvatar.isEmpty
                                      ? const Icon(Icons.person_outline, color: AppTheme.primary, size: 24)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(activeBooking.technicianName, style: theme.textTheme.titleSmall),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Odoo Assigned Specialist',
                                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Dynamic Tasks Timeline (Endpoint 9: project.task/web_search_read)
                        if (tasksList.isNotEmpty) ...[
                          Text('Live Bay Tasks & Progress', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tasksList.length,
                            itemBuilder: (context, index) {
                              final task = tasksList[index];
                              final isDone = task.state == 'done' || task.state == '1_done';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                            : AppTheme.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDone ? Icons.check_circle_outline : Icons.cleaning_services_outlined,
                                        color: isDone ? const Color(0xFF2E7D32) : AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.name,
                                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Stage: ${task.stageName.isNotEmpty ? task.stageName : task.state}'
                                            '${task.portalUserNames.isNotEmpty ? ' • ${task.portalUserNames.join(", ")}' : ''}',
                                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                                            : AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        task.stageName.isNotEmpty ? task.stageName.toUpperCase() : 'IN PROGRESS',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDone ? const Color(0xFF2E7D32) : AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Dynamic Before / After Graphics Bay (Only rendered if actual images exist in Odoo)
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
                                                    'AFTER DETAIL',
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Dynamic Active Projects & Detailing Bays (Endpoint 8: project.project/web_search_read)
                        if (tracking.projects.isNotEmpty) ...[
                          Text('Active Projects & Detailing Bays', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ...tracking.projects.map((project) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.work_outline, color: AppTheme.primary, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project.name,
                                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${project.taskCount} Active Tasks${project.labelTasks.isNotEmpty ? ' • ${project.labelTasks}' : ''}',
                                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
