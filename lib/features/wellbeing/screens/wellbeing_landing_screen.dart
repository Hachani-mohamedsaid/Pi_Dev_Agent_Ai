import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/wellbeing_api_client.dart';
import '../data/wellbeing_registration.dart';
import '../data/wellbeing_storage.dart';
import '../wellbeing_section_styles.dart';

/// Landing: module intro + gate before the 9-question check-in.
class WellbeingLandingScreen extends StatefulWidget {
  const WellbeingLandingScreen({super.key});

  @override
  State<WellbeingLandingScreen> createState() => _WellbeingLandingScreenState();
}

class _WellbeingLandingScreenState extends State<WellbeingLandingScreen> {
  final _api = WellbeingApiClient();
  bool _loading = true;
  bool _allowed = true;
  String? _gateMessage;

  @override
  void initState() {
    super.initState();
    _loadGate();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _loadGate() async {
    setState(() {
      _loading = true;
      _gateMessage = null;
    });

    await ensureWellbeingIdentity(_api);

    if (_api.isConfigured) {
      var uid = await WellbeingStorage.userId();
      if (uid != null && uid.isNotEmpty) {
        var st = await _api.fetchStatus(uid);
        if (st?.userNotFound == true) {
          await WellbeingStorage.clearWellbeingIdentity();
          await ensureWellbeingIdentity(_api);
          uid = await WellbeingStorage.userId();
          if (uid != null && uid.isNotEmpty) {
            st = await _api.fetchStatus(uid);
          }
        }
        if (st != null && !st.userNotFound) {
          final s = st;
          setState(() {
            _allowed = s.allowed;
            _gateMessage = !s.allowed
                ? (s.nextAvailableDate != null
                    ? 'Next window: ${_formatNext(s.nextAvailableDate!)}'
                    : 'A check-in is not available for this cycle yet.')
                : null;
            _loading = false;
          });
          return;
        }
      }
    }

    final localOk = await WellbeingStorage.localMonthlyAllowed();
    setState(() {
      _allowed = localOk;
      _gateMessage = localOk
          ? null
          : 'You already completed this month’s check-in. Come back next month.';
      _loading = false;
    });
  }

  String _formatNext(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _startCheckIn() {
    if (!_allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_gateMessage ?? 'Check-in not available.')),
      );
      return;
    }
    context.push('/wellbeing/check-in');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  static const _bg = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.getResponsiveValue(
      context,
      mobile: 20.0,
      tablet: 28.0,
      desktop: 40.0,
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 52,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.cyan400,
          iconSize: 20,
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Back',
          onPressed: _goBack,
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyan400),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Phones stay one column: hero first, then Three Pillars + CTA below.
                final isPhone = Responsive.isMobile(context);
                final twoCol =
                    !isPhone && constraints.maxWidth >= 1040;
                final gapAfterHero = Responsive.getResponsiveValue(
                  context,
                  mobile: 36.0,
                  tablet: 32.0,
                  desktop: 28.0,
                );
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: twoCol
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _heroColumn(context),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 5,
                                  child: _rightColumn(context),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _heroColumn(context),
                                SizedBox(height: gapAfterHero),
                                _rightColumn(context),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _heroColumn(BuildContext context) {
    final titleSize = Responsive.getResponsiveValue(
      context,
      mobile: 30,
      tablet: 40,
      desktop: 46,
    );
    final subSize = Responsive.getResponsiveValue(
      context,
      mobile: 15,
      tablet: 16,
      desktop: 17,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'AVA',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 28,
                  tablet: 32,
                  desktop: 36,
                ),
                fontWeight: FontWeight.w900,
                color: AppColors.cyan400,
                letterSpacing: 3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.cyan400.withValues(alpha: 0.45),
                ),
                color: AppColors.cyan500.withValues(alpha: 0.08),
              ),
              child: Text(
                'WELLBEING',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.2,
                  color: AppColors.cyan400.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: Responsive.getResponsiveValue(
            context,
            mobile: 24,
            tablet: 32,
            desktop: 40,
          ),
        ),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: titleSize.toDouble(),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.08,
              letterSpacing: -0.8,
            ),
            children: [
              const TextSpan(text: 'How are you '),
              TextSpan(
                text: 'really',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan400,
                  letterSpacing: -0.5,
                ),
              ),
              const TextSpan(text: ' doing?'),
            ],
          ),
        ),
        SizedBox(
          height: Responsive.getResponsiveValue(
            context,
            mobile: 16,
            tablet: 20,
            desktop: 22,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.cyan400.withValues(alpha: 0.55),
                width: 3,
              ),
            ),
          ),
          child: Text(
            'Your monthly psychological checkpoint — built for entrepreneurs. '
            'Nine questions, about two minutes, and a clear read on cognitive load, '
            'emotional pressure, and physical drain.',
            style: TextStyle(
              fontSize: subSize,
              fontWeight: FontWeight.w500,
              color: AppColors.textCyan200.withValues(alpha: 0.9),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rightColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'THREE PILLARS',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w900,
            color: AppColors.cyan400.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Each block maps to your diagnostic',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 18),
        _pillarCard(
          style: WellbeingSectionStyle.cognitive,
          icon: Icons.psychology_rounded,
          title: 'DECISION & COGNITIVE',
          subtitle: 'Mental processing & clarity',
        ),
        const SizedBox(height: 12),
        _pillarCard(
          style: WellbeingSectionStyle.emotional,
          icon: Icons.favorite_rounded,
          title: 'EMOTIONAL & SOCIAL',
          subtitle: 'Anxiety, guilt & isolation',
        ),
        const SizedBox(height: 12),
        _pillarCard(
          style: WellbeingSectionStyle.physical,
          icon: Icons.bolt_rounded,
          title: 'PHYSICAL & ENERGY',
          subtitle: 'Body signals & vitality',
        ),
        if (_gateMessage != null) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cyan500.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              _gateMessage!,
              style: const TextStyle(
                color: AppColors.textCyan200,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
        SizedBox(
          height: Responsive.getResponsiveValue(
            context,
            mobile: 28,
            tablet: 32,
            desktop: 36,
          ),
        ),
        SizedBox(
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppColors.buttonGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan500.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _startCheckIn,
                child: Center(
                  child: Text(
                    'START MY CHECK-IN  →',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 15,
                      color: _allowed ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillarCard({
    required WellbeingSectionStyle style,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: style.cardBorderGradient,
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.5),
          color: Color.lerp(_bg, style.surfaceTint, 0.45),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: style.likertSelectedGradient,
                boxShadow: [
                  BoxShadow(
                    color: style.glow.withValues(alpha: 0.45),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.6,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: style.bright.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
