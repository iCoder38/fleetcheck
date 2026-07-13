import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core Brand Colors (from design spec) ─────────────
  static const Color primary       = Color(0xFF1A2A4A); // Navy Dark — Primary / AppBar / Nav
  static const Color secondary     = Color(0xFFE8A020); // Amber — Accent / CTA / Active
  static const Color accent        = Color(0xFFF5B942); // Amber Light — Hover / Highlight
  static const Color amber         = Color(0xFFE8A020); // Amber
  static const Color amberLight    = Color(0xFFF5B942); // Amber Light
  static const Color danger        = Color(0xFFC0392B); // Red — Fail / Error / Defect
  static const Color warning       = Color(0xFFF39C12); // Warning — Pending
  static const Color success       = Color(0xFF1A7A47); // Green — Pass / Success
  static const Color info          = Color(0xFF2980B9); // Blue — Info / Link
  static const Color overlay       = Color(0xFF1C1C1C); 
    static const Color appbg       = Color(0xFFF0F4F8); 
  // Black — Overlay / Shadow

  // ── Aliases (used across many screens) ───────────────
  static const Color green         = Color(0xFF1A7A47); // = success
  // Used for "active" highlights (e.g. QR scan overlay/spinner) — the
  // spec assigns "Active" to Amber, not green, so this now aliases Amber Light.
  static const Color greenLight    = Color(0xFFF5B942); // = accent / amberLight
  static const Color greenPale     = Color(0xFFD5F0E3); // badge-pass background
  static const Color navy          = Color(0xFF1A2A4A); // = primary
  static const Color red           = Color(0xFFC0392B); // = danger
  static const Color redLight      = Color(0xFFFAD7D4); // badge-fail background
  static const Color muted         = Color(0xFF8BA0C0); // = textSecondary
  static const Color bg            = Color(0xFF0D1B2A); // = background

  // ── Background / Surface ─────────────────────────────
  static const Color background    = Color(0xFF0D1B2A); // Navy Darker
  static const Color surface       = Color(0xFF243B5A); // Navy Mid
  static const Color cardBg        = Color(0xFF243B5A); // = surface

  // ── Text ─────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFF8BA0C0); // Slate
  static const Color textLight     = Color(0xFF5D7290); // dimmed Slate, tertiary text
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders / Dividers (derived — not specified in the design doc) ──
  static const Color border        = Color(0xFF35496B);
  static const Color divider       = Color(0xFF2C3F5C);

  // ── Status ────────────────────────────────────────────
  static const Color statusActive   = Color(0xFF1A7A47); // Green — Pass / Success
  static const Color statusInactive = Color(0xFF9E9E9E);
  static const Color statusPending  = Color(0xFFF39C12); // Warning
  static const Color statusFailed   = Color(0xFFC0392B); // Red

  // ── Dark Mode (system dark theme, distinct from the base navy theme above) ──
  static const Color darkBackground = Color(0xFF0F1923);
  static const Color darkSurface    = Color(0xFF1A2637);
  static const Color darkCard       = Color(0xFF1E2E45);
  static const Color darkBorder     = Color(0xFF2A3D56);

  // ── Checklist item colors ─────────────────────────────
  static const Color goodBg        = Color(0xFFD5F0E3); // badge-pass background
  static const Color goodText      = Color(0xFF1A7A47); // Green
  static const Color defectiveBg   = Color(0xFFFAD7D4); // badge-fail background
  static const Color defectiveText = Color(0xFFC0392B); // Red

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A2A4A), Color(0xFF0D1B2A)], // AppBar / Header
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1A2A4A), Color(0xFF0D1B2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // CTA / accent gradient (field kept as "greenGradient" for call-site
  // compatibility, but now uses the Amber CTA colors per the design spec).
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFFE8A020), Color(0xFFF5B942)], // CTA Button
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1A2A4A), Color(0xFF0D1B2A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
