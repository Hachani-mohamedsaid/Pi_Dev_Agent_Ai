import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/subscription_access_service.dart';
import 'premium_gate_sheet.dart';

class PremiumFeatureGate extends StatefulWidget {
  const PremiumFeatureGate({
    super.key,
    required this.featureName,
    required this.child,
  });

  /// Shown in [PremiumGateSheet] when access is denied.
  final String featureName;
  final Widget child;

  @override
  State<PremiumFeatureGate> createState() => _PremiumFeatureGateState();
}

class _PremiumFeatureGateState extends State<PremiumFeatureGate> {
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final allowed =
        await SubscriptionAccessService.hasActivePlanForCurrentUser();
    if (!mounted) return;

    if (!allowed) {
      final name = widget.featureName;
      final router = GoRouter.of(context);
      final navKey = router.routerDelegate.navigatorKey;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (router.canPop()) {
          router.pop();
        } else {
          router.go('/home');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = navKey.currentContext;
          if (ctx != null && ctx.mounted) {
            PremiumGateSheet.show(ctx, name);
          }
        });
      });
    }

    setState(() {
      _allowed = allowed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_allowed) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return widget.child;
  }
}
