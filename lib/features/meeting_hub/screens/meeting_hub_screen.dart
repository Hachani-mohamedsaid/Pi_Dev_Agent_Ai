import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/meeting_service.dart';
import '../data/meeting_hub_mock_data.dart';
import '../models/meeting_model.dart';

const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
String _randomRoomId() => List.generate(6, (_) => _chars[Random().nextInt(_chars.length)]).join();

/// Meeting Hub landing: Start/Join meeting + recent meetings list.
/// Same structure as phone_agent feature (screens + data + models).
class MeetingHubScreen extends StatelessWidget {
  const MeetingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 32.0, desktop: 48.0);

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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 24, padding, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                      _buildHeader(context),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                      _buildCenterCard(context, isMobile),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
                      _buildRecentSection(context, isMobile, padding),
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

  static Future<void> _goStartMeeting(BuildContext context) async {
    // If a meeting is already active and not ended, reopen it instead of creating a new room.
    if (MeetingService.instance.hasActiveMeeting &&
        (MeetingService.instance.currentRoomId?.isNotEmpty ?? false)) {
      context.push('/active-meeting', extra: {
        'roomID': MeetingService.instance.currentRoomId!,
        'userID': MeetingService.instance.currentUserId ?? 'user_resume',
        'userName': MeetingService.instance.currentUserName ?? 'User',
        'isStart': true,
      });
      return;
    }

    final granted = await _requestCameraAndMicOnHub();
    if (!context.mounted) return;
    if (granted) {
      context.push('/active-meeting', extra: {
        'roomID': _randomRoomId(),
        'userID': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'userName': 'User',
        'isStart': true,
      });
    } else {
      _showPermissionDeniedDialog(context, () {
        Navigator.of(context).pop();
        _goStartMeeting(context);
      });
    }
  }

  /// Request camera then microphone on Meeting Hub (popups appear here). Returns true if both granted.
  static Future<bool> _requestCameraAndMicOnHub() async {
    var cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) return false;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    var micStatus = await Permission.microphone.request();
    return micStatus.isGranted;
  }

  static void _showPermissionDeniedDialog(BuildContext context, VoidCallback onTryAgain) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.videoOff, color: AppColors.cyan400, size: 28),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Camera & microphone required',
                style: TextStyle(color: Colors.white, fontSize: 17),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Tap "Try again" to see the system permission prompts, or open Settings.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            icon: const Icon(LucideIcons.settings, size: 20, color: AppColors.cyan400),
            label: const Text('Open Settings', style: TextStyle(color: AppColors.cyan400)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              onTryAgain();
            },
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.cyan500),
          ),
        ],
      ),
    );
  }

  static void _showJoinSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1a3a52),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Join Meeting', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter room ID',
                hintStyle: TextStyle(color: AppColors.textCyan200.withOpacity(0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.cyan500.withOpacity(0.4))),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final roomID = controller.text.trim();
                if (roomID.isEmpty) return;
                final granted = await _requestCameraAndMicOnHub();
                if (!ctx.mounted) return;
                if (granted) {
                  Navigator.of(ctx).pop();
                  context.push('/active-meeting', extra: {
                    'roomID': roomID,
                    'userID': 'user_${DateTime.now().millisecondsSinceEpoch}',
                    'userName': 'User',
                    'isStart': false,
                  });
                } else {
                  _showPermissionDeniedDialog(context, () => Navigator.of(ctx).pop());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/home'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.chevronLeft, color: AppColors.cyan400, size: 22),
          const SizedBox(width: 8),
          Text(
            'Back to Home',
            style: TextStyle(color: AppColors.cyan400, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Hub',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 26.0, tablet: 30.0, desktop: 34.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 8),
        Text(
          'Start or join a meeting with AI assistance',
          style: TextStyle(color: AppColors.textCyan200.withOpacity(0.85), fontSize: 14),
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildCenterCard(BuildContext context, bool isMobile) {
    final r = Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0);
    return Container(
      padding: EdgeInsets.all(r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.85),
            AppColors.primaryDarker.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: Responsive.getResponsiveValue(context, mobile: 80.0, tablet: 88.0, desktop: 96.0),
            height: Responsive.getResponsiveValue(context, mobile: 80.0, tablet: 88.0, desktop: 96.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.cyan400, AppColors.blue500],
              ),
              borderRadius: BorderRadius.circular(r),
              boxShadow: [
                BoxShadow(color: AppColors.cyan500.withOpacity(0.4), blurRadius: 20, spreadRadius: 0),
              ],
            ),
            child: const Icon(LucideIcons.video, color: Colors.white, size: 40),
          ),
          SizedBox(height: r),
          _buildActionButton(
            context,
            label: 'Start Meeting',
            icon: LucideIcons.video,
            onTap: () => _goStartMeeting(context),
            isPrimary: true,
          ),
          SizedBox(height: 14),
          _buildActionButton(
            context,
            label: 'Join Meeting',
            icon: LucideIcons.users,
            onTap: () => _showJoinSheet(context),
            isPrimary: false,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOut);
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.cyan500, AppColors.blue500],
                  )
                : null,
            color: isPrimary ? null : AppColors.primaryLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: isPrimary ? null : Border.all(color: AppColors.cyan500.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context, bool isMobile, double padding) {
    final recent = mockRecentMeetings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Meetings',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        ...recent.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildRecentMeetingCard(context, m, i),
          );
        }),
      ],
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildRecentMeetingCard(BuildContext context, RecentMeetingModel m, int index) {
    const metaStyle = TextStyle(color: AppColors.textCyan200, fontSize: 13);
    final metaColor = AppColors.textCyan200.withOpacity(0.7);

    return GestureDetector(
      onTap: () => context.push('/meeting-transcript/${m.id}'),
      child: Container(
        padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withOpacity(0.45),
              AppColors.primaryDarker.withOpacity(0.45),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: metaColor),
                    const SizedBox(width: 4),
                    Text(m.date, style: metaStyle.copyWith(color: metaColor)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.video, size: 14, color: metaColor),
                    const SizedBox(width: 4),
                    Text(m.duration, style: metaStyle.copyWith(color: metaColor)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.users, size: 14, color: metaColor),
                    const SizedBox(width: 4),
                    Text('${m.participants}', style: metaStyle.copyWith(color: metaColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cyan500.withOpacity(0.25), AppColors.blue500.withOpacity(0.25)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.fileText, size: 16, color: AppColors.cyan400),
                    const SizedBox(width: 8),
                    Text(
                      'View Transcript',
                      style: TextStyle(color: AppColors.cyan400, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms + (index * 80).ms).slideX(begin: -0.03, end: 0, curve: Curves.easeOut);
  }
}
