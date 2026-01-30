import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../state/auth_controller.dart';

/// Page pour définir le nouveau mot de passe après clic sur le lien email.
/// Le token est passé en query : /reset-password/confirm?token=...
class ResetPasswordConfirmPage extends StatefulWidget {
  const ResetPasswordConfirmPage({
    super.key,
    required this.controller,
    required this.token,
  });

  final AuthController controller;
  final String? token;

  @override
  State<ResetPasswordConfirmPage> createState() =>
      _ResetPasswordConfirmPageState();
}

class _ResetPasswordConfirmPageState extends State<ResetPasswordConfirmPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetNewPassword() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or missing reset link. Request a new one.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (_formKey.currentState!.validate()) {
      final newPassword = _newPasswordController.text.trim();
      final success = await widget.controller.setNewPassword(
        token: token,
        newPassword: newPassword,
      );
      if (success && mounted) {
        setState(() => _isSubmitted = true);
      } else if (mounted && widget.controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error ?? 'Failed to update password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;
    final screenWidth = Responsive.screenWidth(context);

    if (widget.token == null || widget.token!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Invalid reset link',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This link is invalid or has expired. Please request a new password reset from the login page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: AppColors.textCyan200.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Back to Login',
                      onPressed: () =>
                          context.pushReplacement('/login?animate=${DateTime.now().millisecondsSinceEpoch}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? screenWidth * 0.9 : 400,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius:
                          BorderRadius.circular(isMobile ? 24 : 28),
                      border: Border.all(
                        color: AppColors.borderCyan,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(isMobile ? 24 : 28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isMobile ? 80 : 96,
                                height: isMobile ? 80 : 96,
                                decoration: BoxDecoration(
                                  gradient: AppColors.logoGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              Text(
                                'Password Updated',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 28 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              Text(
                                "You can now sign in with your new password.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  color: AppColors.textCyan200.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: isMobile ? 32 : 40),
                              CustomButton(
                                text: 'Back to Login',
                                onPressed: () => context.pushReplacement(
                                    '/login?animate=${DateTime.now().millisecondsSinceEpoch}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: screenWidth * 0.4,
                  tablet: 300,
                  desktop: 400,
                ),
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: screenWidth * 0.4,
                  tablet: 300,
                  desktop: 400,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan500.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: screenWidth * 0.4,
                  tablet: 300,
                  desktop: 400,
                ),
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: screenWidth * 0.4,
                  tablet: 300,
                  desktop: 400,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue500.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: padding,
                    right: padding,
                    top: padding,
                    bottom: padding + MediaQuery.of(context).padding.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? screenWidth * 0.9 : 400,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius:
                            BorderRadius.circular(isMobile ? 24 : 28),
                        border: Border.all(
                          color: AppColors.borderCyan,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(isMobile ? 24 : 28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => context.pushReplacement(
                                        '/login?animate=${DateTime.now().millisecondsSinceEpoch}'),
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: AppColors.cyan400,
                                      size: isMobile ? 20 : 22,
                                    ),
                                    label: Text(
                                      'Back to Login',
                                      style: TextStyle(
                                        color: AppColors.cyan400,
                                        fontSize: isMobile ? 14 : 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 12 : 16),
                                  Center(
                                    child: Container(
                                      width: isMobile ? 64 : 72,
                                      height: isMobile ? 64 : 72,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.logoGradient,
                                        borderRadius:
                                            BorderRadius.circular(
                                                isMobile ? 16 : 20),
                                      ),
                                      child: Icon(
                                        Icons.lock_reset,
                                        color: Colors.white,
                                        size: isMobile ? 32 : 36,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 20 : 24),
                                  Text(
                                    'Set New Password',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isMobile ? 28 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  Text(
                                    'Enter your new password below.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color:
                                          AppColors.textCyan200.withOpacity(0.7),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 32 : 40),
                                  CustomTextField(
                                    label: 'New Password',
                                    hint: 'Enter new password',
                                    icon: Icons.lock_outline,
                                    controller: _newPasswordController,
                                    obscureText: true,
                                    validator: Validators.password,
                                  ),
                                  SizedBox(height: isMobile ? 20 : 24),
                                  CustomTextField(
                                    label: 'Confirm Password',
                                    hint: 'Confirm new password',
                                    icon: Icons.lock_outline,
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    validator: (v) =>
                                        Validators.confirmPassword(
                                            v, _newPasswordController.text.trim()),
                                  ),
                                  SizedBox(height: isMobile ? 24 : 32),
                                  CustomButton(
                                    text: 'Update Password',
                                    onPressed: _handleSetNewPassword,
                                    isLoading: widget.controller.isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
