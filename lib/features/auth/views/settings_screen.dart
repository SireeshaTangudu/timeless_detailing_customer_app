import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/features/auth/controllers/auth_controller.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showLogoutConfirmationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC4913F),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Logout',
                style: AppTypography.canela(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout of the app?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFD1D1D1),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final auth = Provider.of<AuthController>(
                      context,
                      listen: false,
                    );
                    await auth.logout();

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Logout',
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
  }

  void _showDeleteProfilePictureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isClearing = false;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: isClearing ? null : () => Navigator.pop(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFC4913F),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Remove Profile Picture',
                    style: AppTypography.canela(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your profile picture will be removed from your account.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFD1D1D1),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isClearing
                          ? null
                          : () async {
                              setSheetState(() => isClearing = true);
                              final auth = Provider.of<AuthController>(
                                context,
                                listen: false,
                              );
                              final success = await auth.clearProfilePicture();

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Profile picture removed.'
                                        : auth.errorMessage ??
                                            'Failed to remove profile picture.',
                                    style: GoogleFonts.inter(color: Colors.white),
                                  ),
                                  backgroundColor:
                                      success ? AppTheme.primary : AppTheme.error,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledBackgroundColor:
                            AppTheme.primary.withValues(alpha: 0.5),
                      ),
                      child: isClearing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Remove Picture',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: isClearing ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD1D1D1),
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

  void _showDeleteAccountSheet() {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isDeleting = false;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: isDeleting ? null : () => Navigator.pop(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFC4913F),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Delete Account',
                    style: AppTypography.canela(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action is permanent and cannot be undone. All your profile data, bookings, and loyalty points will be removed.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFD1D1D1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Color(0xFFC4913F),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If you only need a break, consider logging out instead.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFC4913F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF1C1C1E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Optional: tell us why you\u2019re leaving',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFFA09D96),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F6F2),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isDeleting
                          ? null
                          : () async {
                              setSheetState(() => isDeleting = true);
                              final auth = Provider.of<AuthController>(
                                context,
                                listen: false,
                              );
                              final success = await auth.deleteAccount();

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              if (success) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Account deleted. We\u2019re sorry to see you go.',
                                      style: GoogleFonts.inter(color: Colors.white),
                                    ),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      auth.errorMessage ??
                                          'Failed to delete account. Please try again or contact support.',
                                      style: GoogleFonts.inter(color: Colors.white),
                                    ),
                                    backgroundColor: AppTheme.error,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledBackgroundColor:
                            AppTheme.error.withValues(alpha: 0.5),
                      ),
                      child: isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Delete My Account',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: isDeleting ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD1D1D1),
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          title: Text(
            'Terms and Conditions',
            style: AppTypography.canela(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Welcome to Timeless Detailing. By utilizing our customer portal, you agree to comply with our service policies, reservation guidelines, and privacy regulations regarding vehicle care and maintenance.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFD1D1D1),
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: color ?? AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? const Color(0xFF1C1C1E),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Settings',
            subtitle: 'Manage your preferences',
          ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  Text(
                    'Account',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E8E93),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSettingsTile(
                    title: 'Remove Profile Picture',
                    icon: Icons.person_remove_alt_1_outlined,
                    onTap: _showDeleteProfilePictureSheet,
                  ),
                  const Divider(color: Color(0xFFF0EDE6), height: 1),
                  _buildSettingsTile(
                    title: 'Logout',
                    icon: Icons.logout_rounded,
                    onTap: _showLogoutConfirmationSheet,
                  ),
                  const Divider(color: Color(0xFFF0EDE6), height: 1),
                  _buildSettingsTile(
                    title: 'Delete Account',
                    icon: Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    onTap: _showDeleteAccountSheet,
                  ),
                  const Divider(color: Color(0xFFF0EDE6), height: 1),
                  const SizedBox(height: 32),
                  Text(
                    'Legal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E8E93),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSettingsTile(
                    title: 'Terms and Conditions',
                    icon: Icons.article_outlined,
                    onTap: _showTermsDialog,
                  ),
                  const Divider(color: Color(0xFFF0EDE6), height: 1),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
