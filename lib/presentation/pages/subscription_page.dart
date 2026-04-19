import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/stripe_checkout_service.dart';
import '../../injection_container.dart';
import '../widgets/navigation_bar.dart';

import 'package:pi_dev_agentia/generated/l10n.dart';

enum _BillingPlan { monthly, yearly }

/// Premium subscription: monthly vs yearly (promo on yearly).
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key, this.activePlan});

  final String? activePlan;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  static const _activePlanKeyPrefix = 'subscription_active_plan';
  static const _legacyActivePlanKey = 'subscription_active_plan';

  _BillingPlan _selected = _BillingPlan.yearly;
  String? _activePlan;
  bool _checkoutLoading = false;
  bool _couponLoading = false;
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  int _discountPercent = 0;

  static const double _monthlyBasePriceValue = 9.99;
  static const double _yearlyBasePriceValue = 99.99;

  @override
  void initState() {
    super.initState();
    _loadActivePlan();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubscriptionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePlan != null &&
        widget.activePlan != oldWidget.activePlan) {
      _setActivePlan(widget.activePlan!);
    }
  }

  Future<void> _loadActivePlan() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveActivePlanKey();
    final storedPlan = prefs.getString(key);
    final planToUse = widget.activePlan ?? storedPlan;
    if (planToUse != null &&
        (planToUse == 'yearly' || planToUse == 'monthly')) {
      if (mounted) {
        setState(() {
          _activePlan = planToUse;
          _selected = planToUse == 'yearly'
              ? _BillingPlan.yearly
              : _BillingPlan.monthly;
        });
      }
      if (storedPlan != planToUse) {
        await prefs.setString(key, planToUse);
      }
    }
  }

  Future<void> _setActivePlan(String plan) async {
    if (plan != 'yearly' && plan != 'monthly') return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveActivePlanKey();
    await prefs.setString(key, plan);
    if (mounted) {
      setState(() {
        _activePlan = plan;
        _selected = plan == 'yearly'
            ? _BillingPlan.yearly
            : _BillingPlan.monthly;
      });
    }
  }

  Future<String> _resolveActivePlanKey() async {
    final userId = await InjectionContainer.instance.authLocalDataSource
        .getUserId();
    if (userId == null || userId.isEmpty) {
      return _legacyActivePlanKey;
    }
    return '$_activePlanKeyPrefix:$userId';
  }

  void _showCheckoutSnackBar(String messageKey) {
    if (!mounted) return;
    final s = S.of(context);
    final message = _getSGetter(s, messageKey);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _getSGetter(S s, String key) {
    switch (key) {
      case 'subscriptionCheckoutFailed':
        return s.subscriptionCheckoutFailed;
      case 'subscriptionLoginRequired':
        return s.subscriptionLoginRequired;
      case 'subscriptionBackendMissing':
        return s.subscriptionBackendMissing;
      case 'subscriptionPlansIntro':
        return s.subscriptionPlansIntro;
      case 'subscriptionActiveBadge':
        return s.subscriptionActiveBadge;
      case 'subscriptionYearly':
        return s.subscriptionYearly;
      case 'subscriptionMonthly':
        return s.subscriptionMonthly;
      case 'subscriptionBilledMonthly':
        return s.subscriptionBilledMonthly;
      case 'subscriptionBilledYearly':
        return s.subscriptionBilledYearly;
      case 'subscriptionYearlyPromoLine':
        return s.subscriptionYearlyPromoLine;
      case 'subscriptionPaymentNote':
        return s.subscriptionPaymentNote;
      case 'premiumSubscription':
        return s.premiumSubscription;
      case 'subscriptionSubtitle':
        return s.subscriptionSubtitle;
      case 'subscriptionFeature1':
        return s.subscriptionFeature1;
      case 'subscriptionFeature2':
        return s.subscriptionFeature2;
      case 'subscriptionFeature3':
        return s.subscriptionFeature3;
      default:
        return key;
    }
  }

  Future<void> _openStripeCheckout(BuildContext context) async {
    if (_checkoutLoading) return;

    setState(() => _checkoutLoading = true);
    final plan = _selected == _BillingPlan.yearly ? 'yearly' : 'monthly';
    try {
      final service = InjectionContainer.instance.buildStripeCheckoutService();
      final url = await service.createCheckoutSessionUrl(
        plan: plan,
        couponCode: _appliedCoupon,
      );
      final uri = Uri.parse(url);
      final launched = await _launchCheckoutUrl(uri);
      if (!mounted) return;
      if (!launched) {
        _showCheckoutSnackBar('subscriptionCheckoutFailed');
      }
    } on StripeCheckoutException catch (e) {
      if (!mounted) return;
      final msgKey = switch (e.code) {
        'login_required' => 'subscriptionLoginRequired',
        'http_404' || 'http_501' || 'http_502' => 'subscriptionBackendMissing',
        _ => 'subscriptionCheckoutFailed',
      };
      _showCheckoutSnackBar(msgKey);
    } catch (_) {
      if (!mounted) return;
      _showCheckoutSnackBar('subscriptionCheckoutFailed');
    } finally {
      if (mounted) setState(() => _checkoutLoading = false);
    }
  }

  Future<bool> _launchCheckoutUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return await launchUrl(uri, mode: LaunchMode.inAppWebView);
  }

  Future<void> _applyCoupon() async {
    final value = _couponController.text.trim().toUpperCase();
    if (value.isEmpty) {
      _showCheckoutSnackBar('subscriptionCheckoutFailed');
      return;
    }

    if (_couponLoading) return;
    setState(() => _couponLoading = true);

    try {
      final plan = _selected == _BillingPlan.yearly ? 'yearly' : 'monthly';
      final service = InjectionContainer.instance.buildStripeCheckoutService();
      final result = await service.validateCoupon(
        couponCode: value,
        plan: plan,
      );

      if (!result.valid || !result.active) {
        if (!mounted) return;
        setState(() {
          _appliedCoupon = null;
          _discountPercent = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Coupon inactive or invalid.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _appliedCoupon = value;
        _discountPercent = result.discountPercent ?? 30;
      });
    } on StripeCheckoutException catch (_) {
      if (!mounted) return;
      setState(() {
        _appliedCoupon = null;
        _discountPercent = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Coupon validation failed. Check backend coupon status.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _couponLoading = false);
    }
  }

  void _handleBackTap(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final s = S.of(context);
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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: padding,
                  bottom: Responsive.getResponsiveValue(
                    context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 140.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.1, end: 0, duration: 300.ms),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 18.0,
                        desktop: 20.0,
                      ),
                    ),
                    Text(
                      s.subscriptionPlansIntro,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                        height: 1.45,
                        color: AppColors.textCyan200.withValues(alpha: 0.88),
                      ),
                    ).animate().fadeIn(delay: 50.ms, duration: 320.ms),
                    if (_activePlan != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 18.0,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan400.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.cyan400.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            '${s.subscriptionActiveBadge} : ${_activePlan == 'yearly' ? s.subscriptionYearly : s.subscriptionMonthly}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textCyan200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 22.0,
                        tablet: 26.0,
                        desktop: 30.0,
                      ),
                    ),
                    LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth > 520;
                            final gap = Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 16.0,
                              desktop: 18.0,
                            );
                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _PlanCard(
                                      isMobile: isMobile,
                                      title: s.subscriptionMonthly,
                                      subtitle: s.subscriptionBilledMonthly,
                                      selected:
                                          _selected == _BillingPlan.monthly,
                                      isActive: _activePlan == 'monthly',
                                      isYearly: false,
                                      discountPercent: _discountPercent,
                                      couponApplied: _appliedCoupon != null,
                                      basePrice: _monthlyBasePriceValue,
                                      onTap: () => setState(
                                        () => _selected = _BillingPlan.monthly,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Expanded(
                                    child: _PlanCard(
                                      isMobile: isMobile,
                                      title: s.subscriptionYearly,
                                      subtitle: s.subscriptionBilledYearly,
                                      selected:
                                          _selected == _BillingPlan.yearly,
                                      isActive: _activePlan == 'yearly',
                                      isYearly: true,
                                      discountPercent: _discountPercent,
                                      couponApplied: _appliedCoupon != null,
                                      basePrice: _yearlyBasePriceValue,
                                      promoLine: s.subscriptionYearlyPromoLine,
                                      onTap: () => setState(
                                        () => _selected = _BillingPlan.yearly,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _PlanCard(
                                  isMobile: isMobile,
                                  title: s.subscriptionMonthly,
                                  subtitle: s.subscriptionBilledMonthly,
                                  selected: _selected == _BillingPlan.monthly,
                                  isActive: _activePlan == 'monthly',
                                  isYearly: false,
                                  discountPercent: _discountPercent,
                                  couponApplied: _appliedCoupon != null,
                                  basePrice: _monthlyBasePriceValue,
                                  onTap: () => setState(
                                    () => _selected = _BillingPlan.monthly,
                                  ),
                                ),
                                SizedBox(height: gap),
                                _PlanCard(
                                  isMobile: isMobile,
                                  title: s.subscriptionYearly,
                                  subtitle: s.subscriptionBilledYearly,
                                  selected: _selected == _BillingPlan.yearly,
                                  isActive: _activePlan == 'yearly',
                                  isYearly: true,
                                  discountPercent: _discountPercent,
                                  couponApplied: _appliedCoupon != null,
                                  basePrice: _yearlyBasePriceValue,
                                  promoLine: s.subscriptionYearlyPromoLine,
                                  onTap: () => setState(
                                    () => _selected = _BillingPlan.yearly,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 380.ms)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          delay: 100.ms,
                          duration: 380.ms,
                        ),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                    ),
                    _buildCouponCard(
                      context,
                      isMobile,
                    ).animate().fadeIn(delay: 130.ms, duration: 320.ms),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 22.0,
                        tablet: 26.0,
                        desktop: 30.0,
                      ),
                    ),
                    _buildFeaturesCard(context, isMobile)
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 380.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          delay: 180.ms,
                          duration: 380.ms,
                        ),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 22.0,
                        tablet: 26.0,
                        desktop: 30.0,
                      ),
                    ),
                    _buildCta(
                      context,
                      isMobile,
                    ).animate().fadeIn(delay: 240.ms, duration: 350.ms),
                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                      ),
                    ),
                    Center(
                      child: Text(
                        s.subscriptionPaymentNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          height: 1.4,
                          color: AppColors.textCyan200.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final s = S.of(context);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleBackTap(context),
          child: Container(
            padding: EdgeInsets.all(
              Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan500.withValues(alpha: 0.3),
                  AppColors.blue500.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(
                Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
              ),
              border: Border.all(
                color: AppColors.cyan500.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: AppColors.cyan400,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 20.0,
                tablet: 22.0,
                desktop: 24.0,
              ),
            ),
          ),
        ),
        SizedBox(
          width: Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan500.withValues(alpha: 0.25),
                          AppColors.blue500.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cyan400.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.crown,
                      color: AppColors.textCyan300,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 22.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(context, mobile: 12.0),
                  ),
                  Expanded(
                    child: Text(
                      s.premiumSubscription,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 21.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        ),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(context, mobile: 8.0),
              ),
              Text(
                s.subscriptionSubtitle,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 13.0,
                    tablet: 14.0,
                    desktop: 15.0,
                  ),
                  color: AppColors.textCyan200.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesCard(BuildContext context, bool isMobile) {
    final s = S.of(context);
    final features = [
      s.subscriptionFeature1,
      s.subscriptionFeature2,
      s.subscriptionFeature3,
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 22.0,
          desktop: 24.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.42),
            AppColors.primaryDarker.withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 18.0,
            tablet: 20.0,
            desktop: 22.0,
          ),
        ),
        border: Border.all(
          color: AppColors.cyan500.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 18.0,
            tablet: 20.0,
            desktop: 22.0,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    color: AppColors.cyan400,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    AppStrings.tr(context, 'subscriptionWhatsIncluded'),
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 17.0,
                        desktop: 18.0,
                      ),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
              ...features.map(
                (t) => Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.getResponsiveValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 14.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.check,
                        size: 18,
                        color: AppColors.statusAccepted,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 15.0,
                              desktop: 15.0,
                            ),
                            height: 1.4,
                            color: AppColors.textCyan200.withValues(
                              alpha: 0.92,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, bool isMobile) {
    final showSavings =
        _discountPercent > 0 && _selected == _BillingPlan.yearly;
    const yearlyBase = 99.99;
    final discounted = yearlyBase * (1 - (_discountPercent / 100));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan500.withValues(alpha: 0.12),
            AppColors.blue500.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Champion Coupon',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monthly #1 can use a one-time coupon for upgrade discount.',
            style: TextStyle(color: AppColors.textCyan200, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon (ex: CHAMP-APR-2026)',
                    hintStyle: TextStyle(
                      color: AppColors.textCyan200.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDarker.withValues(alpha: 0.35),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.cyan500.withValues(alpha: 0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.cyan500.withValues(alpha: 0.25),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppColors.cyan400),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textWhite),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _couponLoading ? null : () => _applyCoupon(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan500,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _couponLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 10),
            Text(
              'Coupon $_appliedCoupon applied: $_discountPercent% off',
              style: const TextStyle(
                color: AppColors.statusAccepted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          if (showSavings) ...[
            const SizedBox(height: 6),
            Text(
              'Yearly after discount: ${discounted.toStringAsFixed(2)} €',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context, bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _checkoutLoading ? null : () => _openStripeCheckout(context),
          borderRadius: BorderRadius.circular(
            Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(
                Responsive.getResponsiveValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan500.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.getResponsiveValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
              child: Center(
                child: _checkoutLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      )
                    : Text(
                        AppStrings.tr(context, 'subscriptionContinue'),
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 16.0,
                            tablet: 17.0,
                            desktop: 18.0,
                          ),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.isMobile,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isActive,
    required this.isYearly,
    required this.onTap,
    this.discountPercent = 0,
    this.couponApplied = false,
    this.basePrice = 9.99,
    this.promoLine,
  });

  final bool isMobile;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isActive;
  final bool isYearly;
  final VoidCallback onTap;
  final int discountPercent;
  final bool couponApplied;
  final double basePrice;
  final String? promoLine;

  @override
  Widget build(BuildContext context) {
    final radius = Responsive.getResponsiveValue(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );
    final curr = AppStrings.tr(context, 'subscriptionCurrencySuffix');
    final monthPrice = AppStrings.tr(context, 'subscriptionPriceMonth');
    final yearWas = AppStrings.tr(context, 'subscriptionPriceYearWas');
    final hasCouponDiscount = couponApplied && discountPercent > 0;
    final effectivePrice = hasCouponDiscount
        ? basePrice * (1 - (discountPercent / 100))
        : basePrice;
    final effectivePriceLabel = effectivePrice.toStringAsFixed(2);
    final basePriceLabel = basePrice.toStringAsFixed(2);

    final borderGradient = selected
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22D3EE), Color(0xFF3B82F6), Color(0xFF06B6D4)],
          )
        : LinearGradient(
            colors: [
              AppColors.cyan500.withValues(alpha: 0.15),
              AppColors.cyan500.withValues(alpha: 0.08),
            ],
          );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 220.ms,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.cyan400.withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                painter: _GradientBorderPainter(
                  gradient: borderGradient,
                  strokeWidth: selected ? 2.2 : 1,
                  radius: radius,
                ),
                child: Container(
                  margin: EdgeInsets.all(selected ? 1.6 : 0.8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius - 1),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryLight.withValues(
                          alpha: isYearly ? 0.55 : 0.4,
                        ),
                        AppColors.primaryDarker.withValues(alpha: 0.52),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius - 1),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          Responsive.getResponsiveValue(context, mobile: 18.0),
                          Responsive.getResponsiveValue(context, mobile: 20.0),
                          Responsive.getResponsiveValue(context, mobile: 18.0),
                          Responsive.getResponsiveValue(context, mobile: 20.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 17.0,
                                        tablet: 18.0,
                                        desktop: 19.0,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ),
                                if (isYearly || hasCouponDiscount)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.95),
                                          const Color(
                                            0xFFD97706,
                                          ).withValues(alpha: 0.95),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.35),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      hasCouponDiscount
                                          ? 'Coupon -$discountPercent%'
                                          : AppStrings.tr(
                                              context,
                                              'subscriptionBestValue',
                                            ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (isYearly) ...[
                              SizedBox(
                                height: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 10.0,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEC4899,
                                      ).withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFF472B6,
                                        ).withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      AppStrings.tr(
                                        context,
                                        'subscriptionPromoBadge',
                                      ),
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFBCFE8),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (promoLine != null)
                                    Expanded(
                                      child: Text(
                                        hasCouponDiscount
                                            ? 'New promo applied from your coupon.'
                                            : promoLine!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.25,
                                          color: AppColors.textCyan200
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            SizedBox(
                              height: Responsive.getResponsiveValue(
                                context,
                                mobile: 16.0,
                                tablet: 18.0,
                                desktop: 20.0,
                              ),
                            ),
                            if (!isYearly)
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 28.0,
                                      tablet: 30.0,
                                      desktop: 32.0,
                                    ),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: hasCouponDiscount
                                          ? effectivePriceLabel
                                          : monthPrice,
                                    ),
                                    TextSpan(
                                      text: curr,
                                      style: TextStyle(
                                        fontSize: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 18.0,
                                          tablet: 20.0,
                                          desktop: 22.0,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textCyan200,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          style: TextStyle(
                                            fontSize:
                                                Responsive.getResponsiveValue(
                                                  context,
                                                  mobile: 28.0,
                                                  tablet: 30.0,
                                                  desktop: 32.0,
                                                ),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.1,
                                          ),
                                          children: [
                                            TextSpan(text: effectivePriceLabel),
                                            TextSpan(
                                              text: curr,
                                              style: TextStyle(
                                                fontSize:
                                                    Responsive.getResponsiveValue(
                                                      context,
                                                      mobile: 18.0,
                                                      tablet: 20.0,
                                                      desktop: 22.0,
                                                    ),
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textCyan200,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          '${hasCouponDiscount ? basePriceLabel : yearWas}${AppStrings.tr(context, 'subscriptionCurrencySuffix')}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: AppColors
                                                .textCyan200
                                                .withValues(alpha: 0.6),
                                            color: AppColors.textCyan200
                                                .withValues(alpha: 0.45),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            if (!isYearly && hasCouponDiscount)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Promo applied from coupon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.statusAccepted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                              ),
                            ),
                            Text(
                              isYearly
                                  ? AppStrings.tr(
                                      context,
                                      'subscriptionPerYearSuffix',
                                    ).trim()
                                  : AppStrings.tr(
                                      context,
                                      'subscriptionPerMonthSuffix',
                                    ),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textCyan200.withValues(
                                  alpha: 0.75,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveValue(
                                context,
                                mobile: 14.0,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 13.0,
                                  desktop: 13.0,
                                ),
                                height: 1.35,
                                color: AppColors.textCyan200.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveValue(
                                context,
                                mobile: 14.0,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  selected
                                      ? LucideIcons.checkCircle
                                      : LucideIcons.circle,
                                  size: 20,
                                  color: selected
                                      ? AppColors.cyan400
                                      : AppColors.textCyan200.withValues(
                                          alpha: 0.35,
                                        ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  selected
                                      ? AppStrings.tr(context, 'done')
                                      : AppStrings.tr(context, 'continue'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppColors.textCyan300
                                        : AppColors.textCyan200.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            if (isActive)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan400.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.cyan400.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.tr(
                                      context,
                                      'subscriptionActiveBadge',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cyan400,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws an inner stroke so gradient "border" sits inside the rounded rect.
class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.radius,
  });

  final LinearGradient gradient;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius - strokeWidth / 2),
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
