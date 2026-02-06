import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

enum ActionStatus { accepted, declined, modified }

class AIAction {
  final int id;
  final String action;
  final String timestamp;
  final ActionStatus status;
  final String outcome;
  final String reason;

  AIAction({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.status,
    required this.outcome,
    required this.reason,
  });
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Set<int> _expandedItems = {};

  final List<AIAction> _actions = [
    AIAction(
      id: 1,
      action: 'Postpone 16:00 meeting to tomorrow morning',
      timestamp: '2 hours ago',
      status: ActionStatus.accepted,
      outcome: 'Meeting rescheduled to 09:00 tomorrow',
      reason: 'You usually decline meetings after 17:00, so this was flagged as optional and better suited for morning hours when you\'re most productive.',
    ),
    AIAction(
      id: 2,
      action: 'Combine two design meetings into one session',
      timestamp: '5 hours ago',
      status: ActionStatus.modified,
      outcome: 'Meetings combined but scheduled for Thursday instead',
      reason: 'Both meetings had overlapping topics and participants. Combining them would save 30 minutes and reduce context switching.',
    ),
    AIAction(
      id: 3,
      action: 'Decline lunch meeting with external vendor',
      timestamp: 'Yesterday',
      status: ActionStatus.declined,
      outcome: 'Meeting kept in calendar',
      reason: 'This type of meeting is typically low priority based on your past decisions, and you had a full morning scheduled.',
    ),
    AIAction(
      id: 4,
      action: 'Block focus time during afternoon gap',
      timestamp: 'Yesterday',
      status: ActionStatus.accepted,
      outcome: '2-hour focus block created from 14:00-16:00',
      reason: 'You had a 3-hour gap with no meetings, which historically leads to scattered work. Focus time helps maintain productivity.',
    ),
    AIAction(
      id: 5,
      action: 'Summarize 12 unread emails into priority groups',
      timestamp: '2 days ago',
      status: ActionStatus.accepted,
      outcome: '3 urgent, 5 informational, 4 can wait',
      reason: 'Your inbox had accumulated messages. Prioritization helps you address urgent items first during your morning review.',
    ),
  ];

  void _toggleExpanded(int id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
      }
    });
  }

  Map<String, dynamic> _getStatusConfig(ActionStatus status) {
    switch (status) {
      case ActionStatus.accepted:
        return {
          'icon': LucideIcons.checkCircle,
          'color': const Color(0xFF4ADE80),
          'bg': const Color(0xFF10B981).withOpacity(0.1),
          'border': const Color(0xFF10B981).withOpacity(0.2),
          'label': 'Accepted',
        };
      case ActionStatus.declined:
        return {
          'icon': LucideIcons.xCircle,
          'color': const Color(0xFFFF6B6B),
          'bg': const Color(0xFFFF0000).withOpacity(0.1),
          'border': const Color(0xFFFF0000).withOpacity(0.2),
          'label': 'Declined',
        };
      case ActionStatus.modified:
        return {
          'icon': LucideIcons.clock,
          'color': const Color(0xFFFFD93D),
          'bg': const Color(0xFFFFB800).withOpacity(0.1),
          'border': const Color(0xFFFFB800).withOpacity(0.2),
          'label': 'Modified',
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

                // Timeline List
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
                    .fadeIn(delay: 600.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/history'),
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
          'AI Activity',
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
          'Complete transparency of all AI actions',
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

  Widget _buildActionsList(BuildContext context, bool isMobile) {
    return Column(
      children: _actions.asMap().entries.map((entry) {
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
    AIAction action,
    int index,
  ) {
    final statusConfig = _getStatusConfig(action.status);
    final isExpanded = _expandedItems.contains(action.id);

    return GestureDetector(
      onTap: () => _toggleExpanded(action.id),
      child: Container(
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
                Padding(
                  padding: EdgeInsets.all(Responsive.getResponsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 20.0,
                  )),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: Responsive.getResponsiveValue(
                              context,
                              mobile: 36.0,
                              tablet: 40.0,
                              desktop: 44.0,
                            ),
                            height: Responsive.getResponsiveValue(
                              context,
                              mobile: 36.0,
                              tablet: 40.0,
                              desktop: 44.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyan500.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 11.0,
                                desktop: 12.0,
                              )),
                            ),
                            child: Icon(
                              LucideIcons.brain,
                              size: Responsive.getResponsiveValue(
                                context,
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                              color: AppColors.cyan400,
                            ),
                          ),
                          SizedBox(width: Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          )),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.action,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 13.0,
                                      tablet: 14.0,
                                      desktop: 15.0,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                SizedBox(height: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                )),
                                Text(
                                  action.timestamp,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 11.0,
                                      tablet: 12.0,
                                      desktop: 13.0,
                                    ),
                                    color: AppColors.textCyan200.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: Responsive.getResponsiveValue(
                                context,
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                              color: AppColors.cyan400.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      )),
                      // Status Badge
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
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      )),
                      // Outcome
                      Container(
                        padding: EdgeInsets.all(Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        )),
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 8.0,
                            tablet: 9.0,
                            desktop: 10.0,
                          )),
                          border: Border.all(
                            color: AppColors.textWhite.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outcome',
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 11.0,
                                  tablet: 12.0,
                                  desktop: 13.0,
                                ),
                                fontWeight: FontWeight.w500,
                                color: AppColors.cyan400,
                              ),
                            ),
                            SizedBox(height: Responsive.getResponsiveValue(
                              context,
                              mobile: 4.0,
                              tablet: 5.0,
                              desktop: 6.0,
                            )),
                            Text(
                              action.outcome,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 11.0,
                                  tablet: 12.0,
                                  desktop: 13.0,
                                ),
                                color: AppColors.textCyan200.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Expandable Reason Section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: isExpanded ? null : 0,
                  child: isExpanded
                      ? Padding(
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
                          child: Container(
                            padding: EdgeInsets.all(Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 16.0,
                              desktop: 20.0,
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 30.0,
                                    tablet: 32.0,
                                    desktop: 36.0,
                                  ),
                                  height: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 30.0,
                                    tablet: 32.0,
                                    desktop: 36.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan500.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                      context,
                                      mobile: 8.0,
                                      tablet: 9.0,
                                      desktop: 10.0,
                                    )),
                                  ),
                                  child: Icon(
                                    LucideIcons.brain,
                                    size: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 14.0,
                                      tablet: 16.0,
                                      desktop: 18.0,
                                    ),
                                    color: AppColors.cyan400,
                                  ),
                                ),
                                SizedBox(width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 10.0,
                                  tablet: 12.0,
                                  desktop: 14.0,
                                )),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Why did AVA suggest this?',
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 11.0,
                                            tablet: 12.0,
                                            desktop: 13.0,
                                          ),
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.cyan400,
                                        ),
                                      ),
                                      SizedBox(height: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 6.0,
                                        tablet: 8.0,
                                        desktop: 10.0,
                                      )),
                                      Text(
                                        action.reason,
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 11.0,
                                            tablet: 12.0,
                                            desktop: 13.0,
                                          ),
                                          color: AppColors.textCyan200.withOpacity(0.8),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100), duration: 300.ms)
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: index * 100), duration: 300.ms);
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
      child: Text(
        'Everything AVA does is logged here. Nothing is hidden.',
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
    );
  }
}
