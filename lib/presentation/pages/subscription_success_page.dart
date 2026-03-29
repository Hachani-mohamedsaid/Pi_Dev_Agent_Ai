import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../injection_container.dart';

class SubscriptionSuccessPage extends StatefulWidget {
  const SubscriptionSuccessPage({super.key, required this.plan});

  final String plan;

  @override
  State<SubscriptionSuccessPage> createState() =>
      _SubscriptionSuccessPageState();
}

class _SubscriptionSuccessPageState extends State<SubscriptionSuccessPage> {
  static const _activePlanKeyPrefix = 'subscription_active_plan';
  static const _legacyActivePlanKey = 'subscription_active_plan';
  bool _successAlertShown = false;

  @override
  void initState() {
    super.initState();
    _recordActivePlan();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPaymentSuccessAlert();
    });
  }

  Future<void> _showPaymentSuccessAlert() async {
    if (!mounted || _successAlertShown) return;
    _successAlertShown = true;

    final planLabel = widget.plan == 'yearly'
        ? AppStrings.tr(context, 'subscriptionYearly')
        : AppStrings.tr(context, 'subscriptionMonthly');

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: const Color(0xFF132A3D),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusAccepted.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.statusAccepted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.tr(context, 'subscriptionSuccessTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '$planLabel — ${AppStrings.tr(context, 'subscriptionActiveBadge')}',
            style: TextStyle(color: AppColors.textCyan200, height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Enregistrer le forfait comme actif dans SharedPreferences
  Future<void> _recordActivePlan() async {
    if (widget.plan != 'yearly' && widget.plan != 'monthly') return;
    final prefs = await SharedPreferences.getInstance();
    final userId = await InjectionContainer.instance.authLocalDataSource
        .getUserId();
    final key = (userId == null || userId.isEmpty)
        ? _legacyActivePlanKey
        : '$_activePlanKeyPrefix:$userId';
    await prefs.setString(key, widget.plan);
  }

  String get _planLabel =>
      widget.plan == 'yearly' ? 'subscriptionYearly' : 'subscriptionMonthly';

  @override
  Widget build(BuildContext context) {
    final isYearly = widget.plan == 'yearly';
    final planLabel = AppStrings.tr(context, _planLabel);
    final description = isYearly
        ? AppStrings.tr(context, 'subscriptionSuccessDescriptionYearly')
        : AppStrings.tr(context, 'subscriptionSuccessDescriptionMonthly');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.getResponsiveValue(
                  context,
                  mobile: 24.0,
                  tablet: 32.0,
                  desktop: 40.0,
                ),
                vertical: Responsive.getResponsiveValue(
                  context,
                  mobile: 36.0,
                  tablet: 42.0,
                  desktop: 48.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: EdgeInsets.all(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 24.0,
                        tablet: 28.0,
                        desktop: 32.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.cyan500.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.statusAccepted.withValues(
                              alpha: 0.16,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 52,
                            color: AppColors.statusAccepted,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          AppStrings.tr(context, 'subscriptionSuccessTitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 24.0,
                              tablet: 26.0,
                              desktop: 28.0,
                            ),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textWhite,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '$planLabel — ${AppStrings.tr(context, 'subscriptionActiveBadge')}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 15.0,
                              tablet: 16.0,
                              desktop: 17.0,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textCyan300,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 15.0,
                              desktop: 16.0,
                            ),
                            height: 1.6,
                            color: AppColors.textCyan200.withValues(
                              alpha: 0.92,
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/profile'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.cyan500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              AppStrings.tr(
                                context,
                                'subscriptionSuccessBackToProfile',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/home'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.cyan400.withValues(
                                  alpha: 0.68,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              AppStrings.tr(
                                context,
                                'subscriptionSuccessBackToHome',
                              ),
                              style: TextStyle(
                                color: AppColors.textCyan200,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
    );
  }
}
