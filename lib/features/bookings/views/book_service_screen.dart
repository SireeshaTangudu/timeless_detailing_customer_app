import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_button.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_textfield.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';

class BookServiceScreen extends StatefulWidget {
  final DetailService initialService;

  const BookServiceScreen({super.key, required this.initialService});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  final _notesController = TextEditingController();
  final _newVehicleMakeModelController = TextEditingController();
  final _newVehiclePlateController = TextEditingController();

  Vehicle? _selectedVehicle;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:00 AM';

  final List<String> _timeSlots = [
    '08:00 AM',
    '09:30 AM',
    '11:00 AM',
    '01:00 PM',
    '02:30 PM',
    '04:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    // Default select first vehicle in garage if available
    final garage = Provider.of<DashboardController>(context, listen: false);
    if (garage.vehicles.isNotEmpty) {
      _selectedVehicle = garage.vehicles.first;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newVehicleMakeModelController.dispose();
    _newVehiclePlateController.dispose();
    super.dispose();
  }

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            'Quick Add Vehicle',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _newVehicleMakeModelController,
                hintText: 'e.g. Tesla Model 3',
                labelText: 'Make & Model',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _newVehiclePlateController,
                hintText: 'e.g. CA-456-XY',
                labelText: 'License Plate',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newVehicleMakeModelController.clear();
                _newVehiclePlateController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
              ),
              onPressed: () {
                if (_newVehicleMakeModelController.text.isNotEmpty &&
                    _newVehiclePlateController.text.isNotEmpty) {
                  final garage = Provider.of<DashboardController>(context, listen: false);
                  garage.addVehicle(
                    _newVehicleMakeModelController.text.trim(),
                    _newVehiclePlateController.text.trim().toUpperCase(),
                    'N/A',
                  );
                  setState(() {
                    _selectedVehicle = garage.vehicles.last;
                  });
                  _newVehicleMakeModelController.clear();
                  _newVehiclePlateController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add & Select'),
            ),
          ],
        );
      },
    );
  }

  void _handleConfirmBooking() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a vehicle first.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Parse selected date and time slot
    final timeFormat = DateFormat('hh:mm a');
    final timeOfDay = TimeOfDay.fromDateTime(timeFormat.parse(_selectedTimeSlot));
    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    final bookingsController = Provider.of<BookingsController>(context, listen: false);
    final result = await bookingsController.scheduleBooking(
      service: widget.initialService,
      vehicleName: _selectedVehicle!.makeModel,
      vehiclePlate: _selectedVehicle!.licensePlate,
      dateTime: finalDateTime,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      final theme = Theme.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Icon(Icons.check_circle, color: AppTheme.success, size: 70),
                const SizedBox(height: 20),
                Text(
                  'Appointment Booked!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your ${widget.initialService.name} detailing has been scheduled. Track details live in your home portal dashboard.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'GO TO PORTAL',
                  height: 48,
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back from Book Screen
                    Navigator.pop(context); // Go back from Detail Screen
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingsController.errorMessage ?? 'Booking failed.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final garage = Provider.of<DashboardController>(context);
    final bookingsController = Provider.of<BookingsController>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BOOK SERVICE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected service summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.initialService.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialService.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Price: \$${widget.initialService.price.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 1: Select Vehicle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1. Select Vehicle',
                  style: theme.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _showAddVehicleDialog,
                  child: const Text('Add New'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (garage.vehicles.isEmpty)
              OutlinedButton(
                onPressed: _showAddVehicleDialog,
                child: const Text('+ ADD VEHICLE TO GARAGE'),
              )
            else
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: garage.vehicles.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final vehicle = garage.vehicles[index];
                    final isSelected = _selectedVehicle?.id == vehicle.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedVehicle = vehicle;
                        });
                      },
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    vehicle.makeModel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontSize: 13,
                                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    vehicle.licensePlate,
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                  ),
                                ],
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

            // Step 2: Date Picker
            Text(
              '2. Select Date & Time Slot',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Easy date picker card
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primary,
                          onPrimary: AppTheme.background,
                          surface: AppTheme.surface,
                          onSurface: AppTheme.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time Slot Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                return ChoiceChip(
                  label: Text(
                    slot,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? AppTheme.background : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                    ),
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Step 3: Special notes
            Text(
              '3. Special Requests / Notes',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _notesController,
              hintText: 'e.g. Tree sap on hood, deep leather conditioning requests, etc.',
              labelText: 'Detailing Notes (Optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Pricing Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Divider(color: AppTheme.divider, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.initialService.name, style: theme.textTheme.bodyMedium),
                      Text('\$${widget.initialService.price.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Taxes & Detailing Shop Fees', style: theme.textTheme.bodyMedium),
                      const Text('\$0.00', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: AppTheme.divider, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${widget.initialService.price.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Book Button
            CustomButton(
              text: 'CONFIRM APPOINTMENT',
              isLoading: bookingsController.isLoading,
              onPressed: _handleConfirmBooking,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
