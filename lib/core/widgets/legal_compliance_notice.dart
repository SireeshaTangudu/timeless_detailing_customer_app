import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeless_detailing_customer_app/core/config/app_config.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';

/// Reusable compliance text displaying:
/// "By signing up you are accepting our Terms and Conditions, Privacy Policy, and POPIA Compliance"
/// Each link displays an inline frosted-glass blur capsule, soft gold glow, and tactile
/// press animation on tap before opening in the external browser.
class LegalComplianceNotice extends StatelessWidget {
  final String prefixText;
  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;

  const LegalComplianceNotice({
    super.key,
    this.prefixText = 'By signing up you are accepting our ',
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  /// Opens any legal URL strictly in the external mobile browser (Safari / Chrome).
  static Future<void> openExternalUrl(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open external browser link.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return Padding(
      padding: padding,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.6,
            color: const Color(0xFF7A7A7E),
          ),
          children: [
            TextSpan(text: prefixText),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: BlurLegalLink(
                text: 'Terms and Conditions',
                onTap: () => openExternalUrl(context, config.termsUrl),
              ),
            ),
            const TextSpan(text: 'and'),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: BlurLegalLink(
                text: 'Privacy Policy',
                onTap: () => openExternalUrl(context, config.privacyPolicyUrl),
              ),
            ),
            // const TextSpan(text: ', and '),
            // WidgetSpan(
            //   alignment: PlaceholderAlignment.middle,
            //   child: BlurLegalLink(
            //     text: 'POPIA Compliance',
            //     onTap: () => openExternalUrl(context, config.popiaUrl),
            //   ),
            // ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: textAlign,
      ),
    );
  }
}

/// Interactive legal link that displays an instant frosted-glass blur capsule,
/// subtle scale down, and soft gold glow when pressed before executing the tap action.
class BlurLegalLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? textColor;

  const BlurLegalLink({
    super.key,
    required this.text,
    required this.onTap,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
    this.textColor,
  });

  @override
  State<BlurLegalLink> createState() => _BlurLegalLinkState();
}

class _BlurLegalLinkState extends State<BlurLegalLink> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) async {
    // Keep the frosted blur tactile action visible briefly before invoking onTap
    await Future.delayed(const Duration(milliseconds: 140));
    if (mounted) {
      setState(() => _isPressed = false);
    }
    widget.onTap();
  }

  void _onTapCancel() {
    if (mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.textColor ?? AppTheme.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isPressed)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _isPressed
                      ? activeColor.withValues(alpha: 0.14)
                      : Colors.transparent,
                ),
                child: Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    fontSize: widget.fontSize,
                    fontWeight: widget.fontWeight,
                    color: activeColor,
                    decoration: _isPressed
                        ? TextDecoration.none
                        : TextDecoration.underline,
                    decorationColor: activeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
