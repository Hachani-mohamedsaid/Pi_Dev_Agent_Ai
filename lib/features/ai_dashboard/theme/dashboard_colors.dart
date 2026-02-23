import 'package:flutter/material.dart';

/// SaaS-style dark-first colors for the AI Business Dashboard.
/// Notion / Stripe / Linear inspired.
class DashboardColors {
  DashboardColors._();

  // Background (dark mode first)
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF171717);
  static const Color surfaceVariant = Color(0xFF262626);
  static const Color surfaceElevated = Color(0xFF1F1F1F);

  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textTertiary = Color(0xFF737373);

  // Accent (primary actions, links)
  static const Color accent = Color(0xFF0EA5E9);
  static const Color accentLight = Color(0xFF38BDF8);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Health score indicators
  static const Color healthGreen = Color(0xFF22C55E);
  static const Color healthOrange = Color(0xFFF59E0B);
  static const Color healthRed = Color(0xFFEF4444);

  // Borders
  static const Color border = Color(0xFF2D2D2D);
  static const Color borderLight = Color(0xFF404040);

  // Shadows (soft)
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
}
