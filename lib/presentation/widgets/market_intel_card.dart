import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Carte d’accès — même langage visuel que les cartes cyan de l’accueil.
class MarketIntelCard extends StatelessWidget {
  const MarketIntelCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const r = 18.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark
        ? AppColors.primaryDarker
        : const Color(0xFFF8FDFF);
    final secondaryColor = isDark
        ? AppColors.textCyan200.withValues(alpha: 0.85)
        : const Color(0xFF5B778E);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: Ink(
          padding: const EdgeInsets.all(r),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: isDark
                  ? AppColors.cyan500.withValues(alpha: 0.35)
                  : const Color(0xFFC1DAE8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.cyan500.withValues(alpha: 0.08)
                    : const Color(0xFFB2CAD8).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF9DB4C1).withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cyan500.withValues(alpha: 0.15)
                      : const Color(0xFFE5F3FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.cyan400.withValues(alpha: 0.35)
                        : const Color(0xFFA7CFE0),
                  ),
                ),
                child: Icon(
                  Icons.newspaper_rounded,
                  color: AppColors.cyan400,
                  size: 26,
                ),
              ),
              const SizedBox(width: r),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Intelligence',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textWhite
                            : const Color(0xFF102437),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'European deal comparables',
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.buttonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan500.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
