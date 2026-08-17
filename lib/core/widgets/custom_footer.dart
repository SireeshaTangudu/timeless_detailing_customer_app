import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';

class CustomFooter extends StatelessWidget {
  final Widget? child;

  final List<Widget>? children;

  final Widget? leading;

  final Widget? trailing;

  final String? title;

  final String? subtitle;

  final String? buttonText;

  final VoidCallback? onPressed;

  final bool isLoading;

  final EdgeInsetsGeometry padding;

  final Color? backgroundColor;

  final Border? border;

  final double elevation;

  const CustomFooter({
    super.key,
    this.child,
    this.children,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
    this.buttonText,
    this.onPressed,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.backgroundColor,
    this.border,
    this.elevation = 0,
  });

  /// Factory constructor for standard action footers
  factory CustomFooter.action({
    Key? key,
    required String buttonText,
    required VoidCallback onPressed,
    Widget? leadingChild,
    bool isLoading = false,
    Color? buttonBackgroundColor,
    Color? buttonTextColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
  }) {
    return CustomFooter(
      key: key,
      buttonText: buttonText,
      onPressed: onPressed,
      leading: leadingChild,
      isLoading: isLoading,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (child != null) {
      content = child!;
    } else if (children != null) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children!,
      );
    } else {
      // Build from leading / trailing / title / subtitle / buttonText props
      Widget? leftWidget = leading;
      if (leftWidget == null && (title != null || subtitle != null)) {
        leftWidget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title!.isNotEmpty)
              Text(
                title!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFC4913F),
                ),
              ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: AppTypography.canela(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFC4913F),
                ),
              ),
          ],
        );
      }

      Widget? rightWidget = trailing;
      if (rightWidget == null && buttonText != null) {
        rightWidget = SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const FourRotatingDotsLoader(size: 22, color: Colors.white)
                : Text(
                    buttonText!,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        );
      }

      content = Row(
        children: [
          if (leftWidget != null) ...[
            Expanded(child: leftWidget),
            const SizedBox(width: 16),
          ],
          if (rightWidget != null)
            Expanded(flex: leftWidget != null ? 1 : 2, child: rightWidget),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,

        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: elevation * 2,
                  offset: Offset(0, -elevation),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: content),
      ),
    );
  }
}
