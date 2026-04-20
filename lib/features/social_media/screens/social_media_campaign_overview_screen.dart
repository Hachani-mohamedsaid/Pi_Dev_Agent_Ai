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
    print(
      '[SocialCampaign][Overview] campaignResult received: ${widget.result.campaignResult}',
    );
  }

  List<String> get _tabs {
    final selected = List<String>.from(widget.result.platforms);
    if (!selected.contains('Analytics')) selected.add('Analytics');
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = _tabs;
    final currentPlatform = tabs[_selectedTab.clamp(0, tabs.length - 1)];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0f2940)
          : const Color(0xFFF3F8FC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0f2940),
                    Color(0xFF1a3a52),
                    Color(0xFF0f2940),
                  ]
                : const [
                    Color(0xFFF8FCFF),
                    Color(0xFFEAF4FB),
                    Color(0xFFF3F8FC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              const SizedBox(height: 8),
              _buildCampaignHeader(isDark),
              const SizedBox(height: 16),
              _buildTabs(tabs, isDark),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildContentCard(currentPlatform, isDark),
                ),
              ),
              _buildBottomActions(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
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
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFF0EA5C6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.cyan500.withOpacity(0.2)
                      : const Color(0xFF0EA5C6).withOpacity(0.22),
                ),
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                color: isDark ? Colors.white : const Color(0xFF12344C),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Campaign Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF12344C),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              LucideIcons.checkCircle,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignHeader(bool isDark) {
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
              child: const Icon(
                LucideIcons.megaphone,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.result.productName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF12344C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.result.platforms.length} platforms • ${widget.result.toneOfVoice} tone',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textCyan200.withOpacity(0.7)
                          : const Color(0xFF3B6D8C),
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

  Widget _buildTabs(List<String> tabs, bool isDark) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                      )
                    : null,
                color: selected
                    ? null
                    : (isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFDCEEF8)),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : (isDark
                            ? AppColors.cyan500.withOpacity(0.15)
                            : const Color(0xFFBFD4E3)),
                ),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : (isDark
                            ? Colors.white.withOpacity(0.55)
                            : const Color(0xFF4E7891)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentCard(String platform, bool isDark) {
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
    final engagement = widget.result.getStatForPlatform(platform, 'engagement');
    final postsRaw = widget.result.getStatForPlatform(platform, 'posts');
    final posts = int.tryParse(postsRaw) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFFFFFFF).withOpacity(0.84),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.cyan500.withOpacity(0.15)
                  : const Color(0xFFC7DDE9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF12263A),
                ),
              ),
              const SizedBox(height: 16),
              body.isNotEmpty
                  ? Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textCyan200.withOpacity(0.8)
                            : const Color(0xFF3F6983),
                        height: 1.6,
                      ),
                    )
                  : Text(
                      'No dedicated $platform section found in the generated report.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : const Color(0xFF6D8BA0),
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
              child: _buildStatCard('Reach', reach, LucideIcons.users, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Engagement',
                engagement,
                LucideIcons.trendingUp,
                isDark,
              ),
            ),
            if (posts > 0) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Posts',
                  '$posts',
                  LucideIcons.fileText,
                  isDark,
                ),
              ),
            ],
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFFFFFFF).withOpacity(0.84),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.cyan500.withOpacity(0.12)
              : const Color(0xFFC7DDE9),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.cyan400, size: 18),
          const SizedBox(height: 8),
          Text(
            value.isNotEmpty ? value : '—',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF12263A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textCyan200.withOpacity(0.6)
                  : const Color(0xFF5B7B92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            (isDark ? const Color(0xFF0f2940) : const Color(0xFFF3F8FC))
                .withOpacity(0.95),
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
                  builder: (_) => const SocialMediaBriefScreen(),
                ),
                (route) => route.isFirst,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFFFFFFF).withOpacity(0.84),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.cyan500.withOpacity(0.2)
                      : const Color(0xFFC7DDE9),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.refreshCw,
                    color: AppColors.cyan400,
                    size: 18,
                  ),
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
