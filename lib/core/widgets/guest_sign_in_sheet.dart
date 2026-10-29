import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/features/auth/views/login_screen.dart';

/// Displays a sleek, Apple-compliant bottom sheet prompting a guest to sign in.
Future<bool?> showGuestSignInSheet(
  BuildContext context, {
  String title = 'Sign In to Proceed',
  String message =
      'Please sign in or create an account to book an appointment and manage your vehicle service details.',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pull indicator pill
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE7DF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Lock Icon with glowing circular badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  title,
                  style: AppTypography.canela(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Informational text
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: const Color(0xFF7A7A7E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Primary Sign In / Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign In / Create Account',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary "Keep Browsing" Dismiss Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Keep Browsing',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9A9285),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// A clean placeholder UI rendered inside tabs (like Bookings and Profile)
/// when accessed in Guest Mode, giving clear guidance without layout errors.
class GuestRestrictedTabPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const GuestRestrictedTabPlaceholder({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
                border: Border.all(color: AppTheme.primary, width: 1.5),
              ),
              child: Icon(icon, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.canela(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C1E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF7A7A7E),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign In / Register',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
