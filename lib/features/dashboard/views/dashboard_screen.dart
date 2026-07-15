import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_button.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_textfield.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/live_tracking_screen.dart';
import 'package:timeless_detailing_customer_app/core/theme/theme_controller.dart';

class DashboardScreen extends StatefulWidget {
  final TabController tabController;

  const DashboardScreen({super.key, required this.tabController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _makeModelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();

  @override
  void dispose() {
    _makeModelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _showAddVehicleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Vehicle to Garage',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: AppTheme.divider),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _makeModelController,
                hintText: 'e.g. Tesla Model 3',
                labelText: 'Make & Model',
                prefixIcon: Icons.directions_car_filled_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _colorController,
                hintText: 'e.g. Midnight Silver',
                labelText: 'Vehicle Color',
                prefixIcon: Icons.color_lens_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _plateController,
                hintText: 'e.g. CA-456-XY',
                labelText: 'License Plate',
                prefixIcon: Icons.pin_outlined,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'ADD TO GARAGE',
                onPressed: () {
                  if (_makeModelController.text.isNotEmpty && _plateController.text.isNotEmpty) {
                    Provider.of<DashboardController>(context, listen: false).addVehicle(
                      _makeModelController.text.trim(),
                      _plateController.text.trim().toUpperCase(),
                      _colorController.text.trim().isEmpty ? 'N/A' : _colorController.text.trim(),
                    );
                    _makeModelController.clear();
                    _plateController.clear();
                    _colorController.clear();
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vehicle added to garage successfully!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthController>(context);
    final garage = Provider.of<DashboardController>(context);
    final bookingsController = Provider.of<BookingsController>(context);

    // Find if there is an active tracking booking (received or inProgress)
    Booking? activeBooking;
    try {
      activeBooking = bookingsController.bookings.firstWhere(
        (b) => b.status == BookingStatus.inProgress || b.status == BookingStatus.received || b.status == BookingStatus.ready,
      );
    } catch (_) {
      activeBooking = null;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        auth.userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Consumer<ThemeController>(
                        builder: (context, themeController, _) {
                          return IconButton(
                            onPressed: () {
                              themeController.toggleTheme();
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Icon(
                                themeController.isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          auth.logout();
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: const Icon(Icons.logout, color: AppTheme.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Loyalty Club Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppTheme.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TIMELESS CLUB',
                          style: GoogleFonts.outfit(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.background.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Gold Status',
                            style: GoogleFonts.outfit(
                              color: AppTheme.background,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${auth.loyaltyPoints}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.background,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Points',
                          style: GoogleFonts.outfit(
                            color: AppTheme.background.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (auth.loyaltyPoints % 500) / 500,
                        backgroundColor: AppTheme.background.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${500 - (auth.loyaltyPoints % 500)} points remaining for a free Ceramic Wax top-off.',
                      style: GoogleFonts.montserrat(
                        color: AppTheme.background.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Active Detailing Booking Section
              if (activeBooking != null) ...[
                Text(
                  'Live Service Status',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sync_outlined,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeBooking.vehicleName,
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activeBooking.service.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              activeBooking.statusTitle,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: activeBooking.progressPercentage,
                          minHeight: 8,
                          backgroundColor: AppTheme.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'TRACK PROGRESS IN SERVICE BAY',
                        icon: Icons.track_changes,
                        height: 44,
                        onPressed: () {
                          // Open Live Tracking Details Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveTrackingScreen(booking: activeBooking!),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Quick Actions / Services catalog shortcut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detailing Packages',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      widget.tabController.animateTo(1); // switch to Services tab
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildShortcutServiceCard(
                      'Ceramic Coatings',
                      'Ultimate 9H shield',
                      'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=300&auto=format&fit=crop&q=60',
                    ),
                    const SizedBox(width: 14),
                    _buildShortcutServiceCard(
                      'Paint Correction',
                      'Erase swirl marks',
                      'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?w=300&auto=format&fit=crop&q=60',
                    ),
                    const SizedBox(width: 14),
                    _buildShortcutServiceCard(
                      'Interior Restoration',
                      'Deep steam sanitization',
                      'https://images.unsplash.com/photo-1563720223185-11003d516935?w=300&auto=format&fit=crop&q=60',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Garage Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Garage',
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: _showAddVehicleSheet,
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (garage.vehicles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.directions_car_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Your Garage is Empty',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a vehicle to simplify detailing schedules.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: garage.vehicles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vehicle = garage.vehicles[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car_filled,
                              color: AppTheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.makeModel,
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceLight,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.cardBorder),
                                      ),
                                      child: Text(
                                        vehicle.licensePlate,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      vehicle.color,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                            onPressed: () {
                              garage.removeVehicle(vehicle.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vehicle removed from garage.'),
                                  backgroundColor: AppTheme.warning,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutServiceCard(String title, String subtitle, String imgUrl) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              imgUrl,
              fit: BoxFit.cover,
              width: 200,
              height: 160,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        color: Colors.grey[400],
                        fontSize: 11,
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
}
