import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Même fond dégradé que l’écran d’accueil — pour les flux plein écran.
class AppShellGradient extends StatelessWidget {
  const AppShellGradient({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: child,
    );
  }
}

/// Bouton principal cyan → bleu (comme les CTA de l’app).
class AppPrimaryGradientButton extends StatelessWidget {
  const AppPrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: loading
                  ? [
                      AppColors.cyan500.withValues(alpha: 0.45),
                      AppColors.blue500.withValues(alpha: 0.45),
                    ]
                  : const [AppColors.cyan500, AppColors.blue500],
            ),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
