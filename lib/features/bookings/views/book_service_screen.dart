import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_button.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_textfield.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/services/models/service_model.dart';
import 'package:timeless_detailing_customer_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/estimation_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/estimation_screen.dart';

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
  final _collectorNameController = TextEditingController();
  final _collectorLicenseController = TextEditingController();

  Vehicle? _selectedVehicle;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '9:00 AM';

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _attachedImages = [];

  void _showImageSourcePicker() {
    if (_attachedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos can be attached.'),
          backgroundColor: Color(0xFF3A2F1E),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Attach Photo (${_attachedImages.length}/5)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A2F1E),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFC4913F),
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFC4913F),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await _picker.pickMultiImage(
          limit: 5 - _attachedImages.length,
        );
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _attachedImages.addAll(
              pickedFiles.take(5 - _attachedImages.length),
            );
          });
        }
      } else {
        final XFile? photo = await _picker.pickImage(source: source);
        if (photo != null) {
          setState(() {
            _attachedImages.add(photo);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

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
    _collectorNameController.dispose();
    _collectorLicenseController.dispose();
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
                  final garage = Provider.of<DashboardController>(
                    context,
                    listen: false,
                  );
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

    if (_collectorNameController.text.trim().isNotEmpty &&
        _collectorLicenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide driver\'s license number for authorized collector.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Parse selected date and time slot
    final timeFormat = DateFormat('hh:mm a');
    final timeOfDay = TimeOfDay.fromDateTime(
      timeFormat.parse(_selectedTimeSlot),
    );
    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    final bookingsController = Provider.of<BookingsController>(
      context,
      listen: false,
    );
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 70,
                ),
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
                  text: 'VIEW ESTIMATION',
                  height: 48,
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EstimationScreen(
                          estimation: EstimationModel.fromBooking(
                            result,
                            vehicleType: 'Hatch Back',
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back from Book Screen
                    Navigator.pop(context); // Go back from Detail Screen
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    'GO TO PORTAL',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
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
    final garage = Provider.of<DashboardController>(context);
    final bookingsController = Provider.of<BookingsController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Book slot for ${widget.initialService.name.toLowerCase()}',
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Car Label & Dropdown
                  Text(
                    'Select Car',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A2F1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEBE7DF)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Vehicle>(
                        isExpanded: true,
                        hint: Text(
                          'Select',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFB0A89C),
                          ),
                        ),
                        value: _selectedVehicle,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFC4913F),
                        ),
                        items: [
                          ...garage.vehicles.map((v) {
                            return DropdownMenuItem<Vehicle>(
                              value: v,
                              child: Text(
                                '${v.makeModel} (${v.licensePlate})',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF3A2F1E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (vehicle) {
                          if (vehicle != null) {
                            setState(() {
                              _selectedVehicle = vehicle;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showAddVehicleDialog,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '+ Add New Vehicle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFC4913F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Select Date Label & Picker
                  Text(
                    'Select Date',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A2F1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFC4913F),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Color(0xFF3A2F1E),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEBE7DF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd-MM-yyyy').format(_selectedDate),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF3A2F1E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFFC4913F),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Select Time Label & Grid Chips
                  Text(
                    'Select Time',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A2F1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        [
                          '9:00 AM',
                          '10:00 AM',
                          '11:00 AM',
                          '12:00 PM',
                          '2:00 PM',
                          '3:00 PM',
                          '4:00 PM',
                        ].map((slot) {
                          final isSelected =
                              _selectedTimeSlot == slot ||
                              _selectedTimeSlot.replaceAll('0', '') ==
                                  slot.replaceAll('0', '');
                          return SizedBox(
                            width: (MediaQuery.of(context).size.width - 64) / 3,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedTimeSlot = slot;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? const Color(
                                        0xFFC4913F,
                                      ).withValues(alpha: 0.08)
                                    : Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFFC4913F)
                                      : const Color(0xFFEBE7DF),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: const Color(0xFF3A2F1E),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Attach Vehicle / Condition Photos Section (Up to 5 Photos)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attach Photos (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3A2F1E),
                        ),
                      ),
                      Text(
                        '${_attachedImages.length}/5',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC4913F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attach up to 5 photos of your car or specific areas needing attention.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF8A8275),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _attachedImages.length +
                          (_attachedImages.length < 5 ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index < _attachedImages.length) {
                          final file = _attachedImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(file.path),
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return GestureDetector(
                            onTap: _showImageSourcePicker,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC4913F),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Color(0xFFC4913F),
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFC4913F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Authorized Vehicle Collector Section
                  Text(
                    'Authorized Vehicle Collector',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A2F1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'If you are unavailable to collect your vehicle after the service, you may authorize another person to collect it on your behalf. Please provide their name and driver\'s license number.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF8A8275),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Collector Name',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A2F1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _collectorNameController,
                    hintText: 'e.g. Jane Smith',
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                  if (_collectorNameController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Driver License Number *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3A2F1E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _collectorLicenseController,
                      hintText: 'e.g. D1234567',
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Button Sticky Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEBE7DF), width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: bookingsController.isLoading
                      ? null
                      : _handleConfirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAB8C5A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: bookingsController.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Book and Get Quotation',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
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
}
