import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

Color _primaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textWhite
      : const Color(0xFF12263A);
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textCyan200
      : const Color(0xFF5B7B92);
}

/// Bottom sheet shown when a premium-only feature is blocked.
class PremiumGateSheet extends StatelessWidget {
  const PremiumGateSheet({super.key, required this.featureName});

  final String featureName;

  static void show(BuildContext context, String featureName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PremiumGateSheet(featureName: featureName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDarker : const Color(0xFFF7FBFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFB7CCD9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.workspace_premium_rounded,
                size: 48,
                color: const Color(0xFFFBBF24),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) => Text(
                  'Premium Feature',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryText(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) => Text(
                  featureName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan400,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) => Text(
                  'Unlock this feature and everything AVA has to offer '
                  'with a Premium plan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: _secondaryText(context),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.go('/subscription');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan400,
                    side: const BorderSide(
                      color: AppColors.cyan500,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
