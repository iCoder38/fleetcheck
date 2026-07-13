import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_responsive.dart';
import '../theme/app_text_styles.dart';

/// Inline error message banner shown below form headers across auth
/// and other form screens (red-tinted box with an error icon).
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.padding(context, 14),
            vertical: AppResponsive.padding(context, 12)),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.error_outline,
              color: AppColors.danger, size: AppResponsive.scale(context, 18)),
          SizedBox(width: AppResponsive.spacing(context, 8)),
          Expanded(
              child: Text(message,
                  style:
                      AppTextStyles.bodySmall(context, color: AppColors.danger))),
        ]),
      );
}
