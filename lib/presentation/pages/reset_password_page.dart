import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../state/auth_controller.dart';

class ResetPasswordPage extends StatefulWidget {
  final AuthController controller;

  const ResetPasswordPage({super.key, required this.controller});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.controller.resetPassword(
        _emailController.text.trim(),
      );
      if (success && mounted) {
        setState(() {
          _isSubmitted = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.error ?? 'Failed to send reset link',
            ),
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

    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Stack(
            children: [
              // Background decorative elements
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
              // Content
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
                          borderRadius: BorderRadius.circular(
                            isMobile ? 24 : 28,
                          ),
                          border: Border.all(
                            color: AppColors.borderCyan,
                            width: 1,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 24 : 28,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 24 : 28,
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: EdgeInsets.all(padding),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child:
                                          Container(
                                                width: isMobile ? 80 : 96,
                                                height: isMobile ? 80 : 96,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppColors.logoGradient,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 48,
                                                ),
                                              )
                                              .animate()
                                              .scale(
                                                begin: const Offset(0, 0),
                                                end: const Offset(1, 1),
                                                delay: 200.ms,
                                                duration: 500.ms,
                                                curve: Curves.elasticOut,
                                              )
                                              .fadeIn(
                                                delay: 200.ms,
                                                duration: 500.ms,
                                              ),
                                    ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    Text(
                                          'Check Your Email',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isMobile ? 28 : 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textWhite,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 400.ms, duration: 500.ms)
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          delay: 400.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 12 : 16),
                                    Text(
                                      "We've sent a password reset link to:",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        color: AppColors.textCyan200
                                            .withOpacity(0.7),
                                      ),
                                    ).animate().fadeIn(
                                      delay: 500.ms,
                                      duration: 500.ms,
                                    ),
                                    SizedBox(height: isMobile ? 8 : 12),
                                    Text(
                                      _emailController.text.trim(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isMobile ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textCyan300,
                                      ),
                                    ).animate().fadeIn(
                                      delay: 600.ms,
                                      duration: 500.ms,
                                    ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    Text(
                                      "Click the link in the email to reset your password. If you don't see it, check your spam folder.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 14,
                                        color: AppColors.textCyan200
                                            .withOpacity(0.6),
                                      ),
                                    ).animate().fadeIn(
                                      delay: 700.ms,
                                      duration: 500.ms,
                                    ),
                                    SizedBox(height: isMobile ? 32 : 40),
                                    CustomButton(
                                          text: 'Back to Login',
                                          onPressed: () => context.pushReplacement(
                                            '/login?animate=${DateTime.now().millisecondsSinceEpoch}',
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 800.ms, duration: 500.ms)
                                        .slideY(
                                          begin: 0.1,
                                          end: 0,
                                          delay: 800.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 16 : 20),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isSubmitted = false;
                                        });
                                      },
                                      child: Text(
                                        "Didn't receive the email? Try again",
                                        style: TextStyle(
                                          color: AppColors.cyan400,
                                          fontSize: isMobile ? 13 : 14,
                                        ),
                                      ),
                                    ).animate().fadeIn(
                                      delay: 900.ms,
                                      duration: 500.ms,
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // Background decorative elements
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
            // Content
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
                        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                        border: Border.all(
                          color: AppColors.borderCyan,
                          width: 1,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            isMobile ? 24 : 28,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            isMobile ? 24 : 28,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: EdgeInsets.all(padding),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Back Button
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => context.pushReplacement(
                                            '/login?animate=${DateTime.now().millisecondsSinceEpoch}',
                                          ),
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
                                      ],
                                    ).animate().fadeIn(duration: 500.ms),
                                    SizedBox(height: isMobile ? 12 : 16),
                                    // Logo/Icon
                                    Center(
                                      child:
                                          Container(
                                                width: isMobile ? 64 : 72,
                                                height: isMobile ? 64 : 72,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppColors.logoGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        isMobile ? 16 : 20,
                                                      ),
                                                ),
                                                child: Icon(
                                                  Icons.mail_outline,
                                                  color: Colors.white,
                                                  size: isMobile ? 32 : 36,
                                                ),
                                              )
                                              .animate()
                                              .fadeIn(
                                                delay: 200.ms,
                                                duration: 500.ms,
                                              )
                                              .scale(
                                                begin: const Offset(0.8, 0.8),
                                                end: const Offset(1, 1),
                                                delay: 200.ms,
                                                duration: 500.ms,
                                              ),
                                    ),
                                    SizedBox(height: isMobile ? 20 : 24),
                                    // Title
                                    Text(
                                          'Reset Password',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isMobile ? 28 : 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textWhite,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 300.ms, duration: 500.ms)
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          delay: 300.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 8 : 12),
                                    // Subtitle
                                    Text(
                                      "Enter your email address and we'll send you a link to reset your password",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        color: AppColors.textCyan200
                                            .withOpacity(0.7),
                                      ),
                                    ).animate().fadeIn(
                                      delay: 400.ms,
                                      duration: 500.ms,
                                    ),
                                    SizedBox(height: isMobile ? 32 : 40),
                                    // Email Input
                                    CustomTextField(
                                          label: 'Email Address',
                                          hint: 'Enter your email',
                                          icon: Icons.mail_outline,
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: Validators.email,
                                        )
                                        .animate()
                                        .fadeIn(delay: 500.ms, duration: 500.ms)
                                        .slideX(
                                          begin: -0.1,
                                          end: 0,
                                          delay: 500.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Submit Button
                                    CustomButton(
                                          text: 'Send Reset Link',
                                          onPressed: _handleResetPassword,
                                          isLoading:
                                              widget.controller.isLoading,
                                        )
                                        .animate()
                                        .fadeIn(delay: 600.ms, duration: 500.ms)
                                        .slideY(
                                          begin: 0.1,
                                          end: 0,
                                          delay: 600.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Additional Help
                                    Container(
                                      padding: EdgeInsets.all(
                                        isMobile ? 16 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundDark,
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 12 : 14,
                                        ),
                                        border: Border.all(
                                          color: AppColors.borderCyan,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Remember your password? ',
                                            style: TextStyle(
                                              color: AppColors.textCyan200
                                                  .withOpacity(0.6),
                                              fontSize: isMobile ? 13 : 14,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                context.pushReplacement(
                                                  '/login?animate=${DateTime.now().millisecondsSinceEpoch}',
                                                ),
                                            child: Text(
                                              'Sign In',
                                              style: TextStyle(
                                                color: AppColors.cyan400,
                                                fontSize: isMobile ? 13 : 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().fadeIn(
                                      delay: 700.ms,
                                      duration: 500.ms,
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
            ),
          ],
        ),
      ),
    );
  }
}
