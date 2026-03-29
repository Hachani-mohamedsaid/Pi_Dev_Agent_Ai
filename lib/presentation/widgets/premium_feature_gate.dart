import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/subscription_access_service.dart';

class PremiumFeatureGate extends StatefulWidget {
  const PremiumFeatureGate({super.key, required this.child});

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/subscription');
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
