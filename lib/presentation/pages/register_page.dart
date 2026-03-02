import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pi_dev_agentia/presentation/widgets/google_sign_in_button_web.dart'
    if (dart.library.io) 'package:pi_dev_agentia/presentation/widgets/google_sign_in_button_stub.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_widget.dart';
import '../widgets/social_button.dart';
import '../widgets/apple_icon.dart';
import '../state/auth_controller.dart';
import '../../core/l10n/app_strings.dart';

class RegisterPage extends StatefulWidget {
  final AuthController controller;

  const RegisterPage({super.key, required this.controller});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Navigate after successful auth: onboarding (first open) or home.
  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool('ava_onboarding_complete') ?? false;
    if (!mounted) return;
    if (onboardingComplete) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.controller.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        await _navigateAfterAuth();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.error ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSocialRegister(SocialProvider provider) async {
    final success = await widget.controller.loginWithSocial(provider);
    if (success && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await _navigateAfterAuth();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Appelé sur le web quand le bouton Google (renderButton) fournit un idToken.
  Future<void> _onGoogleIdToken(String idToken) async {
    final success = await widget.controller.loginWithGoogleIdToken(idToken);
    if (success && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await _navigateAfterAuth();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Registration failed'),
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
                                          AppStrings.tr(
                                            context,
                                            'createAccount',
                                          ),
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
                                      AppStrings.tr(context, 'signUpSubtitle'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        color: AppColors.textCyan200
                                            .withOpacity(0.7),
                                      ),
                                    ).animate().fadeIn(
                                      delay: 300.ms,
                                      duration: 500.ms,
                                    ),
                                    SizedBox(height: isMobile ? 32 : 40),
                                    // Name Input
                                    CustomTextField(
                                          label: AppStrings.tr(
                                            context,
                                            'fullName',
                                          ),
                                          hint: AppStrings.tr(
                                            context,
                                            'enterName',
                                          ),
                                          icon: Icons.person_outline,
                                          controller: _nameController,
                                          validator: Validators.nonEmpty,
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
                                    // Email Input
                                    CustomTextField(
                                          label: AppStrings.tr(
                                            context,
                                            'email',
                                          ),
                                          hint: AppStrings.tr(
                                            context,
                                            'enterEmail',
                                          ),
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
                                    SizedBox(height: isMobile ? 20 : 24),
                                    // Password Input
                                    CustomTextField(
                                          label: AppStrings.tr(
                                            context,
                                            'password',
                                          ),
                                          hint: AppStrings.tr(
                                            context,
                                            'enterPassword',
                                          ),
                                          icon: Icons.lock_outline,
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          suffixIcon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.cyan400
                                                .withOpacity(0.6),
                                            size: isMobile ? 20 : 22,
                                          ),
                                          onSuffixIconTap: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          validator: Validators.password,
                                        )
                                        .animate()
                                        .fadeIn(delay: 600.ms, duration: 500.ms)
                                        .slideX(
                                          begin: -0.1,
                                          end: 0,
                                          delay: 600.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 20 : 24),
                                    // Confirm Password Input
                                    CustomTextField(
                                          label: AppStrings.tr(
                                            context,
                                            'confirmPassword',
                                          ),
                                          hint: AppStrings.tr(
                                            context,
                                            'confirmYourPassword',
                                          ),
                                          icon: Icons.lock_outline,
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          suffixIcon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.cyan400
                                                .withOpacity(0.6),
                                            size: isMobile ? 20 : 22,
                                          ),
                                          onSuffixIconTap: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                          validator: (value) =>
                                              Validators.confirmPassword(
                                                value,
                                                _passwordController.text,
                                              ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 700.ms, duration: 500.ms)
                                        .slideX(
                                          begin: -0.1,
                                          end: 0,
                                          delay: 700.ms,
                                          duration: 500.ms,
                                        ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Register Button
                                    CustomButton(
                                          text: AppStrings.tr(
                                            context,
                                            'signUp',
                                          ),
                                          onPressed: _handleRegister,
                                          isLoading:
                                              widget.controller.isLoading,
                                        )
                                        .animate()
                                        .fadeIn(delay: 800.ms, duration: 500.ms)
                                        .slideY(
                                          begin: 0.1,
                                          end: 0,
                                          delay: 800.ms,
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
                                            AppStrings.tr(
                                              context,
                                              'orSignUpWith',
                                            ),
                                            style: TextStyle(
                                              color: AppColors.textCyan200
                                                  .withOpacity(0.6),
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
                                    ).animate().fadeIn(
                                      delay: 900.ms,
                                      duration: 500.ms,
                                    ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Social Register Buttons (Google Account + Apple)
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        IgnorePointer(
                                          ignoring: widget.controller.isLoading,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child:
                                                    WebGoogleSignInButton(
                                                          onIdToken:
                                                              _onGoogleIdToken,
                                                          onPressed: () =>
                                                              _handleSocialRegister(
                                                                SocialProvider
                                                                    .google,
                                                              ),
                                                        )
                                                        .animate()
                                                        .fadeIn(
                                                          delay: 1000.ms,
                                                          duration: 500.ms,
                                                        )
                                                        .slideX(
                                                          begin: -0.1,
                                                          end: 0,
                                                          delay: 1000.ms,
                                                          duration: 500.ms,
                                                        ),
                                              ),
                                              if (!kIsWeb) ...[
                                                SizedBox(
                                                  width: isMobile ? 12 : 16,
                                                ),
                                                Expanded(
                                                  child:
                                                      SocialButton(
                                                            icon: AppleIcon(
                                                              size: isMobile
                                                                  ? 24
                                                                  : 26,
                                                            ),
                                                            text: AppStrings.tr(
                                                              context,
                                                              'appleAccount',
                                                            ),
                                                            onPressed: () =>
                                                                _handleSocialRegister(
                                                                  SocialProvider
                                                                      .apple,
                                                                ),
                                                          )
                                                          .animate()
                                                          .fadeIn(
                                                            delay: 1100.ms,
                                                            duration: 500.ms,
                                                          )
                                                          .slideX(
                                                            begin: 0.1,
                                                            end: 0,
                                                            delay: 1100.ms,
                                                            duration: 500.ms,
                                                          ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (widget.controller.isLoading)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.backgroundDark
                                                    .withOpacity(0.6),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isMobile ? 12 : 14,
                                                    ),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(
                                                      color: AppColors.cyan400,
                                                    ),
                                                    SizedBox(
                                                      height: isMobile
                                                          ? 12
                                                          : 16,
                                                    ),
                                                    Text(
                                                      AppStrings.tr(
                                                        context,
                                                        'signingUp',
                                                      ),
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.textWhite,
                                                        fontSize: isMobile
                                                            ? 12
                                                            : 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 24 : 32),
                                    // Sign In Link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppStrings.tr(
                                            context,
                                            'alreadyHaveAccount',
                                          ),
                                          style: TextStyle(
                                            color: AppColors.textCyan200
                                                .withOpacity(0.6),
                                            fontSize: isMobile ? 13 : 14,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.push('/login'),
                                          child: Text(
                                            AppStrings.tr(
                                              context,
                                              'signInAction',
                                            ),
                                            style: TextStyle(
                                              color: AppColors.cyan400,
                                              fontSize: isMobile ? 13 : 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ).animate().fadeIn(
                                      delay: 1200.ms,
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
