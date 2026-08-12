import 'dart:io';
import 'dart:convert';
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
  final _vehicleMakeController = TextEditingController(text: 'Toyota');
  final _vehicleModelController = TextEditingController(text: 'Hilux');
  final _vehiclePlateController = TextEditingController(text: 'ND 123 456');
  final _collectorNameController = TextEditingController();
  final _collectorLicenseController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '9:00 AM';

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _attachedImages = [];

  void _fetchOdooBookableSlots(DateTime date) {
    final appointmentTypeId = widget.initialService.appointmentTypeId ?? 1;
    debugPrint(
      '🔵 [BookServiceScreen] Calling Endpoint 3 (appointment.type/get_bookable_slots) for appointmentTypeId=$appointmentTypeId, date=${DateFormat('yyyy-MM-dd').format(date)}...',
    );
    Provider.of<BookingsController>(context, listen: false).fetchBookableSlots(
      appointmentTypeId: appointmentTypeId,
      timezone: 'UTC',
      resourceId: 1,
      date: date,
    );
  }

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
    final garage = Provider.of<DashboardController>(context, listen: false);
    if (garage.vehicles.isNotEmpty) {
      final v = garage.vehicles.first;
      final parts = v.makeModel.split(' ');
      if (parts.isNotEmpty) {
        _vehicleMakeController.text = parts.first;
      }
      if (parts.length > 1) {
        _vehicleModelController.text = parts.sublist(1).join(' ');
      }
      if (v.licensePlate.isNotEmpty) {
        _vehiclePlateController.text = v.licensePlate;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchOdooBookableSlots(_selectedDate);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _collectorNameController.dispose();
    _collectorLicenseController.dispose();
    super.dispose();
  }



  void _handleConfirmBooking() async {
    final vehicleMake = _vehicleMakeController.text.trim();
    final vehicleModel = _vehicleModelController.text.trim();

    if (vehicleMake.isEmpty || vehicleModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Vehicle Make and Vehicle Model.'),
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

    final appointmentTypeId = widget.initialService.appointmentTypeId ?? 1;
    final productId = widget.initialService.odooProductId;

    List<String> base64Images = [];
    if (_attachedImages.isNotEmpty) {
      for (final img in _attachedImages) {
        try {
          final bytes = await img.readAsBytes();
          base64Images.add(base64Encode(bytes));
        } catch (e) {
          debugPrint('Error reading attached image: $e');
        }
      }
    }

    debugPrint(
      '🔵 [BookServiceScreen] Triggering Endpoint 4 (calendar.event/web_save) for service="${widget.initialService.name}", apptTypeId=$appointmentTypeId, productId=$productId, make=$vehicleMake, model=$vehicleModel, imagesCount=${base64Images.length}...',
    );

    final result = await bookingsController.scheduleAppointment(
      service: widget.initialService,
      appointmentTypeId: appointmentTypeId,
      productId: productId,
      startDateTime: finalDateTime,
      stopDateTime: finalDateTime.add(
        Duration(
          hours: widget.initialService.durationHours.toInt() > 0
              ? widget.initialService.durationHours.toInt()
              : 1,
        ),
      ),
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehiclePlate: _vehiclePlateController.text.trim().isNotEmpty
          ? _vehiclePlateController.text.trim()
          : 'ND 123 456',
      phone: '+27821234567',
      collectorName: _collectorNameController.text.trim().isNotEmpty
          ? _collectorNameController.text.trim()
          : null,
      collectorLicense: _collectorLicenseController.text.trim().isNotEmpty
          ? _collectorLicenseController.text.trim()
          : null,
      vehicleImagesBase64: base64Images.isNotEmpty ? base64Images : null,
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
                  // Vehicle Make & Vehicle Model Textfields (in place of select car)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle Make',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3A2F1E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hintText: 'e.g. Toyota',
                              controller: _vehicleMakeController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle Model',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3A2F1E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hintText: 'e.g. Hilux',
                              controller: _vehicleModelController,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Vehicle License Plate (Optional)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A2F1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: 'e.g. ND 123 456',
                    controller: _vehiclePlateController,
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
                        _fetchOdooBookableSlots(date);
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
                  Builder(
                    builder: (context) {
                      final slotsResult = bookingsController.currentBookableSlots;
                      final isLoadingSlots = bookingsController.isLoadingSlots;

                      List<String> dynamicSlots = [
                        '9:00 AM',
                        '10:00 AM',
                        '11:00 AM',
                        '12:00 PM',
                        '2:00 PM',
                        '3:00 PM',
                        '4:00 PM',
                      ];

                      if (slotsResult != null && slotsResult.slots.isNotEmpty) {
                        dynamicSlots = slotsResult.slots.map((s) => s.formattedTime).toList();
                      }

                      if (isLoadingSlots) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: dynamicSlots.map((slot) {
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
                      );
                    },
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
