import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

enum TravelMode { car, train, plane, taxi }
enum JourneyStatus { upcoming, completed }

class Journey {
  final int id;
  final String from;
  final String to;
  final String time;
  final String duration;
  final TravelMode mode;
  final JourneyStatus status;
  final String? traffic;
  final String? aiInsight;

  Journey({
    required this.id,
    required this.from,
    required this.to,
    required this.time,
    required this.duration,
    required this.mode,
    required this.status,
    this.traffic,
    this.aiInsight,
  });
}

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  TravelMode? _selectedMode;

  final List<Journey> _journeys = [
    Journey(
      id: 1,
      from: 'Home',
      to: 'Office',
      time: 'Today, 8:30 AM',
      duration: '25 min',
      mode: TravelMode.car,
      status: JourneyStatus.upcoming,
      traffic: 'Moderate traffic',
      aiInsight: 'Leave 5 minutes earlier than usual',
    ),
    Journey(
      id: 2,
      from: 'Office',
      to: 'Client Meeting',
      time: 'Today, 2:00 PM',
      duration: '15 min',
      mode: TravelMode.taxi,
      status: JourneyStatus.upcoming,
      aiInsight: 'Book Uber 10 minutes before',
    ),
    Journey(
      id: 3,
      from: 'Home',
      to: 'Office',
      time: 'Yesterday, 8:15 AM',
      duration: '20 min',
      mode: TravelMode.car,
      status: JourneyStatus.completed,
      traffic: 'Light traffic',
    ),
    Journey(
      id: 4,
      from: 'Airport',
      to: 'Home',
      time: 'Last week',
      duration: '45 min',
      mode: TravelMode.train,
      status: JourneyStatus.completed,
    ),
  ];

  IconData _getModeIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.car:
      case TravelMode.taxi:
        return LucideIcons.car;
      case TravelMode.train:
        return LucideIcons.train;
      case TravelMode.plane:
        return LucideIcons.plane;
    }
  }

  List<Color> _getModeColors(TravelMode mode) {
    switch (mode) {
      case TravelMode.car:
        return [
          AppColors.blue500.withOpacity(0.2),
          AppColors.cyan500.withOpacity(0.2),
        ];
      case TravelMode.train:
        return [
          const Color(0xFF9333EA).withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ];
      case TravelMode.plane:
        return [
          const Color(0xFFEC4899).withOpacity(0.2),
          const Color(0xFF9333EA).withOpacity(0.2),
        ];
      case TravelMode.taxi:
        return [
          const Color(0xFFFFB800).withOpacity(0.2),
          const Color(0xFFFF9800).withOpacity(0.2),
        ];
    }
  }

  List<Journey> get _filteredJourneys {
    if (_selectedMode == null) {
      return _journeys;
    }
    return _journeys.where((j) => j.mode == _selectedMode).toList();
  }

  List<Journey> get _upcomingJourneys =>
      _filteredJourneys.where((j) => j.status == JourneyStatus.upcoming).toList();

  List<Journey> get _completedJourneys =>
      _filteredJourneys.where((j) => j.status == JourneyStatus.completed).toList();

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

                // Quick Stats
                _buildQuickStats(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Mode Filter
                _buildModeFilter(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Quick Actions
                _buildQuickActions(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Upcoming Journeys
                if (_upcomingJourneys.isNotEmpty)
                  _buildUpcomingSection(context, isMobile),

                // Journey History
                if (_completedJourneys.isNotEmpty)
                  _buildHistorySection(context, isMobile),

                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),

                // Insights Card
                _buildInsightsCard(context, isMobile)
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, delay: 700.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/travel'),
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
          'Travel',
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
          'Your journeys and commutes',
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

  Widget _buildQuickStats(BuildContext context, bool isMobile) {
    final stats = [
      {'label': 'Today', 'value': '2', 'icon': LucideIcons.calendar, 'color': AppColors.cyan400},
      {'label': 'Avg time', 'value': '23m', 'icon': LucideIcons.clock, 'color': AppColors.blue500},
      {'label': 'This week', 'value': '12', 'icon': LucideIcons.trendingUp, 'color': const Color(0xFF9333EA)},
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
              .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms),
        );
      }).toList(),
    );
  }

  Widget _buildModeFilter(BuildContext context, bool isMobile) {
    final filters = [
      {'mode': null, 'icon': LucideIcons.navigation, 'label': 'All'},
      {'mode': TravelMode.car, 'icon': LucideIcons.car, 'label': 'Car'},
      {'mode': TravelMode.taxi, 'icon': LucideIcons.car, 'label': 'Taxi'},
      {'mode': TravelMode.train, 'icon': LucideIcons.train, 'label': 'Train'},
      {'mode': TravelMode.plane, 'icon': LucideIcons.plane, 'label': 'Plane'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final mode = filter['mode'] as TravelMode?;
          final isSelected = _selectedMode == mode;
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
              onTap: () => setState(() => _selectedMode = mode),
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
                      filter['icon'] as IconData,
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
                      filter['label'] as String,
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

  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    final actions = [
      {'label': 'Book Uber', 'icon': LucideIcons.car, 'colors': [const Color(0xFFFFB800).withOpacity(0.2), const Color(0xFFFF9800).withOpacity(0.2)]},
      {'label': 'Check Traffic', 'icon': LucideIcons.navigation, 'colors': [AppColors.cyan500.withOpacity(0.2), AppColors.blue500.withOpacity(0.2)]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        Row(
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < actions.length - 1
                      ? Responsive.getResponsiveValue(
                          context,
                          mobile: 8.0,
                          tablet: 10.0,
                          desktop: 12.0,
                        )
                      : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    // Handle action
                  },
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
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: action['colors'] as List<Color>,
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
                                action['icon'] as IconData,
                                size: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 18.0,
                                  tablet: 20.0,
                                  desktop: 22.0,
                                ),
                                color: AppColors.cyan400,
                              ),
                            ),
                            SizedBox(height: Responsive.getResponsiveValue(
                              context,
                              mobile: 10.0,
                              tablet: 12.0,
                              desktop: 14.0,
                            )),
                            Text(
                              action['label'] as String,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 300 + (index * 100)), duration: 300.ms)
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: Duration(milliseconds: 300 + (index * 100)), duration: 300.ms),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        ..._upcomingJourneys.asMap().entries.map((entry) {
          final index = entry.key;
          final journey = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 16.0,
              ),
            ),
            child: _buildJourneyCard(context, isMobile, journey, index, true),
          );
        }),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 16.0,
              tablet: 18.0,
              desktop: 20.0,
            ),
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        ..._completedJourneys.asMap().entries.map((entry) {
          final index = entry.key;
          final journey = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            child: _buildJourneyCard(context, isMobile, journey, index, false),
          );
        }),
      ],
    );
  }

  Widget _buildJourneyCard(
    BuildContext context,
    bool isMobile,
    Journey journey,
    int index,
    bool isUpcoming,
  ) {
    final modeColors = _getModeColors(journey.mode);
    final modeIcon = _getModeIcon(journey.mode);

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: isUpcoming ? 14.0 : 10.0,
        tablet: isUpcoming ? 16.0 : 12.0,
        desktop: isUpcoming ? 20.0 : 14.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(isUpcoming ? 0.4 : 0.2),
            const Color(0xFF16384d).withOpacity(isUpcoming ? 0.4 : 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: isUpcoming ? 16.0 : 12.0,
          tablet: isUpcoming ? 18.0 : 13.0,
          desktop: isUpcoming ? 20.0 : 14.0,
        )),
        border: Border.all(
          color: AppColors.cyan500.withOpacity(isUpcoming ? 0.1 : 0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: isUpcoming ? 16.0 : 12.0,
          tablet: isUpcoming ? 18.0 : 13.0,
          desktop: isUpcoming ? 20.0 : 14.0,
        )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: isUpcoming ? 36.0 : 28.0,
                      tablet: isUpcoming ? 40.0 : 32.0,
                      desktop: isUpcoming ? 44.0 : 36.0,
                    ),
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: isUpcoming ? 36.0 : 28.0,
                      tablet: isUpcoming ? 40.0 : 32.0,
                      desktop: isUpcoming ? 44.0 : 36.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: modeColors,
                      ),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: isUpcoming ? 10.0 : 8.0,
                        tablet: isUpcoming ? 11.0 : 9.0,
                        desktop: isUpcoming ? 12.0 : 10.0,
                      )),
                      border: Border.all(
                        color: AppColors.cyan500.withOpacity(isUpcoming ? 0.2 : 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      modeIcon,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: isUpcoming ? 18.0 : 14.0,
                        tablet: isUpcoming ? 20.0 : 16.0,
                        desktop: isUpcoming ? 22.0 : 18.0,
                      ),
                      color: AppColors.cyan400,
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 8.0,
                    tablet: 10.0,
                    desktop: 12.0,
                  )),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${journey.from} → ${journey.to}',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: isUpcoming ? 14.0 : 13.0,
                              tablet: isUpcoming ? 15.0 : 14.0,
                              desktop: isUpcoming ? 16.0 : 15.0,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite.withOpacity(isUpcoming ? 1.0 : 0.7),
                          ),
                        ),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 3.0,
                          tablet: 4.0,
                          desktop: 5.0,
                        )),
                        Text(
                          journey.time,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 13.0,
                            ),
                            color: AppColors.cyan400.withOpacity(isUpcoming ? 0.6 : 0.4),
                          ),
                        ),
                        if (isUpcoming) ...[
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 6.0,
                            tablet: 8.0,
                            desktop: 10.0,
                          )),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 13.0,
                                  tablet: 14.0,
                                  desktop: 15.0,
                                ),
                                color: AppColors.cyan400.withOpacity(0.7),
                              ),
                              SizedBox(width: Responsive.getResponsiveValue(
                                context,
                                mobile: 4.0,
                                tablet: 5.0,
                                desktop: 6.0,
                              )),
                              Text(
                                journey.duration,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 11.0,
                                    tablet: 12.0,
                                    desktop: 13.0,
                                  ),
                                  color: AppColors.textCyan200.withOpacity(0.6),
                                ),
                              ),
                              if (journey.traffic != null) ...[
                                SizedBox(width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                )),
                                Icon(
                                  LucideIcons.navigation,
                                  size: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 13.0,
                                    tablet: 14.0,
                                    desktop: 15.0,
                                  ),
                                  color: const Color(0xFFFFB800).withOpacity(0.7),
                                ),
                                SizedBox(width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                )),
                                Text(
                                  journey.traffic!,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 11.0,
                                      tablet: 12.0,
                                      desktop: 13.0,
                                    ),
                                    color: const Color(0xFFFFD93D).withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isUpcoming)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          journey.duration,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 13.0,
                            ),
                            color: AppColors.cyan400.withOpacity(0.6),
                          ),
                        ),
                        if (journey.traffic != null)
                          Text(
                            journey.traffic!,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 11.0,
                                desktop: 12.0,
                              ),
                              color: AppColors.cyan400.withOpacity(0.4),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              // AI Insight
              if (isUpcoming && journey.aiInsight != null) ...[
                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                )),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.zap,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        color: AppColors.cyan400,
                      ),
                      SizedBox(width: Responsive.getResponsiveValue(
                        context,
                        mobile: 6.0,
                        tablet: 8.0,
                        desktop: 10.0,
                      )),
                      Expanded(
                        child: Text(
                          journey.aiInsight!,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 13.0,
                            ),
                            color: AppColors.cyan400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 400 + (index * 100)), duration: 300.ms)
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 400 + (index * 100)), duration: 300.ms);
  }

  Widget _buildInsightsCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 18.0,
        tablet: 20.0,
        desktop: 24.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9333EA).withOpacity(0.1),
            AppColors.blue500.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.2),
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
                  LucideIcons.trendingUp,
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
                    Text(
                      'Weekly Insight',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                        fontWeight: FontWeight.w600,
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
                      'You typically commute at 8:30 AM. Traffic is usually lighter 15 minutes earlier.',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                        color: const Color(0xFFC084FC).withOpacity(0.7),
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
}
