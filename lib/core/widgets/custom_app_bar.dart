import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_typography.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBackButton;
  final IconData backIcon;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBackPressed,
    this.trailing,
    this.showBackButton = true,
    this.backIcon = Icons.arrow_back_sharp,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 12),
    this.backgroundColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 140 : 110);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Circular Action/Back Button & Optional Trailing Widget
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBackButton)
                    GestureDetector(
                      onTap: () {
                        if (onBackPressed != null) {
                          onBackPressed!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
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
                        child: Icon(
                          backIcon,
                          size: 20,
                          color: const Color(0xFFAB8C5A),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 20),

              // Title Below Back Button (Matching Figma Spec)
              Text(
                title,
                style: titleStyle ??
                    GoogleFonts.inter(
                      fontSize: 33,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3A2F1E),
                      height: 1.15,
                    ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: subtitleStyle ??
                      GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7A7A7E),
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
