import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shell.dart';
import '../../core/theme/ava_theme.dart';

Color _flowPrimaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textWhite
      : const Color(0xFF12263A);
}

Color _flowSecondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textCyan200
      : const Color(0xFF5B7B92);
}

Color _flowSurface(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.primaryDarker
      : const Color(0xFFFFFFFF);
}

Color _flowSurfaceBorder(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.cyan500.withValues(alpha: 0.22)
      : const Color(0xFFC7DDE9);
}

/// Step 1 — enter deal terms, then navigate to swipe comparables.
class MarketIntelligenceFormScreen extends StatefulWidget {
  const MarketIntelligenceFormScreen({super.key, this.sessionId = ''});

  final String sessionId;

  @override
  State<MarketIntelligenceFormScreen> createState() =>
      _MarketIntelligenceFormScreenState();
}

class _MarketIntelligenceFormScreenState
    extends State<MarketIntelligenceFormScreen> {
  final _valuationCtrl = TextEditingController();
  final _equityCtrl = TextEditingController();
  final _focusValuation = FocusNode();

  String _sector = 'FinTech';
  String _stage = 'Seed';
  String _geography = 'Europe';

  static const _sectors = [
    'FinTech',
    'HealthTech',
    'SaaS',
    'Climate',
    'Consumer',
  ];
  static const _stages = ['Pre-seed', 'Seed', 'Series A', 'Series B'];
  static const _geos = ['Europe', 'UK', 'DACH', 'France', 'Global'];

  @override
  void initState() {
    super.initState();
    _focusValuation.addListener(() => setState(() {}));
    _valuationCtrl.addListener(() => setState(() {}));
    _equityCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _valuationCtrl.dispose();
    _equityCtrl.dispose();
    _focusValuation.dispose();
    super.dispose();
  }

  double? _tryParseValuation(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String _formatValuationDisplay(double n) {
    final fmt = NumberFormat.currency(
      locale: 'en_IE',
      symbol: '€',
      decimalDigits: 0,
    );
    return fmt.format(n).replaceFirst('€', '€ ');
  }

  String _barLabel(double n) {
    if (n >= 1000000) {
      final m = n / 1000000;
      final s = (m - m.round()).abs() < 0.05
          ? m.round().toString()
          : m.toStringAsFixed(1);
      return '€${s}M';
    }
    if (n >= 1000) return '€${(n / 1000).round()}K';
    return '€${n.round()}';
  }

  void _submit() {
    final numVal = _tryParseValuation(_valuationCtrl.text);
    final equity = _equityCtrl.text.trim();
    if (numVal == null || numVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a proposed valuation amount.'),
          backgroundColor: AppColors.statusRejected,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (equity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter the equity you are offering.'),
          backgroundColor: AppColors.statusRejected,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final display = _formatValuationDisplay(numVal);
    final bar = _barLabel(numVal);
    context.push(
      '/market-intelligence/swipe',
      extra: <String, dynamic>{
        'sessionId': widget.sessionId,
        'proposedValuation': display,
        'proposedValuationNum': numVal,
        'proposedEquity': equity,
        'sector': _sector,
        'stage': _stage,
        'geography': _geography,
        'valuationBarLabel': bar,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focused = _focusValuation.hasFocus;
    final edge = _flowSurfaceBorder(context);

    return AppShellGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.textCyan200 : const Color(0xFF5B7B92),
              size: 18,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Market Intelligence',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _flowPrimaryText(context),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              color: AppColors.cyan500.withValues(alpha: 0.22),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text('YOUR DEAL', style: AvaText.label),
            const SizedBox(height: 5),
            Text(
              'What are you\nproposing?',
              style: AvaText.display.copyWith(
                color: isDark ? AvaColors.text : const Color(0xFF12344C),
              ),
            ),
            const SizedBox(height: 28),
            _avaMessageCard(),
            const SizedBox(height: 22),
            _fieldLabel('YOUR PROPOSED VALUATION'),
            const SizedBox(height: 6),
            TextField(
              controller: _valuationCtrl,
              focusNode: _focusValuation,
              keyboardType: TextInputType.text,
              style: AvaText.body.copyWith(
                fontSize: 13,
                color: _flowPrimaryText(context),
              ),
              decoration: InputDecoration(
                hintText: 'e.g. € 1,000,000',
                hintStyle: TextStyle(
                  color: isDark ? AvaColors.muted : const Color(0xFF7A96AA),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: _flowSurface(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: focused ? AppColors.cyan400 : edge,
                    width: focused ? 1.5 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: edge),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.cyan400,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('EQUITY YOU ARE OFFERING'),
            const SizedBox(height: 6),
            TextField(
              controller: _equityCtrl,
              style: AvaText.body.copyWith(
                fontSize: 13,
                color: _flowPrimaryText(context),
              ),
              decoration: _inputDecoration().copyWith(
                hintText: 'e.g. 15%',
                hintStyle: TextStyle(
                  color: isDark ? AvaColors.muted : const Color(0xFF7A96AA),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('SECTOR'),
                      const SizedBox(height: 6),
                      _dropdown<String>(
                        value: _sector,
                        items: _sectors,
                        onChanged: (v) =>
                            setState(() => _sector = v ?? _sector),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('STAGE'),
                      const SizedBox(height: 6),
                      _dropdown<String>(
                        value: _stage,
                        items: _stages,
                        onChanged: (v) => setState(() => _stage = v ?? _stage),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _fieldLabel('GEOGRAPHY'),
            const SizedBox(height: 6),
            _dropdown<String>(
              value: _geography,
              items: _geos,
              onChanged: (v) => setState(() => _geography = v ?? _geography),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _submit,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.buttonGradient,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Find Comparable Deals',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _fieldLabel(String t) => Text(t, style: AvaText.label);

  InputDecoration _inputDecoration() {
    final edge = _flowSurfaceBorder(context);
    return InputDecoration(
      filled: true,
      fillColor: _flowSurface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: edge),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cyan400, width: 1.5),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final edge = _flowSurfaceBorder(context);
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      onChanged: onChanged,
      dropdownColor: _flowSurface(context),
      style: AvaText.body.copyWith(
        fontSize: 13,
        color: _flowPrimaryText(context),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? AvaColors.muted : const Color(0xFF7A96AA),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _flowSurface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: edge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: edge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan400, width: 1.5),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
          .toList(),
    );
  }

  Widget _avaMessageCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.cardGradient
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF9FCFF), Color(0xFFEAF4FB)],
              ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark
              ? AppColors.cyan500.withValues(alpha: 0.28)
              : const Color(0xFFC7DDE9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avaAvatar(size: 28),
              const SizedBox(width: 8),
              const Text(
                'AVA',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppColors.cyan400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Enter your proposed deal terms and I will find real comparable '
            'companies that raised under the same conditions.',
            style: AvaText.body.copyWith(
              fontSize: 13,
              color: _flowSecondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}
