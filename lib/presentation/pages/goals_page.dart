import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/services/goals_api_service.dart';
import '../../injection_container.dart';
import '../widgets/navigation_bar.dart';

const String _kGoalsLocalKey = 'goals_local_list';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final GoalsApiService _apiService = InjectionContainer.instance.goalsApiService;
  List<Goal> _goals = [];
  List<Achievement> _achievements = [];
  bool _loading = true;
  String? _error;
  String? _togglingActionGoalId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    List<Goal> localGoals = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kGoalsLocalKey);
      if (saved != null && saved.isNotEmpty) {
        try {
          final list = jsonDecode(saved) as List<dynamic>?;
          if (list != null) {
            localGoals = list
                .map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
        } catch (_) {}
      }
    } catch (_) {}

    try {
      final results = await Future.wait([
        _apiService.fetchGoals(),
        _apiService.fetchAchievements(),
      ]);
      final apiGoals = results[0] as List<Goal>;
      final apiAchievements = results[1] as List<Achievement>;
      if (!mounted) return;
      final goalsToUse = apiGoals.isNotEmpty ? apiGoals : localGoals;
      if (apiGoals.isNotEmpty) await _saveGoalsToLocal(apiGoals);
      setState(() {
        _goals = goalsToUse;
        _achievements = apiAchievements;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _goals = localGoals;
        _achievements = [];
        _loading = false;
        _error = null;
      });
    }
  }

  Future<void> _saveGoalsToLocal(List<Goal> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = goals.map((g) => g.toJson()).toList();
      await prefs.setString(_kGoalsLocalKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _updateGoalProgress(Goal goal, int newProgress) async {
    final value = newProgress.clamp(0, 100);
    if (goal.id.startsWith('local_')) {
      final updated = goal.copyWith(progress: value);
      if (!mounted) return;
      setState(() {
        final i = _goals.indexWhere((g) => g.id == goal.id);
        if (i >= 0) _goals = List.from(_goals)..[i] = updated;
      });
      await _saveGoalsToLocal(_goals);
      return;
    }
    final updated = await _apiService.updateGoalProgress(goal.id, value);
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        final i = _goals.indexWhere((g) => g.id == goal.id);
        if (i >= 0) _goals = List.from(_goals)..[i] = updated;
      });
    }
  }

  void _showProgressDialog(Goal goal) {
    final progress = goal.progress.clamp(0, 100);
    int selectedProgress = progress;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.primaryMedium,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Progression',
              style: TextStyle(color: AppColors.textWhite, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: TextStyle(color: AppColors.textCyan200, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                Text(
                  '$selectedProgress %',
                  style: TextStyle(color: AppColors.cyan400, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.cyan500,
                    inactiveTrackColor: AppColors.cyan500.withOpacity(0.2),
                    thumbColor: AppColors.cyan400,
                  ),
                  child: Slider(
                    value: selectedProgress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) => setDialogState(() => selectedProgress = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [0, 25, 50, 75, 100].map((p) {
                    return TextButton(
                      onPressed: () => setDialogState(() => selectedProgress = p),
                      child: Text(
                        '$p%',
                        style: TextStyle(
                          color: selectedProgress == p ? AppColors.cyan400 : AppColors.textCyan200,
                          fontWeight: selectedProgress == p ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Annuler', style: TextStyle(color: AppColors.textCyan200)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _updateGoalProgress(goal, selectedProgress);
                },
                child: Text('OK', style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleAction(Goal goal, GoalAction action) async {
    if (_togglingActionGoalId == goal.id) return;
    setState(() => _togglingActionGoalId = goal.id);
    if (goal.id.startsWith('local_')) {
      final newActions = goal.dailyActions.map((a) => a.id == action.id ? a.copyWith(completed: !a.completed) : a).toList();
      final updated = goal.copyWith(dailyActions: newActions);
      if (!mounted) return;
      setState(() {
        _togglingActionGoalId = null;
        final i = _goals.indexWhere((g) => g.id == goal.id);
        if (i >= 0) _goals = List.from(_goals)..[i] = updated;
      });
      await _saveGoalsToLocal(_goals);
      return;
    }
    final updated = await _apiService.toggleActionCompleted(
      goal.id,
      action.id,
      !action.completed,
    );
    if (!mounted) return;
    setState(() {
      _togglingActionGoalId = null;
      if (updated != null) {
        final i = _goals.indexWhere((g) => g.id == goal.id);
        if (i >= 0) _goals = List.from(_goals)..[i] = updated;
      }
    });
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Personal');
    final deadlineController = TextEditingController(text: 'Ongoing');
    final isMobile = Responsive.isMobile(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 32.0, desktop: 48.0),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.getResponsiveValue(context, mobile: 400.0, tablet: 440.0, desktop: 480.0),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1e4a66).withOpacity(0.95),
                const Color(0xFF16384d).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0)),
            border: Border.all(color: AppColors.cyan500.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cyan500.withOpacity(0.3),
                                  AppColors.blue500.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
                              border: Border.all(color: AppColors.cyan500.withOpacity(0.4), width: 1),
                            ),
                            child: Icon(LucideIcons.target, color: AppColors.cyan400, size: Responsive.getResponsiveValue(context, mobile: 22.0, tablet: 24.0, desktop: 26.0)),
                          ),
                          SizedBox(width: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
                          Text(
                            'New Goal',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(context, mobile: 22.0, tablet: 24.0, desktop: 26.0),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
                      _buildDialogLabel(context, isMobile, 'Title'),
                      SizedBox(height: 8),
                      _buildDialogTextField(context, isMobile, titleController, 'Enter goal title'),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0)),
                      _buildDialogLabel(context, isMobile, 'Category'),
                      SizedBox(height: 8),
                      _buildDialogTextField(context, isMobile, categoryController, 'Work, Personal, Learning...'),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0)),
                      _buildDialogLabel(context, isMobile, 'Deadline'),
                      SizedBox(height: 8),
                      _buildDialogTextField(context, isMobile, deadlineController, 'e.g. Mar 31, Ongoing'),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 28.0, tablet: 32.0, desktop: 36.0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.textCyan200,
                                fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;
                              final category = categoryController.text.trim().isEmpty ? 'Personal' : categoryController.text.trim();
                              final deadline = deadlineController.text.trim().isEmpty ? 'Ongoing' : deadlineController.text.trim();
                              Navigator.of(dialogContext).pop();
                              final created = await _apiService.createGoal(
                                title: title,
                                category: category,
                                deadline: deadline,
                              );
                              if (!mounted) return;
                              if (created != null) {
                                await _loadData();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Objectif créé', style: TextStyle(color: AppColors.textWhite)),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.statusAccepted.withOpacity(0.9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              } else {
                                final localGoal = Goal(
                                  id: 'local_${DateTime.now().millisecondsSinceEpoch}',
                                  title: title,
                                  category: category,
                                  progress: 0,
                                  deadline: deadline,
                                  dailyActions: [],
                                  streak: 0,
                                );
                                setState(() {
                                  _goals = [localGoal, ..._goals];
                                });
                                await _saveGoalsToLocal(_goals);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Objectif enregistré localement',
                                        style: TextStyle(color: AppColors.textWhite),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.cyan500.withOpacity(0.9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
                                vertical: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.cyan500.withOpacity(0.5),
                                    AppColors.blue500.withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
                                border: Border.all(color: AppColors.cyan500.withOpacity(0.6), width: 1.5),
                              ),
                              child: Text(
                                'Create',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogLabel(BuildContext context, bool isMobile, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
        fontWeight: FontWeight.w600,
        color: AppColors.textCyan200.withOpacity(0.95),
      ),
    );
  }

  Widget _buildDialogTextField(BuildContext context, bool isMobile, TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.25), width: 1),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textCyan200.withOpacity(0.5), fontSize: 14),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
            vertical: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f2940),
              Color(0xFF1a3a52),
              Color(0xFF0f2940),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              if (_loading)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading goals...',
                        style: TextStyle(color: AppColors.textCyan200, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.cyan400,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        _buildHeader(context, isMobile)
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.2, end: 0, duration: 500.ms),
                        SizedBox(height: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                        _buildNewGoalButton(context, isMobile)
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 300.ms)
                            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 100.ms, duration: 300.ms),
                        SizedBox(height: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                        if (_error != null) _buildError(context, isMobile),
                        if (_error == null && _goals.isEmpty)
                          _buildEmptyGoals(context, isMobile)
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 300.ms)
                              .slideY(begin: 0.1, end: 0, delay: 150.ms, duration: 300.ms),
                        if (_error == null && _goals.isNotEmpty)
                          ..._goals.asMap().entries.map((entry) {
                            final index = entry.key;
                            final goal = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                              ),
                              child: _buildGoalCard(context, isMobile, goal, index)
                                  .animate()
                                  .fadeIn(delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms)
                                  .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms),
                            );
                          }),
                        if (_error == null && _goals.isNotEmpty) ...[
                          SizedBox(height: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                          _buildAchievementsSection(context, isMobile, _achievements)
                              .animate()
                              .fadeIn(delay: 500.ms, duration: 300.ms)
                              .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 300.ms),
                        ],
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/goals'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
      child: Container(
        padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _error ?? 'Error loading goals',
                style: TextStyle(color: AppColors.textWhite, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _loadData,
              child: Text('Retry', style: TextStyle(color: AppColors.cyan400)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoals(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cyan500.withOpacity(0.1),
              AppColors.blue500.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.target, size: 48, color: AppColors.cyan400.withOpacity(0.6)),
            SizedBox(height: 16),
            Text(
              'No goals yet',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap "New Goal" to add your first objective.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textCyan200.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goals',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 26.0, tablet: 28.0, desktop: 32.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
        Text(
          'Track your personal and professional growth',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
            color: AppColors.textCyan200.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNewGoalButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: _showAddGoalDialog,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: Responsive.getResponsiveValue(context, mobile: 11.0, tablet: 12.0, desktop: 14.0),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cyan500.withOpacity(0.3),
              AppColors.blue500.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 13.0, desktop: 14.0)),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, size: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0), color: AppColors.textCyan300),
            SizedBox(width: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
            Text(
              'New Goal',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textCyan300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, bool isMobile, Goal goal, int index) {
    final progress = goal.progress.clamp(0, 100);
    final dailyActions = goal.dailyActions;
    final streak = goal.streak;
    final isToggling = _togglingActionGoalId == goal.id;

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                        ),
                        SizedBox(height: Responsive.getResponsiveValue(context, mobile: 4.0, tablet: 5.0, desktop: 6.0)),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
                                vertical: Responsive.getResponsiveValue(context, mobile: 3.0, tablet: 4.0, desktop: 5.0),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyan500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 4.0, tablet: 5.0, desktop: 6.0)),
                                border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
                              ),
                              child: Text(
                                goal.category,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 11.0, desktop: 12.0),
                                  color: AppColors.cyan400,
                                ),
                              ),
                            ),
                            SizedBox(width: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                            Row(
                              children: [
                                Icon(LucideIcons.calendar, size: Responsive.getResponsiveValue(context, mobile: 11.0, tablet: 12.0, desktop: 13.0), color: AppColors.cyan400.withOpacity(0.6)),
                                SizedBox(width: Responsive.getResponsiveValue(context, mobile: 3.0, tablet: 4.0, desktop: 5.0)),
                                Text(
                                  goal.deadline,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 11.0, desktop: 12.0),
                                    color: AppColors.cyan400.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showProgressDialog(goal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$progress%',
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(context, mobile: 22.0, tablet: 24.0, desktop: 26.0),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(LucideIcons.pencil, size: 14, color: AppColors.cyan400.withOpacity(0.7)),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Complete · tap to change',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 11.0, desktop: 12.0),
                            color: AppColors.cyan400.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
              Container(
                height: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 7.0, desktop: 8.0),
                decoration: BoxDecoration(
                  color: AppColors.cyan500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 3.0, tablet: 3.5, desktop: 4.0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 3.0, tablet: 3.5, desktop: 4.0)),
                  child: FractionallySizedBox(
                    widthFactor: progress / 100,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.cyan500, AppColors.blue500],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
              Text(
                'Today\'s Actions',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 11.0, tablet: 12.0, desktop: 13.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan400,
                ),
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
              if (dailyActions.isEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No actions for today',
                    style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.6)),
                  ),
                )
              else
                ...dailyActions.map((action) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.getResponsiveValue(context, mobile: 3.0, tablet: 4.0, desktop: 5.0),
                    ),
                    child: GestureDetector(
                      onTap: isToggling ? null : () => _toggleAction(goal, action),
                      child: Row(
                        children: [
                          Icon(
                            action.completed ? LucideIcons.checkCircle : LucideIcons.circle,
                            size: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                            color: action.completed ? const Color(0xFF10B981) : AppColors.textCyan200.withOpacity(0.5),
                          ),
                          SizedBox(width: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                          Expanded(
                            child: Text(
                              action.label,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 13.0, desktop: 14.0),
                                color: action.completed
                                    ? AppColors.textCyan200.withOpacity(0.6)
                                    : AppColors.textCyan200.withOpacity(0.9),
                                decoration: action.completed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
              Container(
                padding: EdgeInsets.only(
                  top: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.cyan500.withOpacity(0.1), width: 1)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.award, size: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0), color: const Color(0xFFFCD34D)),
                    SizedBox(width: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                    Text(
                      '$streak day streak!',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFCD34D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, bool isMobile, List<Achievement> achievements) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9333EA).withOpacity(0.1),
            AppColors.blue500.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: const Color(0xFF9333EA).withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.award, size: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0), color: const Color(0xFFC084FC)),
                  SizedBox(width: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                  Text(
                    'Recent Achievements',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 17.0, desktop: 18.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
              if (achievements.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Complete goals and actions to unlock achievements.',
                    style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.7)),
                  ),
                )
              else
                ...achievements.map((achievement) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                    ),
                    child: Row(
                      children: [
                        Text(achievement.icon, style: TextStyle(fontSize: Responsive.getResponsiveValue(context, mobile: 22.0, tablet: 24.0, desktop: 26.0))),
                        SizedBox(width: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.title,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                achievement.date,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(context, mobile: 11.0, tablet: 12.0, desktop: 13.0),
                                  color: const Color(0xFFC084FC).withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
