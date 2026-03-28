import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/ava_theme.dart';
import '../../data/services/meeting_intelligence_service.dart';
import '../../injection_container.dart';
import 'briefing/briefing_shared.dart';

/// Page 2 — Meeting setup (3 steps). Wired from `/investor-meeting-setup`.
class MeetingSetupScreen extends StatefulWidget {
  const MeetingSetupScreen({super.key});

  @override
  State<MeetingSetupScreen> createState() => _MeetingSetupScreenState();
}

class _MeetingSetupScreenState extends State<MeetingSetupScreen> {
  int _step = 0;
  bool _loading = false;

  String? _draftId;
  String _confirmationText = '';

  final _investorName = TextEditingController();
  final _investorCompany = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  DateTime? _meetingAt;

  final _sector = TextEditingController();
  final _valuation = TextEditingController();
  final _equity = TextEditingController();
  final _investmentAsked = TextEditingController();
  final _revenue = TextEditingController();
  final _teamSize = TextEditingController();
  final _investorBio = TextEditingController();
  final _investorPosts = TextEditingController();

  String _dealType = 'Seed';
  String _meetingType = 'Formal';
  String _uploadedFile = '';

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  @override
  void dispose() {
    _investorName.dispose();
    _investorCompany.dispose();
    _country.dispose();
    _city.dispose();
    _sector.dispose();
    _valuation.dispose();
    _equity.dispose();
    _investmentAsked.dispose();
    _revenue.dispose();
    _teamSize.dispose();
    _investorBio.dispose();
    _investorPosts.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      _investorName.text.trim().isNotEmpty &&
      _country.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _meetingAt != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvaColors.bg,
      appBar: _appBar(),
      body: Column(
        children: [
          _stepCapsule(),
          _progressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _stepContent(),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: AvaColors.bg,
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          if (_step > 0) {
            setState(() => _step--);
          } else {
            context.pop();
          }
        },
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AvaColors.muted,
          size: 18,
        ),
      ),
      title: const Text(
        'Meeting Setup',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AvaColors.text,
        ),
      ),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AvaColors.border),
      ),
    );
  }

  Widget _stepCapsule() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AvaColors.gold.withValues(alpha: 0.45)),
          ),
          child: Text(
            'STEP ${_step + 1} OF 3',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: AvaColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(3, (i) {
          final filled = i <= _step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: filled ? AvaColors.gold : AvaColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      case 2:
        return _step3();
      default:
        return const SizedBox();
    }
  }

  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INVESTOR', style: AvaText.label),
        const SizedBox(height: 5),
        const Text('Who are you\nmeeting?', style: AvaText.display),
        const SizedBox(height: 28),
        _field('Investor Name', _investorName, hint: 'e.g. Marco Rossi', requiredField: true),
        const SizedBox(height: 14),
        _field('Company', _investorCompany, hint: 'e.g. Venture Italia'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _field('Country', _country, hint: 'e.g. France', requiredField: true)),
            const SizedBox(width: 12),
            Expanded(child: _field('City', _city, hint: 'e.g. Paris', requiredField: true)),
          ],
        ),
        const SizedBox(height: 14),
        _datePicker(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DEAL TERMS', style: AvaText.label),
        const SizedBox(height: 5),
        const Text('Context &\nstructure', style: AvaText.display),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _dropdown(
                'Deal Type',
                const ['Seed', 'Series A', 'Series B', 'Strategic Partnership'],
                _dealType,
                (v) => setState(() => _dealType = v ?? _dealType),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdown(
                'Format',
                const ['Formal', 'Lunch', 'Dinner', 'Video Call'],
                _meetingType,
                (v) => setState(() => _meetingType = v ?? _meetingType),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _field('Sector', _sector, hint: 'e.g. FinTech'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _field('Valuation', _valuation, hint: '€1,000,000')),
            const SizedBox(width: 12),
            Expanded(child: _field('Equity %', _equity, hint: '15%')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _field('Investment Asked', _investmentAsked, hint: '€150,000')),
            const SizedBox(width: 12),
            Expanded(child: _field('Team Size', _teamSize, hint: '4')),
          ],
        ),
        const SizedBox(height: 14),
        _field('Revenue', _revenue, hint: 'e.g. pre-revenue or €50K/month'),
        const SizedBox(height: 14),
        _textArea('Investor Bio / LinkedIn', _investorBio, lines: 4),
        const SizedBox(height: 14),
        _textArea('Public Quotes / Posts (optional)', _investorPosts, lines: 3),
        const SizedBox(height: 14),
        _uploadArea(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CONFIRM', style: AvaText.label),
        const SizedBox(height: 5),
        const Text('Review your\nmeeting context', style: AvaText.display),
        const SizedBox(height: 24),
        _avaConfirmBubble(),
        const SizedBox(height: 14),
        _summaryCard(),
        const SizedBox(height: 14),
        _readyBanner(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _avaConfirmBubble() {
    final text = _confirmationText.isEmpty
        ? 'Reviewing your meeting details…'
        : _confirmationText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avaAvatar(size: 22),
              const SizedBox(width: 7),
              const Text(
                'AVA',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AvaColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: AvaText.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final rows = <_SummaryRow>[
      _SummaryRow('Investor', _investorName.text.trim()),
      if (_investorCompany.text.trim().isNotEmpty)
        _SummaryRow('Company', _investorCompany.text.trim()),
      _SummaryRow('Location', '${_city.text.trim()}, ${_country.text.trim()}'),
      _SummaryRow('Deal Type', _dealType),
      _SummaryRow('Format', _meetingType),
      if (_sector.text.trim().isNotEmpty) _SummaryRow('Sector', _sector.text.trim()),
      if (_valuation.text.trim().isNotEmpty)
        _SummaryRow('Valuation', _valuation.text.trim()),
      if (_equity.text.trim().isNotEmpty)
        _SummaryRow('Equity', _equity.text.trim(), accent: AvaColors.gold),
      if (_investmentAsked.text.trim().isNotEmpty)
        _SummaryRow('Investment asked', _investmentAsked.text.trim()),
      if (_revenue.text.trim().isNotEmpty) _SummaryRow('Revenue', _revenue.text.trim()),
      if (_teamSize.text.trim().isNotEmpty) _SummaryRow('Team size', _teamSize.text.trim()),
      if (_meetingAt != null) _SummaryRow('Date', _formatDate(_meetingAt!)),
      if (_investorBio.text.trim().isNotEmpty)
        _SummaryRow('Bio', _investorBio.text.trim()),
      if (_investorPosts.text.trim().isNotEmpty)
        _SummaryRow('Public posts', _investorPosts.text.trim()),
      if (_uploadedFile.isNotEmpty) _SummaryRow('Document', _uploadedFile),
    ].where((r) => r.valueText.isNotEmpty && r.valueText != ', ').toList();

    return Container(
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final r = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(r.label, style: AvaText.caption),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.valueText,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: r.accent ?? AvaColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: AvaColors.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _readyBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AvaColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AvaColors.blue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AvaColors.blue, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'All 5 agents loaded. AVA is preparing your briefing.',
              style: TextStyle(
                fontSize: 11,
                color: AvaColors.blue,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.paddingOf(context).bottom + 16),
      decoration: const BoxDecoration(
        color: AvaColors.bg,
        border: Border(top: BorderSide(color: AvaColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: GestureDetector(
                onTap: _loading ? null : () => setState(() => _step--),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AvaColors.border2),
                  ),
                  child: const Center(
                    child: Text('Back', style: TextStyle(fontSize: 14, color: AvaColors.muted)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _step > 0 ? 2 : 1,
            child: avaGoldBtn(
              _step == 0
                  ? 'Continue →'
                  : _step == 1
                      ? 'Continue →'
                      : 'Start Briefing →',
              _loading ? null : _onNext,
              loading: _loading,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNext() async {
    if (_step == 0) {
      if (!_step1Valid) {
        _showError(
          'Please fill in investor name, country, city and select a date & time.',
        );
        return;
      }
      setState(() => _loading = true);
      try {
        final result = await _api.createDraft(
          investorName: _investorName.text.trim(),
          investorCompany: _investorCompany.text.trim(),
          country: _country.text.trim(),
          city: _city.text.trim(),
          meetingAtIso: _meetingAt!.toUtc().toIso8601String(),
        );
        if (!mounted) return;
        setState(() {
          _draftId = result.id;
          if (result.confirmationText.isNotEmpty) {
            _confirmationText = result.confirmationText;
          }
          _step = 1;
        });
      } catch (e) {
        if (mounted) _showError(e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    if (_step == 1) {
      if (_draftId == null || _draftId!.isEmpty) {
        _showError('Missing draft. Go back to step 1.');
        return;
      }
      setState(() => _loading = true);
      try {
        final result = await _api.updateDraftDealTerms(
          draftId: _draftId!,
          dealTerms: {
            'dealType': _dealType,
            'meetingFormat': _meetingType,
            'sector': _sector.text.trim(),
            'valuation': _valuation.text.trim(),
            'equity': _equity.text.trim(),
            'investmentAsked': _investmentAsked.text.trim(),
            'revenue': _revenue.text.trim(),
            'teamSize': _teamSize.text.trim(),
            'investorBio': _investorBio.text.trim(),
            'publicPosts': _investorPosts.text.trim(),
            'documentFileName': _uploadedFile,
          },
        );
        if (!mounted) return;
        setState(() {
          _confirmationText = _buildAvaConfirmationSummary();
          _step = 2;
        });
      } catch (e) {
        if (mounted) _showError(e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    if (_step == 2) {
      if (_draftId == null || _draftId!.isEmpty) {
        _showError('Missing draft id.');
        return;
      }
      setState(() => _loading = true);
      try {
        final start = await _api.startBriefing(draftId: _draftId!);
        if (!mounted) return;
        final sid = start.meetingId?.trim();
        final sessionId =
            (sid != null && sid.isNotEmpty) ? sid : _draftId!;
        final invName = _investorName.text.trim();
        final loadQ = briefingTabsQuery(
          sessionId,
          invName.isEmpty ? 'Investor' : invName,
          investorCompany: _investorCompany.text.trim(),
          investorCity: _city.text.trim(),
          investorCountry: _country.text.trim(),
          userEquity: _equity.text.trim(),
          userValuation: _valuation.text.trim(),
          meetingFormat: _meetingType,
        );
        context.push('/briefing-loading?$loadQ');
      } catch (e) {
        if (mounted) _showError(e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AvaColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool requiredField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          requiredField ? '${label.toUpperCase()} *' : label.toUpperCase(),
          style: AvaText.label,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: AvaText.body.copyWith(fontSize: 13),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: const TextStyle(color: AvaColors.muted, fontSize: 13),
            filled: true,
            fillColor: AvaColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.border2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.border2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textArea(String label, TextEditingController ctrl, {int lines = 4}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AvaText.label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: lines,
          style: AvaText.body.copyWith(fontSize: 13),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Paste text here…',
            hintStyle: const TextStyle(color: AvaColors.muted, fontSize: 13),
            filled: true,
            fillColor: AvaColors.card,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.border2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.border2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AvaText.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value, // ignore: deprecated_member_use
          onChanged: onChanged,
          dropdownColor: AvaColors.card,
          style: AvaText.body.copyWith(fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AvaColors.muted),
          decoration: InputDecoration(
            filled: true,
            fillColor: AvaColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.border2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.border2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AvaColors.gold, width: 1.5),
            ),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ],
    );
  }

  Widget _datePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MEETING DATE & TIME', style: AvaText.label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AvaColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _meetingAt != null ? AvaColors.gold : AvaColors.border2,
                width: _meetingAt != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: _meetingAt != null ? AvaColors.gold : AvaColors.muted,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _meetingAt == null
                        ? 'Select date and time'
                        : _formatDate(_meetingAt!),
                    style: TextStyle(
                      fontSize: 13,
                      color: _meetingAt == null ? AvaColors.muted : AvaColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AvaColors.gold,
            onPrimary: AvaColors.bg,
            surface: AvaColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AvaColors.gold,
            onPrimary: AvaColors.bg,
            surface: AvaColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _meetingAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Widget _uploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DOCUMENTS (OPTIONAL)', style: AvaText.label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AvaColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _uploadedFile.isNotEmpty ? AvaColors.green : AvaColors.border2,
              ),
            ),
            child: _uploadedFile.isNotEmpty
                ? Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: AvaColors.green, size: 22),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _uploadedFile,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AvaColors.green),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Tap to change',
                        style: TextStyle(fontSize: 10, color: AvaColors.muted),
                      ),
                    ],
                  )
                : const Column(
                    children: [
                      Icon(Icons.upload_file_outlined, color: AvaColors.muted, size: 24),
                      SizedBox(height: 8),
                      Text(
                        'Tap to upload PDF',
                        style: TextStyle(fontSize: 12, color: AvaColors.muted),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Investor profile, pitch deck, emails',
                        style: TextStyle(fontSize: 10, color: AvaColors.faint),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Step 3 — two sentences that mirror the wizard (AVA confirmation).
  String _buildAvaConfirmationSummary() {
    final inv = _investorName.text.trim();
    final co = _investorCompany.text.trim();
    final city = _city.text.trim();
    final country = _country.text.trim();
    final loc = [city, country].where((s) => s.isNotEmpty).join(', ');
    final dateStr =
        _meetingAt != null ? _formatDate(_meetingAt!) : 'your scheduled date';
    final who = co.isNotEmpty ? '$inv ($co)' : (inv.isNotEmpty ? inv : 'your investor');
    final s1 = loc.isNotEmpty
        ? "You're meeting $who in $loc on $dateStr for a $_dealType discussion ($_meetingType)."
        : "You're meeting $who on $dateStr for a $_dealType discussion ($_meetingType).";
    final v = _valuation.text.trim();
    final eq = _equity.text.trim();
    final ask = _investmentAsked.text.trim();
    final parts = <String>[];
    if (v.isNotEmpty) parts.add('valuation $v');
    if (eq.isNotEmpty) parts.add('$eq equity');
    if (ask.isNotEmpty) parts.add('ask $ask');
    final s2 = parts.isEmpty
        ? 'Every briefing tab will use this context — culture, profile, offer, image, and venue — not generic templates.'
        : 'Deal framing: ${parts.join(', ')}. The five agents will align to these numbers and to $country${city.isNotEmpty ? ' / $city' : ''}.';
    return '$s1 $s2';
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final name = result.files.single.name;
      if (name.isNotEmpty) setState(() => _uploadedFile = name);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$m';
  }
}

class _SummaryRow {
  const _SummaryRow(this.label, this.valueText, {this.accent});

  final String label;
  final String valueText;
  final Color? accent;
}
