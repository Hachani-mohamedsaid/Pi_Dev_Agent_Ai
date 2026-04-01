import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shell.dart';
import '../../core/theme/ava_theme.dart';
import '../../models/challenge_model.dart';
import '../../data/services/challenges_service.dart';
import '../../injection_container.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with TickerProviderStateMixin {
  late List<Challenge> challenges;
  late List<UserProfile> leaderboard;
  String? _currentUserId;
  int userTotalPoints = 1250;
  int userRank = 9;
  late TabController _tabController;
  bool _isLoadingChallenges = true;
  bool _isLoadingLeaderboard = true;
  bool _isSyncingChallengeState = true;
  late ChallengesService _challengesService;

  @override
  void initState() {
    super.initState();
    challenges = <Challenge>[];
    leaderboard = <UserProfile>[];
    _tabController = TabController(length: 2, vsync: this);

    // Initialize service
    final authLocalDataSource = InjectionContainer.instance.authLocalDataSource;
    _challengesService = ChallengesService(
      authLocalDataSource: authLocalDataSource,
    );

    _initializeChallengesData();
  }

  Future<void> _initializeChallengesData() async {
    await _loadChallengesCatalog();
    await _loadChallengeState();
    await _loadLeaderboard();
  }

  int get _completedCount =>
      challenges.where((challenge) => challenge.isCompleted).length;

  bool _isChallengeUnlocked(int index) {
    // Sequential progression: only next challenge is unlocked.
    return index <= _completedCount;
  }

  Future<void> _loadChallengesCatalog() async {
    try {
      final loadedChallenges = await _challengesService
          .fetchChallengesCatalog();
      if (!mounted) return;
      setState(() {
        challenges = loadedChallenges;
        _isLoadingChallenges = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        challenges = getMockChallenges();
        _isLoadingChallenges = false;
      });
    }
  }

  Future<void> _loadChallengeState() async {
    try {
      final profile = await _challengesService.getCurrentUserProfile();
      if (!mounted) return;

      if (profile != null) {
        final completedIds = profile.completedChallengeIds.toSet();
        final updatedChallenges = challenges
            .map(
              (challenge) => challenge.copyWith(
                isCompleted: completedIds.contains(challenge.id),
                completedAt: completedIds.contains(challenge.id)
                    ? (challenge.completedAt ?? DateTime.now())
                    : null,
              ),
            )
            .toList();

        setState(() {
          _currentUserId = profile.id;
          userTotalPoints = profile.totalPoints;
          challenges = updatedChallenges;
          _isSyncingChallengeState = false;
        });
      } else {
        setState(() {
          _isSyncingChallengeState = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSyncingChallengeState = false;
      });
    }
  }

  /// Load leaderboard from API or fallback to mock data
  Future<void> _loadLeaderboard() async {
    try {
      final loadedLeaderboard = await _challengesService.fetchLeaderboard();
      if (mounted) {
        final currentIndex = loadedLeaderboard.indexWhere(
          (user) => user.id == _currentUserId,
        );
        setState(() {
          leaderboard = loadedLeaderboard;
          if (currentIndex != -1) {
            userRank = currentIndex + 1;
          }
          _isLoadingLeaderboard = false;
        });
      }
    } catch (e) {
      // Fallback to mock data
      if (mounted) {
        setState(() {
          leaderboard = getMockLeaderboard();
          _isLoadingLeaderboard = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildPointsCard(),
            _buildProgressHeader(),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.cyan400,
              unselectedLabelColor: AvaColors.muted,
              indicatorColor: AppColors.cyan400,
              tabs: const [
                Tab(text: 'Challenges'),
                Tab(text: 'Leaderboard'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildChallengesTab(), _buildLeaderboardTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AvaColors.muted,
          size: 18,
        ),
      ),
      title: const Text(
        'Challenges & Rewards',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            setState(() {
              _isLoadingChallenges = true;
              _isSyncingChallengeState = true;
              _isLoadingLeaderboard = true;
            });
            await _loadChallengesCatalog();
            await _loadChallengeState();
            await _loadLeaderboard();
          },
          icon: const Icon(LucideIcons.refreshCw, color: AvaColors.muted),
          tooltip: 'Refresh from system',
        ),
      ],
      centerTitle: true,
    );
  }

  Widget _buildPointsCard() {
    return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cyan400.withValues(alpha: 0.1),
                AppColors.cyan500.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan500.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.cyan400, AppColors.cyan500],
                  ),
                ),
                child: const Icon(
                  LucideIcons.zap,
                  color: AppColors.primaryDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Points',
                      style: TextStyle(
                        fontSize: 12,
                        color: AvaColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$userTotalPoints',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusAccepted.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.trophy,
                          color: AppColors.statusAccepted,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#$userRank',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusAccepted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rank',
                    style: TextStyle(fontSize: 10, color: AvaColors.muted),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms);
  }

  Widget _buildProgressHeader() {
    final completed = _completedCount;
    final total = challenges.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lock, size: 14, color: AppColors.cyan400),
              const SizedBox(width: 8),
              Text(
                _isSyncingChallengeState
                    ? 'Syncing challenge status from system...'
                    : 'Progression: $completed / $total completed',
                style: const TextStyle(
                  fontSize: 12,
                  color: AvaColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.cyan500.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.cyan400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    if (_isLoadingChallenges) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading challenges...',
              style: TextStyle(color: AvaColors.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final isUnlocked = _isChallengeUnlocked(index);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildChallengeCard(challenge, index, isUnlocked)
              .animate()
              .fadeIn(duration: 500.ms, delay: (50 * index).ms)
              .slideX(begin: 0.2, end: 0, duration: 500.ms),
        );
      },
    );
  }

  Widget _buildChallengeCard(Challenge challenge, int index, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        if (!isUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete previous challenge to unlock this one.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _showChallengeDetail(challenge);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: !isUnlocked
              ? LinearGradient(
                  colors: [
                    AppColors.cyan500.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                )
              : challenge.isCompleted
              ? LinearGradient(
                  colors: [
                    AppColors.statusAccepted.withValues(alpha: 0.1),
                    AppColors.statusAccepted.withValues(alpha: 0.05),
                  ],
                )
              : LinearGradient(
                  colors: [
                    challenge.color.withValues(alpha: 0.08),
                    challenge.color.withValues(alpha: 0.03),
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: !isUnlocked
                ? AppColors.cyan500.withValues(alpha: 0.2)
                : challenge.isCompleted
                ? AppColors.statusAccepted.withValues(alpha: 0.3)
                : challenge.color.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    isUnlocked ? challenge.color : AvaColors.faint,
                    (isUnlocked ? challenge.color : AvaColors.faint).withValues(
                      alpha: 0.7,
                    ),
                  ],
                ),
              ),
              child: Icon(
                isUnlocked ? _getIconData(challenge.icon) : LucideIcons.lock,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isUnlocked
                              ? challenge.title
                              : 'Locked Challenge #${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !isUnlocked
                                ? AvaColors.muted
                                : challenge.isCompleted
                                ? AppColors.statusAccepted
                                : AppColors.textWhite,
                            decoration: challenge.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (challenge.requiresVoice && isUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyan400.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.mic,
                                  size: 10,
                                  color: AppColors.cyan400,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Voice',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.cyan400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (challenge.requiresPayment && isUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD946EF,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.creditCard,
                                  size: 10,
                                  color: Color(0xFFD946EF),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Premium',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFFD946EF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUnlocked
                        ? challenge.description
                        : 'Finish the previous challenge to unlock this mission',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AvaColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (challenge.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.statusAccepted.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      color: AppColors.statusAccepted,
                      size: 18,
                    ),
                  )
                else if (!isUnlocked)
                  Column(
                    children: const [
                      Icon(LucideIcons.lock, size: 18, color: AvaColors.muted),
                      SizedBox(height: 2),
                      Text(
                        'locked',
                        style: TextStyle(fontSize: 10, color: AvaColors.muted),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        '+${challenge.points}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: challenge.color,
                        ),
                      ),
                      const Text(
                        'pts',
                        style: TextStyle(fontSize: 10, color: AvaColors.muted),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoadingLeaderboard) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading leaderboard...',
              style: TextStyle(color: AvaColors.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final user = leaderboard[index];
        final isCurrentUser = false; // In real app, compare with logged-in user

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildLeaderboardItem(user, index, isCurrentUser)
              .animate()
              .fadeIn(duration: 500.ms, delay: (50 * index).ms)
              .slideX(begin: -0.2, end: 0, duration: 500.ms),
        );
      },
    );
  }

  Widget _buildLeaderboardItem(
    UserProfile user,
    int index,
    bool isCurrentUser,
  ) {
    final isTop3 = index < 3;
    final medalIcon = index == 0
        ? LucideIcons.trophy
        : index == 1
        ? LucideIcons.award
        : index == 2
        ? LucideIcons.star
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isTop3
            ? LinearGradient(
                colors: [
                  _getMedalColor(index).withValues(alpha: 0.1),
                  _getMedalColor(index).withValues(alpha: 0.03),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.cyan500.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? _getMedalColor(index).withValues(alpha: 0.2)
              : AppColors.cyan500.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isTop3
                  ? LinearGradient(
                      colors: [
                        _getMedalColor(index),
                        _getMedalColor(index).withValues(alpha: 0.7),
                      ],
                    )
                  : LinearGradient(
                      colors: [AppColors.cyan500, AppColors.cyan400],
                    ),
            ),
            child: isTop3
                ? Icon(medalIcon, color: Colors.white, size: 18)
                : Center(
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (index == 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.badge,
                                size: 10,
                                color: Color(0xFFF59E0B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Monthly Champion',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (user.isPremium)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD946EF,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.crown,
                                size: 10,
                                color: Color(0xFFD946EF),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Pro',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFD946EF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.completedChallengeIds.length} challenges completed',
                  style: const TextStyle(fontSize: 11, color: AvaColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.totalPoints}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isTop3 ? _getMedalColor(index) : AppColors.cyan400,
                ),
              ),
              const Text(
                'points',
                style: TextStyle(fontSize: 10, color: AvaColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChallengeDetail(Challenge challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildChallengeDetailSheet(challenge),
    );
  }

  Widget _buildChallengeDetailSheet(Challenge challenge) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 4,
          width: 40,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.cyan500.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          challenge.color,
                          challenge.color.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Icon(
                      _getIconData(challenge.icon),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '+${challenge.points} points',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: challenge.color,
                              ),
                            ),
                            if (challenge.requiresVoice) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                LucideIcons.mic,
                                size: 14,
                                color: AppColors.cyan400,
                              ),
                            ],
                            if (challenge.requiresPayment) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                LucideIcons.creditCard,
                                size: 14,
                                color: Color(0xFFD946EF),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (challenge.longDescription != null) ...[
                Text(
                  challenge.longDescription!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AvaColors.muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Steps to Complete:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 12),
              ...challenge.steps.asMap().entries.map((entry) {
                final step = entry.value;
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: challenge.color.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: challenge.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AvaColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              if (challenge.isCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.statusAccepted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.statusAccepted),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        LucideIcons.check,
                        size: 18,
                        color: AppColors.statusAccepted,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusAccepted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'mic': LucideIcons.mic,
      'share2': LucideIcons.share2,
      'user-check': LucideIcons.userCheck,
      'calendar': LucideIcons.calendar,
      'calendar-check': LucideIcons.calendarCheck,
      'users': LucideIcons.users,
      'crown': LucideIcons.crown,
      'zap': LucideIcons.zap,
      'message-circle': LucideIcons.messageCircle,
      'code': LucideIcons.code,
      'award': LucideIcons.award,
      'shield': LucideIcons.shield,
      'file-text': LucideIcons.fileText,
      'sparkles': LucideIcons.sparkles,
    };
    return iconMap[iconName] ?? LucideIcons.target;
  }

  Color _getMedalColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // Gold
    if (index == 1) return const Color(0xFFC0C0C0); // Silver
    return const Color(0xFFCD7F32); // Bronze
  }
}
