import 'package:flutter/material.dart';

class AppColors {
  /* ================= BRAND ================= */
  static const Color primary = Color(0xFF6C63FF); // soft violet / vibey accent
  static const Color secondary = Color(0xFF00C2A8); // optional accent (teal)

  /* ================= LIGHT THEME (OFF-WHITE) ================= */
  static const Color bgLight = Color(0xFFF9F9F7); // off-white background
  static const Color cardLight = Color(0xFFFFFFFF); // pure white cards
  static const Color textLight = Color(0xFF1C1C1E); // near-black
  static const Color mutedLight = Color(0xFF6E6E73); // iOS-style muted text
  static const Color borderLight = Color(0xFFE5E5EA);

  /* ================= DARK THEME (OFF-BLACK) ================= */
  static const Color bgDark = Color(0xFF0F0F12); // soft black
  static const Color cardDark = Color(0xFF1A1A1E);
  static const Color textDark = Color(0xFFF5F5F7);
  static const Color mutedDark = Color(0xFF9A9AA1);
  static const Color borderDark = Color(0xFF2C2C2E);

  /* ================= STATUS ================= */
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF1C40F);

  /* ================= CURRENT MODE (TEMP) ================= */
  // Toggle this later using ThemeMode
  static const bool isDark = false;

  static Color get bg => isDark ? const Color.fromARGB(255, 84, 84, 99) : const Color.fromARGB(255, 158, 158, 157);
  static Color get card => isDark ? cardDark : const Color.fromARGB(255, 207, 202, 202);
  static const text = Color.fromARGB(255, 27, 25, 25);
  static const muted = Color.fromARGB(255, 97, 86, 86);
  static Color get border => isDark ? borderDark : borderLight;
}
