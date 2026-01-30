import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final size = isMobile ? 64.0 : 72.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image is not found
            return Container(
              decoration: BoxDecoration(
                gradient: AppColors.logoGradient,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              ),
              child: Icon(
                Icons.fingerprint,
                color: Colors.white,
                size: size * 0.6,
              ),
            );
          },
        ),
      ),
    );
  }
}
