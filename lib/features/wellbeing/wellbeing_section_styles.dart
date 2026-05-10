import 'package:flutter/material.dart';

/// Couleurs par section (alignées thème AVA : fond sombre + accents vifs).
class WellbeingSectionStyle {
  const WellbeingSectionStyle({
    required this.id,
    required this.primary,
    required this.bright,
    required this.soft,
    required this.glow,
    required this.surfaceTint,
  });

  final String id;
  final Color primary;
  final Color bright;
  final Color soft;
  final Color glow;
  final Color surfaceTint;

  LinearGradient get headerGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.45),
          soft.withValues(alpha: 0.12),
          const Color(0xFF0D1B2A),
        ],
      );

  LinearGradient get cardBorderGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          bright.withValues(alpha: 0.95),
          primary.withValues(alpha: 0.5),
        ],
      );

  LinearGradient get likertSelectedGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bright, primary],
      );

  static WellbeingSectionStyle forSectionId(String sectionId) {
    switch (sectionId) {
      case 'A':
        return cognitive;
      case 'B':
        return emotional;
      case 'C':
        return physical;
      default:
        return cognitive;
    }
  }

  /// A — Décision & charge cognitive (bleu type AVA / blue500)
  static const cognitive = WellbeingSectionStyle(
    id: 'A',
    primary: Color(0xFF2563EB),
    bright: Color(0xFF60A5FA),
    soft: Color(0xFF1D4ED8),
    glow: Color(0xFF3B82F6),
    surfaceTint: Color(0xFF172554),
  );

  /// B — Pression émotionnelle (rose / corail)
  static const emotional = WellbeingSectionStyle(
    id: 'B',
    primary: Color(0xFFDB2777),
    bright: Color(0xFFF472B6),
    soft: Color(0xFFBE185D),
    glow: Color(0xFFEC4899),
    surfaceTint: Color(0xFF4C0519),
  );

  /// C — Physique & énergie (vert émeraude)
  static const physical = WellbeingSectionStyle(
    id: 'C',
    primary: Color(0xFF059669),
    bright: Color(0xFF34D399),
    soft: Color(0xFF047857),
    glow: Color(0xFF10B981),
    surfaceTint: Color(0xFF022C22),
  );
}
