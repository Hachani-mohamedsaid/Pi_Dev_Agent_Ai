import 'package:flutter/material.dart';
import 'package:pi_dev_agentia/generated/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../state/auth_controller.dart';

class HomePage extends StatelessWidget {
  final AuthController controller;

  const HomePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final user = controller.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.primaryGradient
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBFF), Color(0xFFE7F2FA), Color(0xFFF7FBFF)],
          );
    final titleColor = isDark ? AppColors.textWhite : const Color(0xFF11263A);
    final subtitleColor = isDark
        ? AppColors.textCyan200
        : const Color(0xFF4B6780);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: background),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  S.of(context).welcome,
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 40,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                if (user != null) ...[
                  SizedBox(height: isMobile ? 16 : 24),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      color: subtitleColor,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: subtitleColor.withOpacity(isDark ? 0.7 : 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
