import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_widget.dart';
import '../widgets/social_button.dart';
import '../widgets/google_icon.dart';
import '../widgets/apple_icon.dart';
import '../state/auth_controller.dart';

class LoginPage extends StatefulWidget {
  final AuthController controller;

  const LoginPage({
    super.key,
    required this.controller,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.controller.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSocialLogin(SocialProvider provider) async {
    final success = await widget.controller.loginWithSocial(provider);
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenWidth = Responsive.screenWidth(context);
    final maxWidth = isMobile ? screenWidth * 0.9 : 400.0;
    final padding = isMobile ? 24.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
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
                    constraints: BoxConstraints(maxWidth: maxWidth),
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
                          borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
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
                                    // Logo
                                    Center(
                                      child: const LogoWidget()
                                          .animate()
                                          .fadeIn(duration: 500.ms)
                                          .scale(
                                            begin: const Offset(0.8, 0.8),
                                            end: const Offset(1, 1),
                                            duration: 500.ms,
                                          ),
                                    ),
                                    SizedBox(height: isMobile ? 20 : 24),
                                    // Title
                                    Text(
                                      'Welcome Back',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isMobile ? 28 : 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textWhite,
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(delay: 200.ms, duration: 500.ms)
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          delay: 200.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 8 : 12),
                                    // Subtitle
                                    Text(
                                      'Sign in to continue to your AI assistant',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        color: AppColors.textCyan200.withOpacity(0.7),
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(delay: 300.ms, duration: 500.ms),
                                    SizedBox(height: isMobile ? 32 : 40),
                                    // Email Input
                                    Builder(
                                      builder: (context) {
                                        return CustomTextField(
                                          label: 'Email',
                                          hint: 'Enter your email',
                                          icon: Icons.mail_outline,
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: Validators.email,
                                        );
                                      },
                                    )
                                        .animate()
                                        .fadeIn(delay: 400.ms, duration: 500.ms)
                                        .slideX(
                                          begin: -0.1,
                                          end: 0,
                                          delay: 400.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 20 : 24),
                                    // Password Input
                                    Builder(
                                      builder: (context) {
                                        return CustomTextField(
                                          label: 'Password',
                                          hint: 'Enter your password',
                                          icon: Icons.lock_outline,
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          suffixIcon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.cyan400.withOpacity(0.6),
                                            size: isMobile ? 20 : 22,
                                          ),
                                          onSuffixIconTap: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                          validator: Validators.password,
                                        );
                                      },
                                    )
                                        .animate()
                                        .fadeIn(delay: 500.ms, duration: 500.ms)
                                        .slideX(
                                          begin: -0.1,
                                          end: 0,
                                          delay: 500.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 12 : 16),
                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => context.push('/reset-password'),
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: AppColors.cyan400,
                                            fontSize: isMobile ? 13 : 14,
                                          ),
                                        ),
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(delay: 600.ms, duration: 500.ms),
                                    SizedBox(height: isMobile ? 20 : 24),
                                    // Login Button
                                    CustomButton(
                                      text: 'Sign In',
                                      onPressed: _handleLogin,
                                      isLoading: widget.controller.isLoading,
                                    )
                                        .animate()
                                        .fadeIn(delay: 700.ms, duration: 500.ms)
                                        .slideY(
                                          begin: 0.1,
                                          end: 0,
                                          delay: 700.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.borderCyan,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 12 : 16,
                                          ),
                                          child: Text(
                                            'Or continue with',
                                            style: TextStyle(
                                              color: AppColors.textCyan200.withOpacity(0.6),
                                              fontSize: isMobile ? 12 : 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.borderCyan,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    )
                                        .animate()
                                        .fadeIn(delay: 800.ms, duration: 500.ms),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Social Login Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SocialButton(
                                            icon: GoogleIcon(size: isMobile ? 20 : 22),
                                            text: 'Google Account',
                                            onPressed: () => _handleSocialLogin(SocialProvider.google),
                                          )
                                              .animate()
                                              .fadeIn(delay: 900.ms, duration: 500.ms)
                                              .slideX(
                                                begin: -0.1,
                                                end: 0,
                                                delay: 900.ms,
                                                duration: 500.ms,
                                              ),
                                        ),
                                        SizedBox(width: isMobile ? 12 : 16),
                                        Expanded(
                                          child: SocialButton(
                                            icon: AppleIcon(size: isMobile ? 24 : 26),
                                            text: 'Apple Account',
                                            onPressed: () => _handleSocialLogin(SocialProvider.apple),
                                          )
                                              .animate()
                                              .fadeIn(delay: 1000.ms, duration: 500.ms)
                                              .slideX(
                                                begin: 0.1,
                                                end: 0,
                                                delay: 1000.ms,
                                                duration: 500.ms,
                                              ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Sign Up Link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                            color: AppColors.textCyan200.withOpacity(0.6),
                                            fontSize: isMobile ? 13 : 14,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.push('/register'),
                                          child: Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              color: AppColors.cyan400,
                                              fontSize: isMobile ? 13 : 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                        .animate()
                                        .fadeIn(delay: 1100.ms, duration: 500.ms),
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

