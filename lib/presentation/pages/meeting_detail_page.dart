import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';
import '../../data/models/meeting_model.dart';
import '../../data/services/meeting_service.dart';

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

class MeetingDetailPage extends StatefulWidget {
  final String meetingId;
  final MeetingService? meetingService;

  const MeetingDetailPage({
    super.key,
    required this.meetingId,
    this.meetingService,
  });

  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  late final MeetingService _service;
  Meeting? _meeting;
  String? _error;
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.meetingService ?? MeetingService();
    _fetchMeeting();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchMeeting() async {
    try {
      final meetings = await _service.fetchMeetings();
      if (!mounted) return;
      Meeting? found;
      for (final m in meetings) {
        if (m.meetingId == widget.meetingId) {
          found = m;
          break;
        }
      }
      setState(() {
        _meeting = found;
        _error = found == null ? 'Réunion introuvable' : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _sendDecision(String decision) async {
    final meeting = _meeting;
    if (meeting == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    debugPrint(
      'POST meeting-decision: meetingId=${meeting.meetingId}, decision=$decision',
    );

    try {
      await _service.sendDecision(meeting.meetingId, decision);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0f2940)
            : const Color(0xFFF3F8FC),
        body: Container(
          decoration: BoxDecoration(gradient: pageGradient),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
            ),
          ),
        ),
      );
    }

    final meeting = _meeting;
    if (meeting == null || _error != null) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0f2940)
            : const Color(0xFFF3F8FC),
        body: Container(
          decoration: BoxDecoration(gradient: pageGradient),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error ?? 'Réunion introuvable',
                    style: TextStyle(color: _primaryText(context)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat.yMMMMd();
    final duration = meeting.endTime.difference(meeting.startTime).inMinutes;
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
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
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildMeetingCard(
                      context,
                      meeting,
                      timeFormat,
                      dateFormat,
                      duration,
                    ),
                    const SizedBox(height: 20),
                    _buildImportanceCard(context, meeting),
                    const SizedBox(height: 20),
                    _buildActionButtons(context),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: const NavigationBarWidget(currentPath: '/meeting'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.arrowLeft, color: AppColors.cyan400, size: 20),
              const SizedBox(width: 8),
              Text(
                'Retour à l\'accueil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cyan400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Détail de la réunion',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 24.0,
              tablet: 26.0,
              desktop: 28.0,
            ),
            fontWeight: FontWeight.bold,
            color: _primaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingCard(
    BuildContext context,
    Meeting meeting,
    DateFormat timeFormat,
    DateFormat dateFormat,
    int durationMinutes,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final durationStr = durationMinutes >= 60
        ? '${durationMinutes ~/ 60}h ${durationMinutes % 60}min'
        : '$durationMinutes min';

    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? const Color(0xFF1e4a66).withOpacity(0.5)
                : const Color(0xFFF9FCFF),
            isDark
                ? const Color(0xFF16384d).withOpacity(0.5)
                : const Color(0xFFEAF4FB),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.cyan500.withOpacity(0.2)
              : const Color(0xFFC7DDE9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meeting.subject,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 18.0,
                tablet: 19.0,
                desktop: 20.0,
              ),
              fontWeight: FontWeight.w600,
              color: _primaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cyan500, height: 1),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            LucideIcons.calendar,
            dateFormat.format(meeting.startTime),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            LucideIcons.clock,
            '${timeFormat.format(meeting.startTime)} - ${timeFormat.format(meeting.endTime)}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(context, LucideIcons.timer, durationStr),
          if (meeting.timezone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(context, LucideIcons.globe, meeting.timezone),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cyan500.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.cyan400, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? _primaryText(context).withOpacity(0.9)
                  : _secondaryText(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportanceCard(BuildContext context, Meeting meeting) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final importanceColor = _importanceColor(meeting.importance);
    final importanceLabel = meeting.importance.isEmpty
        ? 'Normal'
        : meeting.importance[0].toUpperCase() + meeting.importance.substring(1);

    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? const Color(0xFF1e4a66).withOpacity(0.5)
                : const Color(0xFFF9FCFF),
            isDark
                ? const Color(0xFF16384d).withOpacity(0.5)
                : const Color(0xFFEAF4FB),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? importanceColor.withOpacity(0.3)
              : const Color(0xFFC7DDE9),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: importanceColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: importanceColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.alertCircle, color: importanceColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  importanceLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: importanceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _importanceColor(String importance) {
    final value = importance.toLowerCase();
    if (value.contains('high') || value.contains('important')) {
      return Colors.redAccent;
    }
    if (value.contains('low')) {
      return Colors.greenAccent;
    }
    return AppColors.cyan400;
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () => _sendDecision(MeetingDecisionType.accept),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22c55e),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSubmitting ? 'Envoi…' : 'Accepter',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () => _sendDecision(MeetingDecisionType.suggest),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cyan400,
              side: BorderSide(color: AppColors.cyan500.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.calendarClock,
                  size: 20,
                  color: AppColors.cyan400,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Proposer un autre créneau',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isSubmitting
                ? null
                : () => _sendDecision(MeetingDecisionType.reject),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                const SizedBox(width: 8),
                const Text(
                  'Refuser',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
