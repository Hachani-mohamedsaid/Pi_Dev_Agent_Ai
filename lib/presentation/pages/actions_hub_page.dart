import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

enum ActionStatus { available, pending, completed }
enum ActionCategory { all, transport, food, communication, finance }

class SmartAction {
  final int id;
  final String title;
  final String description;
  final IconData icon;
  final ActionCategory category;
  final ActionStatus status;
  final int? confidence;
  final bool requiresConfirmation;
  final String? lastUsed;

  SmartAction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.status,
    this.confidence,
    required this.requiresConfirmation,
    this.lastUsed,
  });
}

class ActionsHubPage extends StatefulWidget {
  const ActionsHubPage({super.key});

  @override
  State<ActionsHubPage> createState() => _ActionsHubPageState();
}

class _ActionsHubPageState extends State<ActionsHubPage> {
  ActionCategory _selectedCategory = ActionCategory.all;
  int? _expandedAction;

  final List<SmartAction> _actions = [
    SmartAction(
      id: 1,
      title: 'Book Uber',
      description: 'Quick ride booking to your frequent destinations',
      icon: LucideIcons.car,
      category: ActionCategory.transport,
      status: ActionStatus.available,
      confidence: 95,
      requiresConfirmation: true,
      lastUsed: '2 hours ago',
    ),
    SmartAction(
      id: 2,
      title: 'Order Coffee',
      description: 'Your usual order from favorite coffee shop',
      icon: LucideIcons.coffee,
      category: ActionCategory.food,
      status: ActionStatus.available,
      confidence: 90,
      requiresConfirmation: true,
      lastUsed: 'Yesterday',
    ),
    SmartAction(
      id: 3,
      title: 'Schedule Meeting',
      description: 'Find optimal time slots for all participants',
      icon: LucideIcons.calendar,
      category: ActionCategory.communication,
      status: ActionStatus.pending,
      requiresConfirmation: true,
    ),
    SmartAction(
      id: 4,
      title: 'Draft Email',
      description: 'AI-powered email composition',
      icon: LucideIcons.mail,
      category: ActionCategory.communication,
      status: ActionStatus.available,
      confidence: 88,
      requiresConfirmation: false,
    ),
    SmartAction(
      id: 5,
      title: 'Pay Bill',
      description: 'Quick bill payment with saved methods',
      icon: LucideIcons.dollarSign,
      category: ActionCategory.finance,
      status: ActionStatus.available,
      requiresConfirmation: true,
    ),
    SmartAction(
      id: 6,
      title: 'Make Call',
      description: 'Quick dial to frequent contacts',
      icon: LucideIcons.phone,
      category: ActionCategory.communication,
      status: ActionStatus.completed,
      lastUsed: '1 hour ago',
      requiresConfirmation: false,
    ),
  ];

  List<SmartAction> get _filteredActions {
    if (_selectedCategory == ActionCategory.all) {
      return _actions;
    }
    return _actions.where((a) => a.category == _selectedCategory).toList();
  }

