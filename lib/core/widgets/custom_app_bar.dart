import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBackButton;
  final IconData backIcon;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool showLogo;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.onBackPressed,
    this.trailing,
    this.showBackButton = true,
    this.backIcon = Icons.arrow_back_sharp,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 12),
    this.backgroundColor,
    this.titleStyle,
    this.subtitleStyle,
    this.showLogo = true,
  });

  bool get _hasTitle => title != null && title!.trim().isNotEmpty;
  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  @override
  Size get preferredSize {
    if (_hasTitle && _hasSubtitle) return const Size.fromHeight(140);
    if (_hasTitle || _hasSubtitle) return const Size.fromHeight(100);
    return const Size.fromHeight(66);
  }

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
              // Top Header Row: Circular Action/Back Button, Centered App Mini Logo & Optional Trailing Widget
              Stack(
                alignment: Alignment.center,
                children: [
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
                        const SizedBox(width: 38, height: 38),

                      if (trailing != null)
                        trailing!
                      else
                        const SizedBox(width: 38, height: 38),
                    ],
                  ),
                  if (showLogo)
                    Image.asset(
                      'assets/images/app_logo_mini.png',
                      height: 24,
                      width: 41,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
              if (_hasTitle || _hasSubtitle) const SizedBox(height: 20),

              // Title Below Back Button (Matching Figma Spec)
              if (_hasTitle)
                Text(
                  title!,
                  style: titleStyle ??
                      GoogleFonts.inter(
                        fontSize: 33,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3A2F1E),
                        height: 1.15,
                      ),
                ),
              if (_hasSubtitle) ...[
                if (_hasTitle) const SizedBox(height: 6),
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
