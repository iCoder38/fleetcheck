import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_responsive.dart';

/// Small caption label placed above a form field, shared by
/// [AppTextField] and [AppPasswordField] so every screen's fields
/// look consistent without redeclaring a private label widget each time.
class AppFieldLabel extends StatelessWidget {
  final String label;
  const AppFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: AppResponsive.spacing(context, 6)),
        child: Text(label,
            style: TextStyle(
                fontSize: AppResponsive.text(context, 13),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );
}

/// Labeled text field used across forms (identifier, phone, email, etc).
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(label),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onFieldSubmitted: onSubmitted,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            ),
          ),
        ],
      );
}

/// Labeled password field with a built-in show/hide toggle.
class AppPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const AppPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(widget.label),
          TextFormField(
            controller: widget.controller,
            obscureText: _obscure,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onFieldSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      );
}
