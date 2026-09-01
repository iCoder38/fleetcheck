import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._();

  static double scale(BuildContext context, double size) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final factor = width < 360
        ? 0.92
        : width < 600
            ? 1.0
            : 1.05;
    return size * factor * textScale;
  }

  static double text(BuildContext context, double size) => scale(context, size);

  static double spacing(BuildContext context, double size) =>
      scale(context, size);

  static double padding(BuildContext context, double size) =>
      scale(context, size);

  static double radius(BuildContext context, double size) =>
      scale(context, size);

  static EdgeInsets horizontal(BuildContext context, {double value = 20}) =>
      EdgeInsets.symmetric(horizontal: padding(context, value));

  static EdgeInsets vertical(BuildContext context, {double value = 16}) =>
      EdgeInsets.symmetric(vertical: padding(context, value));

  static EdgeInsets symmetric(BuildContext context,
          {double horizontal = 20, double vertical = 16}) =>
      EdgeInsets.symmetric(
        horizontal: padding(context, horizontal),
        vertical: padding(context, vertical),
      );

  static EdgeInsets all(BuildContext context, {double value = 16}) =>
      EdgeInsets.all(padding(context, value));
}