  Map<String, dynamic> _getStatusConfig(ActionStatus status) {
    switch (status) {
      case ActionStatus.available:
        return {
          'icon': LucideIcons.checkCircle,
          'color': const Color(0xFF4ADE80),
          'bg': const Color(0xFF10B981).withOpacity(0.1),
          'border': const Color(0xFF10B981).withOpacity(0.2),
          'label': 'Ready',
        };
      case ActionStatus.pending:
        return {
          'icon': LucideIcons.clock,
          'color': const Color(0xFFFFD93D),
          'bg': const Color(0xFFFFB800).withOpacity(0.1),
          'border': const Color(0xFFFFB800).withOpacity(0.2),
          'label': 'Pending',
        };
      case ActionStatus.completed:
        return {
          'icon': LucideIcons.checkCircle,
          'color': AppColors.cyan400,
          'bg': AppColors.cyan500.withOpacity(0.1),
          'border': AppColors.cyan500.withOpacity(0.2),
          'label': 'Done',
        };
    }
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
              // Main Content
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
                  ), // Space for navigation bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Header
                _buildHeader(context, isMobile)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0, duration: 500.ms),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Stats
                _buildStats(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Category Filter
                _buildCategoryFilter(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Actions List
                _buildActionsList(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Info Footer
                _buildInfoFooter(context, isMobile)
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/actions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Actions',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 26.0,
              tablet: 28.0,
              desktop: 32.0,
            ),
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 6.0,
          tablet: 8.0,
          desktop: 10.0,
        )),
        Text(
          'Automated tasks AVA can perform for you',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 13.0,
              tablet: 14.0,
              desktop: 15.0,
            ),
            color: AppColors.textCyan200.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, bool isMobile) {
    final availableCount = _actions.where((a) => a.status == ActionStatus.available).length;
    final pendingCount = _actions.where((a) => a.status == ActionStatus.pending).length;

    final stats = [
      {'icon': LucideIcons.checkCircle, 'value': '$availableCount', 'label': 'Available', 'color': const Color(0xFF4ADE80)},
      {'icon': LucideIcons.clock, 'value': '$pendingCount', 'label': 'Pending', 'color': const Color(0xFFFFD93D)},
      {'icon': LucideIcons.zap, 'value': '24', 'label': 'This week', 'color': AppColors.cyan400},
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < stats.length - 1
                  ? Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    )
                  : 0,
            ),
            child: Container(
              padding: EdgeInsets.all(Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 20.0,
              )),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1e4a66).withOpacity(0.4),
                    const Color(0xFF16384d).withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                )),
                border: Border.all(
                  color: AppColors.cyan500.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                )),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
                        ),
                        color: stat['color'] as Color,
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 6.0,
                        tablet: 8.0,
                        desktop: 10.0,
                      )),
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 22.0,
                            desktop: 24.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 3.0,
                        tablet: 4.0,
                        desktop: 5.0,
                      )),
                      Text(
                        stat['label'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 11.0,
                            desktop: 12.0,
                          ),
                          color: AppColors.cyan400.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, bool isMobile) {
    final categories = [
      {'category': ActionCategory.all, 'icon': LucideIcons.zap, 'label': 'All'},
      {'category': ActionCategory.transport, 'icon': LucideIcons.car, 'label': 'Transport'},
      {'category': ActionCategory.food, 'icon': LucideIcons.coffee, 'label': 'Food'},
      {'category': ActionCategory.communication, 'icon': LucideIcons.phone, 'label': 'Comm'},
      {'category': ActionCategory.finance, 'icon': LucideIcons.dollarSign, 'label': 'Finance'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final category = cat['category'] as ActionCategory;
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(
              right: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getResponsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                  vertical: Responsive.getResponsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 9.0,
                    desktop: 10.0,
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.cyan500.withOpacity(0.3),
                            AppColors.blue500.withOpacity(0.3),
                          ],
                        )
                      : null,
                  color: isSelected ? null : AppColors.textWhite.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 13.0,
                    desktop: 14.0,
                  )),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.cyan500.withOpacity(0.5)
                        : AppColors.textWhite.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                      color: isSelected
                          ? AppColors.textCyan300
                          : AppColors.cyan400.withOpacity(0.7),
                    ),
                    SizedBox(width: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    )),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.textCyan300
                            : AppColors.cyan400.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionsList(BuildContext context, bool isMobile) {
    return Column(
      children: _filteredActions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildActionCard(context, isMobile, action, index),
        );
      }).toList(),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    bool isMobile,
    SmartAction action,
    int index,
  ) {
    final statusConfig = _getStatusConfig(action.status);
    final isExpanded = _expandedAction == action.id;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Main Content
              GestureDetector(
                onTap: () => setState(() => _expandedAction = isExpanded ? null : action.id),
                child: Padding(
                  padding: EdgeInsets.all(Responsive.getResponsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 20.0,
                  )),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: Responsive.getResponsiveValue(
                          context,
                          mobile: 44.0,
                          tablet: 48.0,
                          desktop: 52.0,
                        ),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 44.0,
                          tablet: 48.0,
                          desktop: 52.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.cyan500.withOpacity(0.2),
                              AppColors.blue500.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 11.0,
                            desktop: 12.0,
                          )),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          action.icon,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 22.0,
                            tablet: 24.0,
                            desktop: 26.0,
                          ),
                          color: AppColors.cyan400,
                        ),
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    action.title,
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 15.0,
                                        tablet: 16.0,
                                        desktop: 17.0,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 8.0,
                                      tablet: 10.0,
                                      desktop: 12.0,
                                    ),
                                    vertical: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 4.0,
                                      tablet: 5.0,
                                      desktop: 6.0,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusConfig['bg'] as Color,
                                    borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                      context,
                                      mobile: 6.0,
                                      tablet: 7.0,
                                      desktop: 8.0,
                                    )),
                                    border: Border.all(
                                      color: statusConfig['border'] as Color,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        statusConfig['icon'] as IconData,
                                        size: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 13.0,
                                          tablet: 14.0,
                                          desktop: 15.0,
                                        ),
                                        color: statusConfig['color'] as Color,
                                      ),
                                      SizedBox(width: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 4.0,
                                        tablet: 5.0,
                                        desktop: 6.0,
                                      )),
                                      Text(
                                        statusConfig['label'] as String,
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 11.0,
                                            tablet: 12.0,
                                            desktop: 13.0,
                                          ),
                                          fontWeight: FontWeight.w500,
                                          color: statusConfig['color'] as Color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 10.0,
                            )),
                            Text(
                              action.description,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 13.0,
                                  desktop: 14.0,
                                ),
                                color: AppColors.textCyan200.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: Responsive.getResponsiveValue(
                              context,
                              mobile: 8.0,
                              tablet: 10.0,
                              desktop: 12.0,
                            )),
                            // Meta Info
                            Wrap(
                              spacing: Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 12.0,
                                desktop: 14.0,
                              ),
                              runSpacing: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              ),
                              children: [
                                if (action.confidence != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 5.0,
                                          tablet: 6.0,
                                          desktop: 7.0,
                                        ),
                                        height: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 5.0,
                                          tablet: 6.0,
                                          desktop: 7.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.cyan400,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 4.0,
                                        tablet: 5.0,
                                        desktop: 6.0,
                                      )),
                                      Text(
                                        '${action.confidence}% confidence',
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 10.0,
                                            tablet: 11.0,
                                            desktop: 12.0,
                                          ),
                                          color: AppColors.cyan400.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (action.lastUsed != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.clock,
                                        size: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 12.0,
                                          tablet: 13.0,
                                          desktop: 14.0,
                                        ),
                                        color: AppColors.cyan400.withOpacity(0.5),
                                      ),
                                      SizedBox(width: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 4.0,
                                        tablet: 5.0,
                                        desktop: 6.0,
                                      )),
                                      Text(
                                        action.lastUsed!,
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 10.0,
                                            tablet: 11.0,
                                            desktop: 12.0,
                                          ),
                                          color: AppColors.cyan400.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (action.requiresConfirmation)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.alertCircle,
                                        size: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 12.0,
                                          tablet: 13.0,
                                          desktop: 14.0,
                                        ),
                                        color: const Color(0xFFFFD93D).withOpacity(0.7),
                                      ),
                                      SizedBox(width: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 4.0,
                                        tablet: 5.0,
                                        desktop: 6.0,
                                      )),
                                      Text(
                                        'Needs approval',
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 10.0,
                                            tablet: 11.0,
                                            desktop: 12.0,
                                          ),
                                          color: const Color(0xFFFFD93D).withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded Actions
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? Container(
                        padding: EdgeInsets.only(
                          left: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 20.0,
                          ),
                          right: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 20.0,
                          ),
                          bottom: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 20.0,
                          ),
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.cyan500.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: Responsive.getResponsiveValue(
                              context,
                              mobile: 10.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            )),
                            if (action.status == ActionStatus.available) ...[
                              _buildActionButton(
                                context,
                                isMobile,
                                'Execute Action',
                                true,
                              ),
                              SizedBox(height: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              )),
                              _buildActionButton(
                                context,
                                isMobile,
                                'Configure Settings',
                                false,
                              ),
                            ],
                            if (action.status == ActionStatus.pending)
                              Container(
                                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                                  context,
                                  mobile: 10.0,
                                  tablet: 12.0,
                                  desktop: 14.0,
                                )),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB800).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 13.0,
                                    desktop: 14.0,
                                  )),
                                  border: Border.all(
                                    color: const Color(0xFFFFB800).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'This action is being processed...',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 13.0,
                                        desktop: 14.0,
                                      ),
                                      color: const Color(0xFFFFD93D),
                                    ),
                                  ),
                                ),
                              ),
                            if (action.status == ActionStatus.completed)
                              Container(
                                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                                  context,
                                  mobile: 10.0,
                                  tablet: 12.0,
                                  desktop: 14.0,
                                )),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan500.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 13.0,
                                    desktop: 14.0,
                                  )),
                                  border: Border.all(
                                    color: AppColors.cyan500.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Completed ${action.lastUsed ?? ''}',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 13.0,
                                        desktop: 14.0,
                                      ),
                                      color: AppColors.cyan400,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 400 + (index * 100)), duration: 300.ms)
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 400 + (index * 100)), duration: 300.ms);
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isMobile,
    String label,
    bool isPrimary,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle action
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: Responsive.getResponsiveValue(
            context,
            mobile: 11.0,
            tablet: 12.0,
            desktop: 14.0,
          ),
        ),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cyan500,
                    AppColors.cyan400,
                  ],
                )
              : null,
          color: isPrimary ? null : AppColors.textWhite.withOpacity(0.05),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          )),
          border: Border.all(
            color: isPrimary
                ? AppColors.cyan500.withOpacity(0.3)
                : AppColors.textWhite.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.cyan400.withOpacity(0.3),
                    blurRadius: Responsive.getResponsiveValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 13.0,
                tablet: 14.0,
                desktop: 15.0,
              ),
              fontWeight: FontWeight.w500,
              color: isPrimary ? AppColors.textWhite : AppColors.cyan400.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFooter(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 14.0,
        tablet: 16.0,
        desktop: 20.0,
      )),
      decoration: BoxDecoration(
        color: AppColors.cyan500.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 13.0,
          desktop: 14.0,
        )),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
            color: AppColors.cyan400.withOpacity(0.7),
          ),
          SizedBox(width: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          )),
          Text(
            'Actions marked require your confirmation before execution',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 11.0,
                desktop: 12.0,
              ),
              color: AppColors.cyan400.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
