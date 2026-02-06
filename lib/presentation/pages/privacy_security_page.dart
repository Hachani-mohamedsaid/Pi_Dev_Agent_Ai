import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../state/auth_controller.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key, this.controller});

  final AuthController? controller;

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _faceId = true;
  bool _fingerprint = false;
  bool _twoFactor = false;
  bool _activityStatus = true;
  bool _analytics = true;

  /// Email considéré vérifié si le backend renvoie emailVerified == true (après clic sur le lien reçu par email).
  bool get _emailVerified {
    final c = widget.controller;
    if (c == null) return false;
    if (c.currentProfile?.emailVerified == true) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onAuthUpdate);
    widget.controller?.loadProfile();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onAuthUpdate);
    super.dispose();
  }

  void _onAuthUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 24.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: padding,
              right: padding,
              top: padding,
              bottom: padding + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                              borderRadius: BorderRadius.circular(
                                isMobile ? 12 : 14,
                              ),
                              border: Border.all(
                                color: AppColors.cyan500.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 12 : 14,
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: AppColors.cyan400,
                                  size: isMobile ? 20 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Privacy & Security',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 40 : 48),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 16 : 20),

                // Header Info
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
                                Icons.security,
                                color: AppColors.cyan400,
                                size: isMobile ? 20 : 24,
                              ),
                              SizedBox(width: isMobile ? 12 : 16),
                              Expanded(
                                child: Text(
                                  'Manage your security and privacy settings',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    color: AppColors.textCyan200.withOpacity(
                                      0.7,
                                    ),
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

                // Account Security Section
                _SectionTitle(
                  title: 'Account Security',
                  isMobile: isMobile,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Change Password
                _SecurityItem(
                      icon: Icons.lock,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () => context.push('/change-password'),
                      isMobile: isMobile,
                    )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Email Verification : envoi d’un email avec lien (Resend) via POST /auth/verify-email
                _EmailVerificationItem(
                      isVerified: _emailVerified,
                      onVerify: () async {
                        final c = widget.controller;
                        if (c == null) return;
                        final success = await c.requestEmailVerification();
                        if (!mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Un email avec un lien de vérification vous a été envoyé. Consultez votre boîte mail.',
                              ),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                c.error ??
                                    'Impossible d’envoyer l’email. Réessayez plus tard.',
                              ),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      isMobile: isMobile,
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Two-Factor Authentication
                _SecurityToggleItem(
                      icon: Icons.security,
                      title: 'Two-Factor Authentication',
                      subtitle: 'Add extra security layer',
                      value: _twoFactor,
                      onChanged: (value) => setState(() => _twoFactor = value),
                      isMobile: isMobile,
                    )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Biometric Authentication Section
                _SectionTitle(
                  title: 'Biometric Authentication',
                  isMobile: isMobile,
                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Face ID
                _SecurityToggleItem(
                      icon: Icons.face,
                      title: 'Face ID',
                      subtitle: 'Use Face ID to unlock',
                      value: _faceId,
                      onChanged: (value) => setState(() => _faceId = value),
                      isMobile: isMobile,
                      iconColor: Colors.purple,
                    )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Fingerprint
                _SecurityToggleItem(
                      icon: Icons.fingerprint,
                      title: 'Fingerprint',
                      subtitle: 'Use fingerprint to unlock',
                      value: _fingerprint,
                      onChanged: (value) =>
                          setState(() => _fingerprint = value),
                      isMobile: isMobile,
                      iconColor: Colors.orange,
                    )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Privacy Section
                _SectionTitle(
                  title: 'Privacy',
                  isMobile: isMobile,
                ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Activity Status
                _SecurityToggleItem(
                      icon: Icons.visibility,
                      title: 'Activity Status',
                      subtitle: "Show when you're active",
                      value: _activityStatus,
                      onChanged: (value) =>
                          setState(() => _activityStatus = value),
                      isMobile: isMobile,
                      iconColor: Colors.green,
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Analytics
                _SecurityToggleItem(
                      icon: Icons.analytics,
                      title: 'Analytics & Improvement',
                      subtitle: 'Help us improve the app',
                      value: _analytics,
                      onChanged: (value) => setState(() => _analytics = value),
                      isMobile: isMobile,
                    )
                    .animate()
                    .fadeIn(delay: 650.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
                SizedBox(height: isMobile ? 24 : 32),

                // Account Management Section
                _SectionTitle(
                  title: 'Account Management',
                  isMobile: isMobile,
                ).animate().fadeIn(delay: 700.ms, duration: 300.ms),
                SizedBox(height: isMobile ? 12 : 16),

                // Delete Account
                _DeleteAccountItem(isMobile: isMobile)
                    .animate()
                    .fadeIn(delay: 750.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isMobile;

  const _SectionTitle({required this.title, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isMobile ? 8 : 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 18 : 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isMobile;

  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan500.withOpacity(0.2),
                        AppColors.blue500.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.cyan400,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 16 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWhite,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppColors.textCyan200.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.cyan400.withOpacity(0.5),
                  size: isMobile ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailVerificationItem extends StatelessWidget {
  final bool isVerified;
  final VoidCallback onVerify;
  final bool isMobile;

  const _EmailVerificationItem({
    required this.isVerified,
    required this.onVerify,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan500.withOpacity(0.2),
                      AppColors.blue500.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                ),
                child: Icon(
                  Icons.mail_outline,
                  color: AppColors.cyan400,
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (isVerified) ...[
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade400,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.green.shade400,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Not Verified',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.orange.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isVerified)
                GestureDetector(
                  onTap: onVerify,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 20,
                      vertical: isMobile ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                    child: Text(
                      'Verify',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isMobile;
  final Color? iconColor;

  const _SecurityToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isMobile,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.cyan400;

    return Container(
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
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 24),
              ),
              SizedBox(width: isMobile ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: AppColors.textCyan200.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged, activeColor: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountItem extends StatelessWidget {
  final bool isMobile;

  const _DeleteAccountItem({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle delete account
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.primaryLight,
            title: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.textWhite),
            ),
            content: const Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone.',
              style: TextStyle(color: AppColors.textCyan200),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.cyan400),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Handle delete
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.15)],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 16 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade400,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Permanently delete your account',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.red.shade400.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.red.shade400.withOpacity(0.5),
                  size: isMobile ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
