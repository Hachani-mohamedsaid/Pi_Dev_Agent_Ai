import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Aligné sur le thème global (dégradé accueil + surfaces bleu/cyan).
abstract final class MarketIntelPalette {
  static const Color bg = Colors.transparent;
  static const Color surface = AppColors.primaryMedium;
  static const Color card = AppColors.primaryDarker;
  static const Color border = AppColors.primaryLight;
  static const Color border2 = Color(0xFF286082);

  static const Color faint = Color(0xFF475569);

  /// Accents principaux (équivalent « or » AVA sur fond dégradé).
  static const Color gold = AppColors.cyan400;
  static const Color gold2 = AppColors.cyan200;
  static const Color gold3 = AppColors.cyan500;

  static const Color text = AppColors.textWhite;
  static const Color muted = Color(0xFF94A3B8);

  static const Color green = AppColors.statusAccepted;
  static const Color blue = AppColors.cyan400;
  static const Color red = AppColors.statusRejected;
  static const Color amber = AppColors.statusPending;

  static const LinearGradient insightPanelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primaryDarker],
  );

  static const LinearGradient summaryCardGradient = AppColors.cardGradient;

  static const LinearGradient summaryTopAccent = AppColors.logoGradient;
}
