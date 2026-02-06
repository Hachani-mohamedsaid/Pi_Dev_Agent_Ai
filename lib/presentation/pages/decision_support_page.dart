import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

class DecisionSupportPage extends StatelessWidget {
  const DecisionSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final pendingDecisions = [
      {
        'id': 1,
        'title': 'Reschedule Friday 5 PM meeting?',
        'description': 'Client wants to meet Friday at 5 PM, but you typically avoid late meetings.',
        'pros': ['Client is flexible with time', 'Important project discussion'],
        'cons': ['Outside preferred hours', 'Energy levels typically low', 'Weekend preparation time'],
        'impact': 'medium',
        'recommendation': 'Suggest Monday 10 AM instead',
        'confidence': 85,
      },
      {
        'id': 2,
        'title': 'Accept new project proposal?',
        'description': 'New project would add 10 hours/week to your schedule.',
        'pros': ['Good for career growth', 'High budget', 'Interesting tech stack'],
        'cons': ['Already at capacity', 'Would need to reduce focus time', 'Overlaps with Q2 goals'],
        'impact': 'high',
        'recommendation': 'Decline or negotiate timeline',
        'confidence': 78,
      },
    ];

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

                // Decision Cards
                ...pendingDecisions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final decision = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),
                    child: _buildDecisionCard(context, isMobile, decision)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms),
                  );
                }),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/decisions'),
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
          'Decision Support',
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
          'AI-powered analysis for better decisions',
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

  Map<String, dynamic> _getImpactStyle(String impact) {
    switch (impact) {
      case 'high':
        return {
          'bg': [
            const Color(0xFFFF0000).withOpacity(0.2),
            const Color(0xFFFF9800).withOpacity(0.2),
          ],
          'border': const Color(0xFFFF0000).withOpacity(0.3),
          'text': const Color(0xFFFF6B6B),
        };
      case 'medium':
        return {
          'bg': [
            const Color(0xFFF59E0B).withOpacity(0.2),
            const Color(0xFFEAB308).withOpacity(0.2),
          ],
          'border': const Color(0xFFF59E0B).withOpacity(0.3),
          'text': const Color(0xFFFCD34D),
        };
      case 'low':
        return {
          'bg': [
            AppColors.cyan500.withOpacity(0.2),
            AppColors.blue500.withOpacity(0.2),
          ],
          'border': AppColors.cyan500.withOpacity(0.3),
          'text': AppColors.cyan400,
        };
      default:
        return {
          'bg': [
            AppColors.cyan500.withOpacity(0.2),
            AppColors.blue500.withOpacity(0.2),
          ],
          'border': AppColors.cyan500.withOpacity(0.3),
          'text': AppColors.cyan400,
        };
    }
  }

  Widget _buildDecisionCard(BuildContext context, bool isMobile, Map<String, dynamic> decision) {
    final impactStyle = _getImpactStyle(decision['impact'] as String);
    final pros = decision['pros'] as List<String>;
    final cons = decision['cons'] as List<String>;
    final confidence = decision['confidence'] as int;

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 18.0,
        tablet: 20.0,
        desktop: 24.0,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Impact Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          decision['title'] as String,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 16.0,
                              tablet: 17.0,
                              desktop: 18.0,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        )),
                        Text(
                          decision['description'] as String,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                            color: AppColors.textCyan200.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  )),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      ),
                      vertical: Responsive.getResponsiveValue(
                        context,
                        mobile: 4.0,
                        tablet: 5.0,
                        desktop: 6.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: impactStyle['bg'] as List<Color>,
                      ),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 9.0,
                        desktop: 10.0,
                      )),
                      border: Border.all(
                        color: impactStyle['border'] as Color,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      (decision['impact'] as String).toUpperCase(),
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 11.0,
                          desktop: 12.0,
                        ),
                        fontWeight: FontWeight.w500,
                        color: impactStyle['text'] as Color,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              )),

              // Pros and Cons Grid
              Row(
                children: [
                  Expanded(
                    child: _buildProsConsSection(
                      context,
                      isMobile,
                      title: 'Pros',
                      items: pros,
                      isPros: true,
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  )),
                  Expanded(
                    child: _buildProsConsSection(
                      context,
                      isMobile,
                      title: 'Cons',
                      items: cons,
                      isPros: false,
                    ),
                  ),
                ],
              ),

              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              )),

              // AVA's Recommendation
              Container(
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 20.0,
                )),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 13.0,
                    desktop: 14.0,
                  )),
                  border: Border.all(
                    color: const Color(0xFF9333EA).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
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
                        color: const Color(0xFF9333EA).withOpacity(0.2),
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
                        color: const Color(0xFFC084FC),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  'AVA\'s Recommendation',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 13.0,
                                      tablet: 14.0,
                                      desktop: 15.0,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFC084FC),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: Responsive.getResponsiveValue(
                                context,
                                mobile: 8.0,
                                tablet: 10.0,
                                desktop: 12.0,
                              )),
                              Text(
                                '$confidence% confident',
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 11.0,
                                    tablet: 12.0,
                                    desktop: 13.0,
                                  ),
                                  color: const Color(0xFFC084FC),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                            decision['recommendation'] as String,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 12.0,
                                tablet: 13.0,
                                desktop: 14.0,
                              ),
                              color: const Color(0xFFC084FC).withOpacity(0.8),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              )),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Handle follow recommendation
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withOpacity(0.3),
                              AppColors.cyan500.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          )),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.checkCircle,
                              size: Responsive.getResponsiveValue(
                                context,
                                mobile: 14.0,
                                tablet: 16.0,
                                desktop: 18.0,
                              ),
                              color: const Color(0xFF6EE7B7),
                            ),
                            SizedBox(width: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 10.0,
                            )),
                            Flexible(
                              child: Text(
                                'Follow Recommendation',
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 13.0,
                                    tablet: 14.0,
                                    desktop: 15.0,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6EE7B7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  )),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Handle decide later
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          )),
                          border: Border.all(
                            color: AppColors.textWhite.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Decide Later',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                              fontWeight: FontWeight.w500,
                              color: AppColors.cyan400.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }

  Widget _buildProsConsSection(
    BuildContext context,
    bool isMobile, {
    required String title,
    required List<String> items,
    required bool isPros,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 14.0,
        tablet: 16.0,
        desktop: 20.0,
      )),
      decoration: BoxDecoration(
        color: isPros
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFFF0000).withOpacity(0.1),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 13.0,
          desktop: 14.0,
        )),
        border: Border.all(
          color: isPros
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFFF0000).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPros ? LucideIcons.thumbsUp : LucideIcons.thumbsDown,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
                color: isPros ? const Color(0xFF10B981) : const Color(0xFFFF6B6B),
              ),
              SizedBox(width: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              )),
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 13.0,
                    tablet: 14.0,
                    desktop: 15.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: isPros ? const Color(0xFF10B981) : const Color(0xFFFF6B6B),
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
          ...items.map((item) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: Responsive.getResponsiveValue(
                  context,
                  mobile: 6.0,
                  tablet: 8.0,
                  desktop: 10.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      color: isPros ? const Color(0xFF10B981) : const Color(0xFFFF6B6B),
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  )),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 11.0,
                          tablet: 12.0,
                          desktop: 13.0,
                        ),
                        color: isPros
                            ? const Color(0xFF6EE7B7).withOpacity(0.7)
                            : const Color(0xFFFFB3B3).withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
