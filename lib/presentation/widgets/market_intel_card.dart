import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Carte d’accès — même langage visuel que les cartes cyan de l’accueil.
class MarketIntelCard extends StatelessWidget {
  const MarketIntelCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const r = 18.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: Ink(
          padding: const EdgeInsets.all(r),
          decoration: BoxDecoration(
            color: AppColors.primaryDarker,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: AppColors.cyan500.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan500.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
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
                  color: AppColors.cyan500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.cyan400.withValues(alpha: 0.35),
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
                    const Text(
                      'Market Intelligence',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'European deal comparables',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textCyan200.withValues(alpha: 0.85),
                      ),
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
