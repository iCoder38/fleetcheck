import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core Brand Colors ─────────────────────────────────
  static const Color primary       = Color(0xFF1B2A4A); // Navy
  static const Color secondary     = Color(0xFF2E7D32); // Green dark
  static const Color accent        = Color(0xFF4CAF50); // Green light
  static const Color amber         = Color(0xFFF59E0B); // Amber / Warning
  static const Color danger        = Color(0xFFDC2626); // Red / Error
  static const Color warning       = Color(0xFFF59E0B);
  static const Color success       = Color(0xFF2E7D32);

  // ── Aliases (used across many screens) ───────────────
  static const Color green         = Color(0xFF2E7D32); // = secondary
  static const Color greenLight    = Color(0xFF4CAF50); // = accent
  static const Color greenPale     = Color(0xFFE8F5E9);
  static const Color navy          = Color(0xFF1B2A4A); // = primary
  static const Color red           = Color(0xFFDC2626); // = danger
  static const Color redLight      = Color(0xFFFFEBEE);
  static const Color muted         = Color(0xFF8FA3B8); // = textSecondary
  static const Color bg            = Color(0xFFF4F7FB); // = background

  // ── Background / Surface ─────────────────────────────
  static const Color background    = Color(0xFFF4F7FB);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardBg        = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1B2A4A);
  static const Color textSecondary = Color(0xFF8FA3B8);
  static const Color textLight     = Color(0xFFBBCCDD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders / Dividers ────────────────────────────────
  static const Color border        = Color(0xFFE2ECF4);
  static const Color divider       = Color(0xFFF0F4F8);

  // ── Status ────────────────────────────────────────────
  static const Color statusActive   = Color(0xFF4CAF50);
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusPending  = Color(0xFFF59E0B);
  static const Color statusFailed   = Color(0xFFDC2626);

  // ── Dark Mode ─────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1923);
  static const Color darkSurface    = Color(0xFF1A2637);
  static const Color darkCard       = Color(0xFF1E2E45);
  static const Color darkBorder     = Color(0xFF2A3D56);

  // ── Checklist item colors ─────────────────────────────
  static const Color goodBg        = Color(0xFFE8F5E9);
  static const Color goodText      = Color(0xFF2E7D32);
  static const Color defectiveBg   = Color(0xFFFFEBEE);
  static const Color defectiveText = Color(0xFFDC2626);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B2A4A), Color(0xFF243660)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1B2A4A), Color(0xFF243660)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1B2A4A), Color(0xFF0D1F3C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
