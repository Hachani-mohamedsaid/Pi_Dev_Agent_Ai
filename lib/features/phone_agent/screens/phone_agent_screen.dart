import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../data/services/google_connect_service.dart';
import '../../../presentation/widgets/google_connect_gate_sheet.dart';
import '../services/phone_agent_service.dart';

class PhoneAgentScreen extends StatefulWidget {
  const PhoneAgentScreen({super.key});

  @override
  State<PhoneAgentScreen> createState() => _PhoneAgentScreenState();
}

class _PhoneAgentScreenState extends State<PhoneAgentScreen> {
  final _service = PhoneAgentService();
  final _googleService = GoogleConnectService();
  bool _connectionChecked = false;
  String _filter = 'all';
  bool _isLoading = true;
  String? _errorMessage;
  List<PhoneCallData> _calls = [];

  @override
  void initState() {
    super.initState();
    _checkConnectionThenLoad();
  }

  Future<void> _checkConnectionThenLoad() async {
    if (_connectionChecked) return;
    _connectionChecked = true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_access_token') ?? '';
    if (token.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final googleStatus = await _googleService.getStatus(token);
    if (!mounted) return;

    if (!googleStatus.connected) {
      await GoogleConnectGateSheet.show(
        context,
        'Connect Google to use the Phone Agent — call transcripts and AI summaries are stored in your AVA Tracker.',
      );
      if (!mounted) return;
      // Re-check after user returns from connect flow
      final refreshed = await _googleService.getStatus(token);
      if (!mounted) return;
      if (!refreshed.connected) {
        setState(() => _isLoading = false);
        return;
      }
    }

    await _loadCalls();
  }

  Future<void> _loadCalls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final calls = await _service.fetchCalls();
      if (!mounted) return;
      setState(() {
        _calls = calls;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PhoneCallData> get _filteredCalls {
    switch (_filter) {
      case 'completed':
        return _calls
            .where((c) => c.callStatus.toLowerCase() == 'completed')
            .toList();
      case 'important':
        return _calls.where((c) => c.priorityFromLeadQuality == 'high').toList();
      case 'booked':
        return _calls
            .where((c) => c.callStatus.toLowerCase().contains('book'))
            .toList();
      default:
        return _calls;
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(context,
        mobile: 18.0, tablet: 22.0, desktop: 26.0);

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
          child: Column(
            children: [
              _buildHeader(context, padding),
              SizedBox(height: padding),
              if (!_isLoading && _errorMessage == null)
                _buildStatsGrid(context, padding),
              if (!_isLoading && _errorMessage == null) const SizedBox(height: 16),
              if (!_isLoading && _errorMessage == null) _buildFilterTabs(context),
              if (!_isLoading && _errorMessage == null) const SizedBox(height: 12),
              Expanded(child: _buildBody(context, padding)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double padding) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle,
                size: 48, color: Colors.red.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text('Failed to load calls',
                style: TextStyle(color: AppColors.textCyan200, fontSize: 15)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadCalls,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_filteredCalls.isEmpty) {
      return _buildEmpty(context);
    }
    return RefreshIndicator(
      onRefresh: _loadCalls,
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
        itemCount: _filteredCalls.length,
        itemBuilder: (context, index) {
          final call = _filteredCalls[index];
          return _CallCard(
            call: call,
            onTap: () => context.push('/phone-agent-call', extra: call),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 50 * index))
              .slideY(
                  begin: 0.08,
                  end: 0,
                  delay: Duration(milliseconds: 50 * index));
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cyan400),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cyan500.withOpacity(0.1),
              side: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.phone, color: AppColors.cyan400, size: 24),
                    const SizedBox(width: 8),
                    Text('Phone Agent',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(context,
                              mobile: 20.0, tablet: 22.0, desktop: 24.0),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text('AI-powered call management',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textCyan200.withOpacity(0.7))),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, double padding) {
    final total = _calls.length;
    final completed =
        _calls.where((c) => c.callStatus.toLowerCase() == 'completed').length;
    final booked =
        _calls.where((c) => c.callStatus.toLowerCase().contains('book')).length;
    final important =
        _calls.where((c) => c.priorityFromLeadQuality == 'high').length;

    final items = [
      _StatItem('Total Calls', total, LucideIcons.phone, const Color(0xFF06B6D4)),
      _StatItem('Completed', completed, LucideIcons.checkCircle,
          const Color(0xFF22C55E)),
      _StatItem(
          'Booked', booked, LucideIcons.calendar, const Color(0xFF3B82F6)),
      _StatItem('High Priority', important, LucideIcons.alertCircle,
          const Color(0xFFEF4444)),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        physics: const NeverScrollableScrollPhysics(),
        children: items.asMap().entries.map((e) {
          final item = e.value;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1e4a66).withOpacity(0.4),
                  const Color(0xFF16384d).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.icon, color: item.color, size: 18),
                    Text('${item.value}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: item.color)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textCyan200.withOpacity(0.7))),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 50 * e.key))
              .slideY(
                  begin: 0.1,
                  end: 0,
                  delay: Duration(milliseconds: 50 * e.key));
        }).toList(),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final tabs = [
      ('all', 'All Calls'),
      ('completed', 'Completed'),
      ('booked', 'Booked'),
      ('important', 'Important'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: tabs.map((t) {
          final selected = _filter == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = t.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.cyan500.withOpacity(0.3)
                      : AppColors.cyan500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.cyan400.withOpacity(0.4)
                        : AppColors.cyan500.withOpacity(0.2),
                  ),
                ),
                child: Text(t.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppColors.textCyan200
                          : AppColors.textCyan200.withOpacity(0.7),
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.phone,
              size: 64, color: AppColors.cyan400.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No calls yet',
              style: TextStyle(
                  color: AppColors.textCyan200.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Calls from your Vapi phone agent will appear here.',
              style: TextStyle(
                  color: AppColors.textCyan200.withOpacity(0.5), fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

class _CallCard extends StatelessWidget {
  final PhoneCallData call;
  final VoidCallback onTap;

  const _CallCard({required this.call, required this.onTap});

  Color get _priorityColor {
    switch (call.priorityFromLeadQuality) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'low':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFFACC15);
    }
  }

  Color get _statusColor {
    final s = call.callStatus.toLowerCase();
    if (s.contains('book')) return const Color(0xFF3B82F6);
    if (s == 'completed') return const Color(0xFF22C55E);
    return AppColors.cyan500;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1e4a66).withOpacity(0.4),
                const Color(0xFF16384d).withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan500.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(call.callerNumber,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            if (call.priorityFromLeadQuality == 'high') ...[
                              const SizedBox(width: 6),
                              const Icon(LucideIcons.star,
                                  size: 16, color: Color(0xFFEF4444)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${call.formattedDate} • ${call.formattedTime}',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    AppColors.textCyan200.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (call.duration.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.clock,
                                size: 12,
                                color:
                                    AppColors.textCyan200.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(call.duration,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textCyan200
                                        .withOpacity(0.6))),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              if (call.summary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(call.summary,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textCyan200.withOpacity(0.8)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(_priorityColor, call.priorityFromLeadQuality,
                      hasDot: true),
                  _chip(_statusColor, call.callStatus, hasDot: false),
                  if (call.sentiment.isNotEmpty)
                    _chip(const Color(0xFF8B5CF6), call.sentiment,
                        hasDot: false),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right,
                    color: AppColors.cyan400.withOpacity(0.5), size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(Color bg, String label, {required bool hasDot}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDot) ...[
            Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: bg)),
        ],
      ),
    );
  }
}

