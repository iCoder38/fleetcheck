import 'package:flutter/material.dart';
import '../theme/app_responsive.dart';
import '../theme/app_text_styles.dart';

/// Full-width primary button with a built-in loading-spinner state.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: AppResponsive.scale(context, height),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: loading
              ? SizedBox(
                  width: AppResponsive.scale(context, 22),
                  height: AppResponsive.scale(context, 22),
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(label, style: AppTextStyles.button(context)),
        ),
      );
}

/// Full-width secondary (outlined) button, optionally with a leading icon.
class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;

  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.label(context, color: color);
    return SizedBox(
      width: double.infinity,
      height: AppResponsive.scale(context, height),
      child: icon != null
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: AppResponsive.scale(context, 18)),
              label: Text(label, style: labelStyle),
            )
          : OutlinedButton(
              onPressed: onPressed,
              child: Text(label, style: labelStyle),
            ),
    );
  }
}
