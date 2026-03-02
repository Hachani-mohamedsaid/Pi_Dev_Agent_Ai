import 'package:flutter/material.dart';
import 'package:pi_dev_agentia/core/l10n/app_strings.dart';
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.tr(context, 'welcome'),
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                if (user != null) ...[
                  SizedBox(height: isMobile ? 16 : 24),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      color: AppColors.textCyan200,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      color: AppColors.textCyan200.withOpacity(0.7),
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
