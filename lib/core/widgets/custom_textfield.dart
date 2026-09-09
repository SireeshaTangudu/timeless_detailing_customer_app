import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeless_detailing_customer_app/core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters ??
          [
            FilteringTextInputFormatter.deny(
              RegExp(
                r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F800}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{200D}\u{FE0F}]',
                unicode: true,
              ),
            ),
          ],
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 15,
          ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppTheme.primary, size: 20)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
