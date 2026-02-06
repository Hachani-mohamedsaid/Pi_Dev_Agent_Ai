import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/custom_button.dart';
import '../state/auth_controller.dart';

/// Page ouverte depuis le lien reçu par email (Resend).
/// URL : /verify-email/confirm?token=...
/// Appelle POST /auth/verify-email/confirm puis affiche succès ou erreur.
class VerifyEmailConfirmPage extends StatefulWidget {
  const VerifyEmailConfirmPage({
    super.key,
    required this.controller,
    required this.token,
  });

  final AuthController controller;
  final String? token;

  @override
  State<VerifyEmailConfirmPage> createState() => _VerifyEmailConfirmPageState();
}

class _VerifyEmailConfirmPageState extends State<VerifyEmailConfirmPage> {
  bool _error = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _confirmIfNeeded();
  }

  Future<void> _confirmIfNeeded() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    final success = await widget.controller.confirmEmailVerification(token);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = !success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;
    final screenWidth = Responsive.screenWidth(context);

    if (widget.token == null || widget.token!.isEmpty) {
      return _buildInvalidLink(context, isMobile, padding);
    }

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.cyan400),
          ),
        ),
      );
    }

    if (_error) {
      return _buildError(context, isMobile, padding);
    }

    return _buildSuccess(context, isMobile, padding, screenWidth);
  }

  Widget _buildInvalidLink(
    BuildContext context,
    bool isMobile,
    double padding,
  ) {
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
                  Icon(
                    Icons.link_off,
                    size: isMobile ? 64 : 80,
                    color: AppColors.textCyan200.withOpacity(0.8),
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  Text(
                    'Lien invalide',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    'Ce lien est invalide ou a expiré. Demandez un nouvel email de vérification depuis Paramètres > Confidentialité et sécurité.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: AppColors.textCyan200.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  CustomButton(
                    text: 'Retour à l’accueil',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isMobile, double padding) {
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
                  Icon(
                    Icons.error_outline,
                    size: isMobile ? 64 : 80,
                    color: Colors.orange.shade400,
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  Text(
                    'Lien expiré ou invalide',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    widget.controller.error ??
                        'Une erreur s’est produite. Demandez un nouvel email de vérification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: AppColors.textCyan200.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  CustomButton(
                    text: 'Retour au profil',
                    onPressed: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(
    BuildContext context,
    bool isMobile,
    double padding,
    double screenWidth,
  ) {
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
                    borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                    border: Border.all(color: AppColors.borderCyan, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
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
                                Icons.mark_email_read,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            SizedBox(height: isMobile ? 24 : 32),
                            Text(
                              'Email vérifié',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 28 : 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'Votre adresse email a bien été vérifiée.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: AppColors.textCyan200.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: isMobile ? 32 : 40),
                            CustomButton(
                              text: 'Retour au profil',
                              onPressed: () => context.go('/profile'),
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
}
