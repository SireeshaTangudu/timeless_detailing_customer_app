import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/settings_screen.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/bookings/views/bookings_history_screen.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';

class ProfileScreen extends StatefulWidget {
  final TabController? tabController;
  final VoidCallback? onMenuTap;

  const ProfileScreen({super.key, this.tabController, this.onMenuTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      auth.refreshProfile();
      final partnerId = auth.userProfile?['id'] is int
          ? auth.userProfile!['id'] as int
          : null;
      Provider.of<BookingsController>(
        context,
        listen: false,
      ).loadBookings(partnerId: partnerId);
    });
  }

  void _showUpdateProfileSheet() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final nameController = TextEditingController(text: auth.userName);
    final phoneController = TextEditingController(
      text: auth.userPhone.isNotEmpty ? auth.userPhone : '+91 98456 43210',
    );
    final emailController = TextEditingController(text: auth.userEmail);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Update Profile',
                        style: AppTypography.canela(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1C1E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF7A7A7E)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFEBE7DF)),
                  const SizedBox(height: 12),
                  Text(
                    'Full Name',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8F6F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Phone Number',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8F6F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email ID',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8F6F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              final success = await auth.updateProfile(
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                email: emailController.text.trim(),
                              );

                              if (!mounted) return;

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Profile updated successfully.'
                                        : auth.errorMessage ??
                                              'Failed to update profile.',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: success
                                      ? AppTheme.primary
                                      : AppTheme.error,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isSaving
                          ? const FourRotatingDotsLoader(size: 20, color: Colors.white)
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      final auth = Provider.of<AuthController>(context, listen: false);
      final success = await auth.uploadProfileImage(bytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile picture updated successfully!'
                : auth.errorMessage ?? 'Failed to upload photo.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: success ? AppTheme.primary : AppTheme.error,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      final isChannelError =
          errorStr.contains('channel-error') ||
          errorStr.contains('MissingPluginException') ||
          errorStr.contains('Unable to establish connection');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isChannelError
                ? 'Native image picker linked! Please stop and re-run the app in your terminal/IDE.'
                : 'Permission or system error: ${e.message}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      final isChannelError =
          errorStr.contains('channel-error') ||
          errorStr.contains('MissingPluginException') ||
          errorStr.contains('Unable to establish connection');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isChannelError
                ? 'Native image picker linked! Please stop and re-run the app in your terminal/IDE.'
                : 'Error selecting image: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Profile Picture',
                  style: AppTypography.canela(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFBF9F5),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    'Take a Photo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFBF9F5),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder(AuthController auth) {
    final name = auth.userName;
    final initials = name.isNotEmpty && name != 'Guest Customer'
        ? name
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'TD';

    return Center(
      child: Text(
        initials,
        style: AppTypography.canela(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(AuthController auth) {
    final base64Str = auth.profileImageBase64;
    Uint8List? imageBytes;
    if (base64Str != null) {
      try {
        String cleaned = base64Str.replaceAll(RegExp(r'\s+'), '');
        while (cleaned.length % 4 != 0) {
          cleaned += '=';
        }
        imageBytes = base64Decode(cleaned);
      } catch (_) {
        imageBytes = null;
      }
    }

    return Center(
      child: GestureDetector(
        onTap: _showImagePickerModal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                color: const Color(0xFFFBF9F5),
              ),
              child: ClipOval(
                child: auth.isLoading
                    ? const FourRotatingDotsLoader(size: 30)
                    : (imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              width: 96,
                              height: 96,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildAvatarPlaceholder(auth),
                            )
                          : _buildAvatarPlaceholder(auth)),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'My Profile',
              onBackPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (widget.tabController != null) {
                  widget.tabController!.animateTo(0);
                } else if (widget.onMenuTap != null) {
                  widget.onMenuTap!();
                }
              },
              trailing: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFAB8C5A),
                      width: 1.2,
                    ),
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Color(0xFFAB8C5A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User Info Section & Action Cards
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await auth.refreshProfile();
                  if (mounted) {
                    final partnerId = auth.userProfile?['id'] is int
                        ? auth.userProfile!['id'] as int
                        : null;
                    await Provider.of<BookingsController>(
                      context,
                      listen: false,
                    ).loadBookings(partnerId: partnerId);
                  }
                },
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // User Profile Image Avatar with Camera Overlay
                      _buildProfileAvatar(auth),
                      const SizedBox(height: 20),

                      // Sub-label: Hello
                      Text(
                        'Hello',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF7A7A7E),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // User Full Name with Edit Icon Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              auth.userName.isNotEmpty
                                  ? auth.userName
                                  : 'Guest Customer',
                              style: AppTypography.canela(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showUpdateProfileSheet,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFBF9F5),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Phone Number Item Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.userPhone.isNotEmpty
                                    ? auth.userPhone
                                    : '+91 98456 43210',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Email ID Item Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email ID',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.userEmail.isNotEmpty
                                    ? auth.userEmail
                                    : 'Not provided',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Action Cards Grid (My Orders & Bookings and My Cars as in Figma)
                      Row(
                        children: [
                          // Card 1: My Orders & Bookings
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (widget.tabController != null) {
                                  widget.tabController!.animateTo(
                                    2,
                                  ); // Go to Bookings tab
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BookingsHistoryScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                height: 160,
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
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFBF9F5),
                                        border: Border.all(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Image.asset(
                                        'assets/profile/my_orders.png',
                                        width: 28,
                                        height: 28,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 26,
                                                  color: AppTheme.primary,
                                                ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'My Orders &\nBookings',
                                      style: AppTypography.canela(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1C1C1E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Card 2: My Cars
                          Expanded(
                            child: GestureDetector(
                              onTap: _showUpdateProfileSheet,
                              child: Container(
                                height: 160,
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
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFBF9F5),
                                        border: Border.all(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Image.asset(
                                        'assets/profile/my_cars.png',
                                        width: 28,
                                        height: 28,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.directions_car_outlined,
                                                  size: 26,
                                                  color: AppTheme.primary,
                                                ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'My Cars',
                                      style: AppTypography.canela(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1C1C1E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
