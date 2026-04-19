import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/meeting_model.dart';
import '../../data/services/meeting_service.dart';
import '../../data/services/google_connect_service.dart';
import '../widgets/google_connect_gate_sheet.dart';
import '../widgets/navigation_bar.dart';

Color _primaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textWhite
      : const Color(0xFF12263A);
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textCyan200
      : const Color(0xFF5B7B92);
}

/// Agenda screen: review schedule / agenda. Placeholder for now.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const _tokenKey = 'auth_access_token';
  static const _userIdKey = 'user_id';

  final _googleService = GoogleConnectService();
  final _meetingService = MeetingService();

  bool _isLoading = true;
  bool _connectionChecked = false;
  String? _errorMessage;
  String? _userId;
  List<Meeting> _meetings = [];
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _checkConnectionThenLoad();
  }

  @override
  void dispose() {
    _meetingService.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionThenLoad() async {
    if (_connectionChecked) return;
    _connectionChecked = true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ?? '';
    if (token.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Check Google connection (covers Gmail + Calendar + Sheets — same token)
    final googleStatus = await _googleService.getStatus(token);
    if (!mounted) return;

    if (!googleStatus.connected) {
      await GoogleConnectGateSheet.show(
        context,
        'Connect Google to use the Agenda — AVA monitors your Gmail for meeting requests and manages your Calendar automatically.',
      );
      if (!mounted) return;
      // Re-check after returning from connect flow
      final refreshed = await _googleService.getStatus(token);
      if (!mounted) return;
      if (!refreshed.connected) {
        setState(() => _isLoading = false);
        return;
      }
    }

    await _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId ??= prefs.getString(_userIdKey);
      if (_userId == null || _userId!.isEmpty) {
        throw Exception('User ID not found. Please log out and back in.');
      }
      final meetings = await _meetingService.fetchMeetings(_userId!);
      if (!mounted) return;
      setState(() {
        _meetings = meetings;
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

  Future<void> _submitDecision(Meeting meeting, String decision) async {
    if (_userId == null) return;
    setState(() => _processingIds.add(meeting.meetingId));
    try {
      final result = await _meetingService.sendDecision(
        _userId!,
        meeting.meetingId,
        decision,
      );
      if (!mounted) return;
      final meetLink = result['meetLink'] as String? ?? '';
      if (decision == 'accept' && meetLink.isNotEmpty) {
        _showMeetLinkDialog(meetLink);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(decision == 'accept'
              ? '✅ Meeting accepted'
              : '❌ Meeting rejected'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      await _loadMeetings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _processingIds.remove(meeting.meetingId));
    }
  }

  void _showMeetLinkDialog(String meetLink) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Meeting Confirmed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.video, color: Color(0xFF10B981), size: 44),
            const SizedBox(height: 12),
            const Text('Google Meet link generated:',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            SelectableText(meetLink,
                style: const TextStyle(
                    color: Color(0xFF06B6D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close',
                style: TextStyle(color: AppColors.cyan400.withOpacity(0.8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse(meetLink);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open Meet',
                style: TextStyle(
                    color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m';
  }

  Color _importanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'high': return const Color(0xFFEF4444);
      case 'low': return const Color(0xFF22C55E);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 48.0,
    );
    final pageGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FCFF), Color(0xFFEAF4FB), Color(0xFFF3F8FC)],
          );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0f2940)
          : const Color(0xFFF3F8FC),
      body: Container(
        decoration: BoxDecoration(gradient: pageGradient),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.chevronLeft,
                        color: AppColors.cyan400,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: TextStyle(
                          color: AppColors.cyan400,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveValue(
                    context,
                    mobile: 20.0,
                    tablet: 24.0,
                    desktop: 28.0,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      color: AppColors.cyan400,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Review Agenda',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 24.0,
                          tablet: 28.0,
                          desktop: 32.0,
                        ),
                        fontWeight: FontWeight.bold,
                        color: _primaryText(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your schedule and upcoming items',
                  style: TextStyle(
                    color: _secondaryText(context).withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveValue(
                    context,
                    mobile: 28.0,
                    tablet: 32.0,
                    desktop: 40.0,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : const Color(0xFFF9FCFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cyan500.withOpacity(0.25)
                          : const Color(0xFFC7DDE9),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.calendarDays,
                        color: AppColors.cyan400.withOpacity(0.7),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Agenda content will go here',
                        style: TextStyle(
                          color: _primaryText(context),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect your calendar or add meetings to see your agenda.',
                        style: TextStyle(
                          color: _secondaryText(context).withOpacity(0.8),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: NavigationBarWidget(currentPath: '/agenda'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, Meeting meeting, int index) {
    final isProcessing = _processingIds.contains(meeting.meetingId);
    final importanceColor = _importanceColor(meeting.importance);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.5),
            const Color(0xFF16384d).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.cyan500.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(meeting.subject,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: importanceColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: importanceColor.withOpacity(0.4)),
                ),
                child: Text(meeting.importance.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: importanceColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(LucideIcons.clock,
                  size: 13, color: AppColors.cyan400.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(_formatDateTime(meeting.startTime),
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textCyan200.withOpacity(0.65))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _submitDecision(meeting, 'accept'),
                    icon: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.check, size: 16),
                    label:
                        Text(isProcessing ? 'Processing...' : 'Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _submitDecision(meeting, 'reject'),
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(
                          color: Color(0xFFEF4444), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: 150 + index * 80),
            duration: 400.ms)
        .slideY(
            begin: 0.15,
            end: 0,
            delay: Duration(milliseconds: 150 + index * 80),
            duration: 400.ms);
  }
}
