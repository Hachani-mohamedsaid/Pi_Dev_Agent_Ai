import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../state/auth_controller.dart';

/// Page "Nouveau mot de passe" après clic sur le lien reçu par email.
/// Reçoit le [token] depuis l'URL : /reset-password/confirm?token=xxx
class ResetPasswordConfirmPage extends StatefulWidget {
  const ResetPasswordConfirmPage({
    super.key,
    required this.controller,
    required this.token,
  });

  final AuthController controller;
  final String token;

  @override
  State<ResetPasswordConfirmPage> createState() =>
      _ResetPasswordConfirmPageState();
}

class _ResetPasswordConfirmPageState extends State<ResetPasswordConfirmPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or missing reset link. Request a new one.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      final success = await widget.controller.confirmResetPassword(
        widget.token,
        _newPasswordController.text,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated. You can sign in now.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.error ?? 'Failed to set new password',
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
    final screenWidth = MediaQuery.of(context).size.width;

    if (widget.token.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Invalid or missing reset link.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/reset-password'),
                    child: const Text('Request a new link'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  const Text(
                    'Set new password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your new password below.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                  SizedBox(height: screenWidth * 0.1),
                  CustomTextField(
                    label: 'New password',
                    hint: 'Enter new password',
                    icon: Icons.lock_outline,
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    suffixIcon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.cyan400.withOpacity(0.6),
                      size: 20,
                    ),
                    onSuffixIconTap: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    validator: Validators.password,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirm password',
                    hint: 'Confirm new password',
                    icon: Icons.lock_outline,
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    suffixIcon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.cyan400.withOpacity(0.6),
                      size: 20,
                    ),
                    onSuffixIconTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) => Validators.confirmPassword(
                      v,
                      _newPasswordController.text,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                  SizedBox(height: screenWidth * 0.08),
                  CustomButton(
                    text: 'Set password',
                    onPressed: _handleSubmit,
                    isLoading: widget.controller.isLoading,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
