import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/meeting_hub_mock_data.dart';
import '../models/meeting_model.dart';

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
                      SizedBox(height: 80),
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
            onTap: () => context.push('/active-meeting'),
            isPrimary: true,
          ),
          SizedBox(height: 14),
          _buildActionButton(
            context,
            label: 'Join Meeting',
            icon: LucideIcons.users,
            onTap: () => context.push('/active-meeting'),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
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
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 14, color: AppColors.textCyan200.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(m.date, style: TextStyle(color: AppColors.textCyan200.withOpacity(0.7), fontSize: 13)),
                      const SizedBox(width: 12),
                      Icon(LucideIcons.video, size: 14, color: AppColors.textCyan200.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(m.duration, style: TextStyle(color: AppColors.textCyan200.withOpacity(0.7), fontSize: 13)),
                      const SizedBox(width: 12),
                      Icon(LucideIcons.users, size: 14, color: AppColors.textCyan200.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text('${m.participants}', style: TextStyle(color: AppColors.textCyan200.withOpacity(0.7), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyan500.withOpacity(0.25), AppColors.blue500.withOpacity(0.25)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.fileText, size: 16, color: AppColors.cyan400),
                  const SizedBox(width: 6),
                  Text(
                    'View Transcript',
                    style: TextStyle(color: AppColors.cyan400, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms + (index * 80).ms).slideX(begin: -0.03, end: 0, curve: Curves.easeOut);
  }
}
