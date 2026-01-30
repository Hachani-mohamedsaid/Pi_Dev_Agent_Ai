import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_calculatePasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordController.removeListener(_calculatePasswordStrength);
    super.dispose();
  }

  void _calculatePasswordStrength() {
    final password = _newPasswordController.text;
    int strength = 0;
    if (password.length >= 8) strength += 25;
    if (password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'))) strength += 25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 25;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) strength += 25;
    setState(() {
      _passwordStrength = strength;
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 50) return Colors.red;
    if (_passwordStrength < 75) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText() {
    if (_passwordStrength < 50) return 'Weak';
    if (_passwordStrength < 75) return 'Medium';
    return 'Strong';
  }

  bool _meetsRequirement(String requirement) {
    final password = _newPasswordController.text;
    switch (requirement) {
      case 'length':
        return password.length >= 8;
      case 'case':
        return password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'));
      case 'number':
        return password.contains(RegExp(r'[0-9]'));
      case 'special':
        return password.contains(RegExp(r'[^a-zA-Z0-9]'));
      default:
        return false;
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_passwordStrength < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password is too weak'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Handle password change
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: padding,
              bottom: padding + MediaQuery.of(context).padding.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryLight.withOpacity(0.6),
                              AppColors.primaryDarker.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.cyan400,
                              size: isMobile ? 20 : 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(width: isMobile ? 40 : 48),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 16 : 20),

                // Info Box
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan500.withOpacity(0.1),
                        AppColors.blue500.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    border: Border.all(
                      color: AppColors.cyan500.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            color: AppColors.cyan400,
                            size: isMobile ? 20 : 24,
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Create a strong password with at least 8 characters',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: AppColors.textCyan200.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Current Password
                      CustomTextField(
                        label: 'Current Password',
                        hint: 'Enter current password',
                        icon: Icons.lock_outline,
                        controller: _currentPasswordController,
                        obscureText: !_showCurrentPassword,
                        suffixIcon: Icon(
                          _showCurrentPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.cyan400.withOpacity(0.5),
                          size: isMobile ? 20 : 22,
                        ),
                        onSuffixIconTap: () {
                          setState(() {
                            _showCurrentPassword = !_showCurrentPassword;
                          });
                        },
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),

                      // New Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'New Password',
                            hint: 'Enter new password',
                            icon: Icons.lock_outline,
                            controller: _newPasswordController,
                            obscureText: !_showNewPassword,
                            suffixIcon: Icon(
                              _showNewPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.cyan400.withOpacity(0.5),
                              size: isMobile ? 20 : 22,
                            ),
                            onSuffixIconTap: () {
                              setState(() {
                                _showNewPassword = !_showNewPassword;
                              });
                            },
                          ),
                          if (_newPasswordController.text.isNotEmpty) ...[
                            SizedBox(height: isMobile ? 12 : 16),
                            // Password Strength Indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _passwordStrength / 100,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Password strength: ${_getStrengthText()}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    color: _getStrengthColor(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 20 : 24),

                      // Confirm Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'Confirm New Password',
                            hint: 'Confirm new password',
                            icon: Icons.lock_outline,
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            suffixIcon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.cyan400.withOpacity(0.5),
                              size: isMobile ? 20 : 22,
                            ),
                            onSuffixIconTap: () {
                              setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          if (_confirmPasswordController.text.isNotEmpty &&
                              _newPasswordController.text == _confirmPasswordController.text)
                            Padding(
                              padding: EdgeInsets.only(top: isMobile ? 8 : 12, left: isMobile ? 4 : 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade400,
                                    size: isMobile ? 16 : 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Passwords match',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      color: Colors.green.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 24 : 32),

                      // Requirements
                      Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryLight.withOpacity(0.4),
                              AppColors.primaryDarker.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password Requirements:',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                _RequirementItem(
                                  text: 'At least 8 characters',
                                  met: _meetsRequirement('length'),
                                  isMobile: isMobile,
                                ),
                                SizedBox(height: isMobile ? 8 : 12),
                                _RequirementItem(
                                  text: 'Upper and lowercase letters',
                                  met: _meetsRequirement('case'),
                                  isMobile: isMobile,
                                ),
                                SizedBox(height: isMobile ? 8 : 12),
                                _RequirementItem(
                                  text: 'At least one number',
                                  met: _meetsRequirement('number'),
                                  isMobile: isMobile,
                                ),
                                SizedBox(height: isMobile ? 8 : 12),
                                _RequirementItem(
                                  text: 'At least one special character',
                                  met: _meetsRequirement('special'),
                                  isMobile: isMobile,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                      SizedBox(height: isMobile ? 32 : 40),

                      // Save Button
                      CustomButton(
                        text: 'Update Password',
                        onPressed: _handleSave,
                        isLoading: false,
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),
                    ],
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

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool met;
  final bool isMobile;

  const _RequirementItem({
    required this.text,
    required this.met,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isMobile ? 6 : 8,
          height: isMobile ? 6 : 8,
          decoration: BoxDecoration(
            color: met ? Colors.green.shade400 : AppColors.cyan500.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: AppColors.textCyan200.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
