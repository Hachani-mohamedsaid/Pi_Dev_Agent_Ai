import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../models/campaign_result_model.dart';
import 'social_media_brief_screen.dart';
import 'social_media_report_screen.dart';

class SocialMediaCampaignOverviewScreen extends StatefulWidget {
  final CampaignResultModel result;

  const SocialMediaCampaignOverviewScreen({super.key, required this.result});

  @override
  State<SocialMediaCampaignOverviewScreen> createState() =>
      _SocialMediaCampaignOverviewScreenState();
}

class _SocialMediaCampaignOverviewScreenState
    extends State<SocialMediaCampaignOverviewScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    print('[SocialCampaign][Overview] campaignResult received: ${widget.result.campaignResult}');
  }

  List<String> get _tabs {
    final selected = List<String>.from(widget.result.platforms);
    if (!selected.contains('Analytics')) selected.add('Analytics');
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final currentPlatform = tabs[_selectedTab.clamp(0, tabs.length - 1)];

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
              _buildAppBar(context),
              const SizedBox(height: 8),
              _buildCampaignHeader(),
              const SizedBox(height: 16),
              _buildTabs(tabs),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildContentCard(currentPlatform),
                ),
              ),
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
              ),
              child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Campaign Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Icon(LucideIcons.checkCircle,
                color: Color(0xFF10B981), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC4899).withOpacity(0.15),
              const Color(0xFFA855F7).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.megaphone, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.result.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.result.platforms.length} platforms • ${widget.result.toneOfVoice} tone',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textCyan200.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ready',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildTabs(List<String> tabs) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                      )
                    : null,
                color: selected ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : AppColors.cyan500.withOpacity(0.15),
                ),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.55),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentCard(String platform) {
    final headline = widget.result.getHeadlineForPlatform(platform);
    final sectionBody = widget.result.getPlatformSection(platform);
    final fullBody = widget.result.formattedCampaignResultText;
    final hasSections = widget.result.hasPlatformSections;
    final showFullBodyOnThisTab = _selectedTab == 0;
    final body = hasSections
        ? (sectionBody.isNotEmpty
            ? sectionBody
            : (showFullBodyOnThisTab ? fullBody : ''))
        : (showFullBodyOnThisTab ? fullBody : '');
    final reach = widget.result.getStatForPlatform(platform, 'reach');
    final engagement =
        widget.result.getStatForPlatform(platform, 'engagement');
    final postsRaw = widget.result.getStatForPlatform(platform, 'posts');
    final posts = int.tryParse(postsRaw) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: AppColors.cyan500.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              body.isNotEmpty
                  ? Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textCyan200.withOpacity(0.8),
                        height: 1.6,
                      ),
                    )
                  : Text(
                      'No dedicated $platform section found in the generated report.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Reach', reach, LucideIcons.users),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                  'Engagement', engagement, LucideIcons.trendingUp),
            ),
            if (posts > 0) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Posts', '$posts', LucideIcons.fileText),
              ),
            ],
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.cyan400, size: 18),
          const SizedBox(height: 8),
          Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textCyan200.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0f2940).withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SocialMediaReportScreen(result: widget.result),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileText, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'View Full Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const SocialMediaBriefScreen()),
                (route) => route.isFirst,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.cyan500.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.refreshCw,
                      color: AppColors.cyan400, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Regenerate',
                    style: TextStyle(
                      color: AppColors.cyan400,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
