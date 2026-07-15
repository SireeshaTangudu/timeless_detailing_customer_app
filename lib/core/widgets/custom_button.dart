import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double height;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = 54,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonWidth = width ?? double.infinity;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(
            icon,
            size: 20,
            color: isOutlined ? AppTheme.primary : AppTheme.background,
          ),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? AppTheme.primary : AppTheme.background,
              ),
            ),
          )
        else
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isOutlined ? AppTheme.primary : AppTheme.background,
              fontSize: 16,
            ),
          ),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: buttonWidth,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonContent,
        ),
      );
    }

    // Gradient button container
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: onPressed == null
          ? null
          : (gradient ?? AppTheme.goldGradient),
      color: onPressed == null ? theme.disabledColor : null,
      boxShadow: onPressed == null
          ? []
          : [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
    );

    return Container(
      width: buttonWidth,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
