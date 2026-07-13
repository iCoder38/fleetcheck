import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_responsive.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(BuildContext context,
          {Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 28),
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle heading1(BuildContext context, {Color? color}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 24),
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle heading2(BuildContext context, {Color? color}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 20),
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle heading3(BuildContext context, {Color? color}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 16),
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle body(BuildContext context,
          {Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 14),
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle bodySmall(BuildContext context, {Color? color}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 12),
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle label(BuildContext context, {Color? color}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 13),
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle button(BuildContext context, {Color? color}) =>
      TextStyle(
        fontFamily: 'Verdana',
        fontSize: AppResponsive.text(context, 15),
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textOnPrimary,
      );
}
