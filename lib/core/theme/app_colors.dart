import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary gradient colors
  static const Color primaryDark = Color(0xFF0F2940);
  static const Color primaryMedium = Color(0xFF1A3A52);
  static const Color primaryLight = Color(0xFF1E4A66);
  static const Color primaryDarker = Color(0xFF16384D);

  // Accent colors
  static const Color cyan400 = Color(0xFF22D3EE);
  static const Color cyan500 = Color(0xFF06B6D4);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color cyan200 = Color(0xFFA5F3FC);
  
  // Status colors
  static const Color statusPending = Color(0xFFF59E0B); // Orange/Amber for "En attente"
  static const Color statusAccepted = Color(0xFF10B981); // Green for "Acceptées"
  static const Color statusRejected = Color(0xFFEF4444); // Red for "Rejetées"

  // Text colors
  static const Color textWhite = Colors.white;
  static const Color textCyan200 = Color(0xFFA5F3FC);
  static const Color textCyan300 = Color(0xFF67E8F9);
  static const Color textCyan400 = Color(0xFF22D3EE);

  // Background colors with opacity
  static Color backgroundDark = const Color(0xFF0F2940).withOpacity(0.5);
  static Color borderCyan = cyan500.withOpacity(0.2);
  static Color borderCyanFocus = cyan400.withOpacity(0.3);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryMedium, primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, primaryDarker],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [cyan500, blue500],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan400, blue500],
  );
}
