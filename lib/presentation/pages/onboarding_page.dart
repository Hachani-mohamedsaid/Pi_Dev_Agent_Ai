import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 1;

  // Step 2: Personality
  final List<String> _workStyle = [];
  String? _communicationStyle;
  String? _decisionStyle;

  // Step 3: Daily Routine
  bool? _morningPerson;
  final List<String> _peakHours = [];
  final List<String> _busyDays = [];

  // Step 4: Priorities
  final List<String> _priorities = [];

  // Step 5: Learning Consent
  bool _learningConsent = false;
  String _automationLevel = 'suggest';

  void _toggleSelection(String item, List<String> list) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else {
        list.add(item);
      }
    });
  }

  bool _canProceed() {
    switch (_step) {
      case 2:
        return _workStyle.isNotEmpty && _communicationStyle != null && _decisionStyle != null;
      case 3:
        return _morningPerson != null && _peakHours.isNotEmpty;
      case 4:
        return _priorities.isNotEmpty;
      case 5:
        return _learningConsent;
      default:
        return true;
    }
  }

  Future<void> _handleComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ava_onboarding_complete', true);
    if (mounted) {
      context.go('/home');
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
          child: Column(
            children: [
              // Progress Bar
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    Container(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 6.0,
                        tablet: 7.0,
                        desktop: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 3.0,
                          tablet: 3.5,
                          desktop: 4.0,
                        )),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        ),
                        width: MediaQuery.of(context).size.width * (_step / 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cyan500,
                              AppColors.blue500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                            context,
                            mobile: 3.0,
                            tablet: 3.5,
                            desktop: 4.0,
                          )),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    )),
                    Text(
                      'Step $_step of 6',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                        color: AppColors.cyan400.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildStepContent(context, isMobile),
                ),
              ),

              // Navigation Buttons
              Container(
                padding: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: Responsive.getResponsiveValue(
                    context,
                    mobile: 20.0,
                    tablet: 24.0,
                    desktop: 28.0,
                  ),
                  bottom: padding + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0f2940).withOpacity(0.95),
                      const Color(0xFF0f2940),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    if (_step > 1)
                      GestureDetector(
                        onTap: () => setState(() => _step--),
                        child: Container(
                          padding: EdgeInsets.all(Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 18.0,
                          )),
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
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: Responsive.getResponsiveValue(
                              context,
                              mobile: 18.0,
                              tablet: 20.0,
                              desktop: 22.0,
                            ),
                            color: AppColors.cyan400,
                          ),
                        ),
                      ),
                    if (_step > 1)
                      SizedBox(width: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      )),
                    Expanded(
                      child: GestureDetector(
                        onTap: _canProceed()
                            ? () {
                                if (_step == 6) {
                                  _handleComplete();
                                } else {
                                  setState(() => _step++);
                                }
                              }
                            : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 16.0,
                              desktop: 18.0,
                            ),
                          ),
                          decoration: BoxDecoration(
                            gradient: _canProceed()
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.cyan500,
                                      AppColors.cyan400,
                                    ],
                                  )
                                : null,
                            color: _canProceed() ? null : AppColors.textWhite.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            )),
                            border: Border.all(
                              color: _canProceed()
                                  ? AppColors.cyan500.withOpacity(0.3)
                                  : AppColors.textWhite.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: _canProceed()
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _step == 6 ? "Let's go!" : 'Continue',
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 15.0,
                                    desktop: 16.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: _canProceed() ? AppColors.textWhite : AppColors.cyan400.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(width: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              )),
                              Icon(
                                LucideIcons.chevronRight,
                                size: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 18.0,
                                  tablet: 20.0,
                                  desktop: 22.0,
                                ),
                                color: _canProceed() ? AppColors.textWhite : AppColors.cyan400.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildStepContent(BuildContext context, bool isMobile) {
    switch (_step) {
      case 1:
        return _buildStep1(context, isMobile);
      case 2:
        return _buildStep2(context, isMobile);
      case 3:
        return _buildStep3(context, isMobile);
      case 4:
        return _buildStep4(context, isMobile);
      case 5:
        return _buildStep5(context, isMobile);
      case 6:
        return _buildStep6(context, isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(BuildContext context, bool isMobile) {
    final features = [
      {'icon': LucideIcons.messageSquare, 'text': 'Multimodal: Voice & Text'},
      {'icon': LucideIcons.clock, 'text': 'Manage your time & schedule'},
      {'icon': LucideIcons.target, 'text': 'Learn your preferences'},
      {'icon': LucideIcons.shield, 'text': 'Your data is private & secure'},
    ];

    return Column(
      children: [
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Column(
          children: [
            Container(
              width: Responsive.getResponsiveValue(
                context,
                mobile: 90.0,
                tablet: 100.0,
                desktop: 110.0,
              ),
              height: Responsive.getResponsiveValue(
                context,
                mobile: 90.0,
                tablet: 100.0,
                desktop: 110.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cyan500.withOpacity(0.3),
                    AppColors.blue500.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan400.withOpacity(0.3),
                    blurRadius: Responsive.getResponsiveValue(
                      context,
                      mobile: 20.0,
                      tablet: 30.0,
                      desktop: 40.0,
                    ),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 48.0,
                  tablet: 52.0,
                  desktop: 56.0,
                ),
                color: AppColors.cyan400,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1, 1),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            SizedBox(height: Responsive.getResponsiveValue(
              context,
              mobile: 20.0,
              tablet: 24.0,
              desktop: 28.0,
            )),
            Text(
              'Welcome to AVA',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 32.0,
                  tablet: 36.0,
                  desktop: 40.0,
                ),
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            SizedBox(height: Responsive.getResponsiveValue(
              context,
              mobile: 8.0,
              tablet: 10.0,
              desktop: 12.0,
            )),
            Text(
              'Your Personal Intelligent Multitasking Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                color: AppColors.textCyan200.withOpacity(0.7),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 40.0,
          tablet: 50.0,
          desktop: 60.0,
        )),
        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
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
                  child: Row(
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
                          feature['icon'] as IconData,
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
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      Expanded(
                        child: Text(
                          feature['text'] as String,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 14.0,
                              tablet: 15.0,
                              desktop: 16.0,
                            ),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms)
                .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 100 + (index * 100)), duration: 300.ms),
          );
        }),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 30.0,
          tablet: 40.0,
          desktop: 50.0,
        )),
        Text(
          'Let\'s personalize AVA to work perfectly for you',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 13.0,
              desktop: 14.0,
            ),
            color: AppColors.cyan400.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Text(
          'Tell me about your work style',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
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
          'This helps AVA understand how you work best',
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
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        // Work Style
        Text(
          'How do you prefer to work? (Select all that apply)',
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
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        Wrap(
          spacing: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          runSpacing: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          children: ['Structured', 'Flexible', 'Collaborative', 'Independent', 'Fast-paced', 'Thoughtful']
              .map((style) => _buildSelectableButton(
                    context,
                    isMobile,
                    style,
                    _workStyle.contains(style),
                    () => _toggleSelection(style, _workStyle),
                  ))
              .toList(),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        // Communication Style
        Text(
          'Communication preference',
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
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        ...['Concise & direct', 'Detailed & thorough', 'Casual & friendly'].map((style) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            child: _buildSelectableButton(
              context,
              isMobile,
              style,
              _communicationStyle == style,
              () => setState(() => _communicationStyle = style),
              isFullWidth: true,
            ),
          );
        }),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        // Decision Style
        Text(
          'Decision-making style',
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
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        ...['Quick decisions', 'Analyze options first', 'Ask for input'].map((style) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            child: _buildSelectableButton(
              context,
              isMobile,
              style,
              _decisionStyle == style,
              () => setState(() => _decisionStyle = style),
              isFullWidth: true,
            ),
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

  Widget _buildStep3(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Text(
          'Your daily routine',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
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
          'Help AVA optimize your schedule',
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
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        // Morning/Night Person
        Text(
          'Are you a morning person or night owl?',
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
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        Row(
          children: [
            Expanded(
              child: _buildSelectableButton(
                context,
                isMobile,
                '☀️ Morning Person',
                _morningPerson == true,
                () => setState(() => _morningPerson = true),
              ),
            ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            )),
            Expanded(
              child: _buildSelectableButton(
                context,
                isMobile,
                '🌙 Night Owl',
                _morningPerson == false,
                () => setState(() => _morningPerson = false),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        // Peak Hours
        Text(
          'When are you most productive? (Select all)',
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
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        Wrap(
          spacing: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          runSpacing: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          children: [
            'Early morning (6-9)',
            'Morning (9-12)',
            'Afternoon (12-3)',
            'Late afternoon (3-6)',
            'Evening (6-9)',
            'Night (9-12)',
          ].map((time) => _buildSelectableButton(
                context,
                isMobile,
                time,
                _peakHours.contains(time),
                () => _toggleSelection(time, _peakHours),
                isSmall: true,
              )).toList(),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        // Busy Days
        Text(
          'Typically busy days (Optional)',
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
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        Wrap(
          spacing: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          runSpacing: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => _buildSelectableButton(
                    context,
                    isMobile,
                    day,
                    _busyDays.contains(day),
                    () => _toggleSelection(day, _busyDays),
                  ))
              .toList(),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
      ],
    );
  }

  Widget _buildStep4(BuildContext context, bool isMobile) {
    final priorities = [
      {'emoji': '💼', 'label': 'Work efficiency', 'desc': 'Get more done in less time'},
      {'emoji': '👨‍👩‍👧', 'label': 'Family time', 'desc': 'Protect personal moments'},
      {'emoji': '💪', 'label': 'Health & wellness', 'desc': 'Maintain work-life balance'},
      {'emoji': '📚', 'label': 'Learning & growth', 'desc': 'Time for development'},
      {'emoji': '💰', 'label': 'Financial goals', 'desc': 'Budget and savings'},
      {'emoji': '🎯', 'label': 'Career advancement', 'desc': 'Professional growth'},
      {'emoji': '🧘', 'label': 'Mental health', 'desc': 'Stress management'},
      {'emoji': '🤝', 'label': 'Relationships', 'desc': 'Social connections'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Text(
          'What matters most to you?',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
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
          'AVA will respect your priorities when making suggestions',
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
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        ...priorities.map((priority) {
          final isSelected = _priorities.contains(priority['label'] as String);
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
            ),
            child: GestureDetector(
              onTap: () => _toggleSelection(priority['label'] as String, _priorities),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 20.0,
                )),
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
                  children: [
                    Text(
                      priority['emoji'] as String,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 24.0,
                          tablet: 26.0,
                          desktop: 28.0,
                        ),
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
                            priority['label'] as String,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 14.0,
                                tablet: 15.0,
                                desktop: 16.0,
                              ),
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.textCyan300 : AppColors.textWhite,
                            ),
                          ),
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 3.0,
                            tablet: 4.0,
                            desktop: 5.0,
                          )),
                          Text(
                            priority['desc'] as String,
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
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        LucideIcons.check,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 18.0,
                          tablet: 20.0,
                          desktop: 22.0,
                        ),
                        color: AppColors.cyan400,
                      ),
                  ],
                ),
              ),
            ),
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

  Widget _buildStep5(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Text(
          'How AVA learns from you',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
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
          'Understanding and consent',
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
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        Container(
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
                  Text(
                    'What AVA learns:',
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
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  )),
                  ...[
                    'Your work patterns and preferences',
                    'Communication style and decision-making',
                    'Schedule optimization opportunities',
                    'Context and priorities for suggestions',
                  ].map((item) {
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
                                mobile: 14.0,
                                tablet: 15.0,
                                desktop: 16.0,
                              ),
                              color: AppColors.cyan400,
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
                                  mobile: 12.0,
                                  tablet: 13.0,
                                  desktop: 14.0,
                                ),
                                color: AppColors.textCyan200.withOpacity(0.8),
                              ),
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
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.shield,
                    size: Responsive.getResponsiveValue(
                      context,
                      mobile: 18.0,
                      tablet: 20.0,
                      desktop: 22.0,
                    ),
                    color: AppColors.cyan400,
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  )),
                  Text(
                    'Your Privacy',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 15.0,
                        desktop: 16.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan400,
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
              ...[
                '✓ Data stays on your device',
                '✓ No sharing with third parties',
                '✓ You can delete anytime',
                '✓ Full transparency in AI Activity log',
              ].map((item) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.getResponsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 5.0,
                      desktop: 6.0,
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      color: AppColors.textCyan200.withOpacity(0.7),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        GestureDetector(
          onTap: () => setState(() => _learningConsent = !_learningConsent),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.getResponsiveValue(
              context,
              mobile: 14.0,
              tablet: 16.0,
              desktop: 20.0,
            )),
            decoration: BoxDecoration(
              gradient: _learningConsent
                  ? LinearGradient(
                      colors: [
                        AppColors.cyan500.withOpacity(0.3),
                        AppColors.blue500.withOpacity(0.3),
                      ],
                    )
                  : null,
              color: _learningConsent ? null : AppColors.textWhite.withOpacity(0.05),
              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 13.0,
                desktop: 14.0,
              )),
              border: Border.all(
                color: _learningConsent
                    ? AppColors.cyan500.withOpacity(0.5)
                    : AppColors.textWhite.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: Responsive.getResponsiveValue(
                    context,
                    mobile: 22.0,
                    tablet: 24.0,
                    desktop: 26.0,
                  ),
                  height: Responsive.getResponsiveValue(
                    context,
                    mobile: 22.0,
                    tablet: 24.0,
                    desktop: 26.0,
                  ),
                  decoration: BoxDecoration(
                    color: _learningConsent ? AppColors.cyan500 : Colors.transparent,
                    borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 7.0,
                      desktop: 8.0,
                    )),
                    border: Border.all(
                      color: _learningConsent
                          ? AppColors.cyan500
                          : AppColors.cyan500.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _learningConsent
                      ? Icon(
                          LucideIcons.check,
                          size: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 18.0,
                          ),
                          color: AppColors.textWhite,
                        )
                      : null,
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
                        'I understand and consent',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 15.0,
                            desktop: 16.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: _learningConsent ? AppColors.textCyan300 : AppColors.textWhite,
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 3.0,
                        tablet: 4.0,
                        desktop: 5.0,
                      )),
                      Text(
                        'AVA can learn from my behavior to assist me better',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        // Automation Level
        Text(
          'How much autonomy should AVA have?',
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
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        )),
        ...[
          {'value': 'observe', 'label': 'Observe only', 'desc': 'Just watch and learn'},
          {'value': 'suggest', 'label': 'Make suggestions', 'desc': 'Recommend actions (Default)'},
          {'value': 'act', 'label': 'Act with confirmation', 'desc': 'Take action after approval'},
        ].map((level) {
          final isSelected = _automationLevel == level['value'];
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
            ),
            child: GestureDetector(
              onTap: () => setState(() => _automationLevel = level['value'] as String),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 11.0,
                  tablet: 12.0,
                  desktop: 14.0,
                )),
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
                  children: [
                    Container(
                      width: Responsive.getResponsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 18.0,
                        desktop: 20.0,
                      ),
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 16.0,
                        tablet: 18.0,
                        desktop: 20.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.cyan500 : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyan500
                              : AppColors.cyan500.withOpacity(0.3),
                          width: 2,
                        ),
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
                            level['label'] as String,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.textCyan300 : AppColors.textWhite,
                            ),
                          ),
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 3.0,
                            tablet: 4.0,
                            desktop: 5.0,
                          )),
                          Text(
                            level['desc'] as String,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildStep6(BuildContext context, bool isMobile) {
    final services = [
      {'emoji': '📅', 'name': 'Google Calendar', 'desc': 'Manage your schedule', 'status': 'Ready'},
      {'emoji': '📧', 'name': 'Gmail', 'desc': 'Email management', 'status': 'Ready'},
      {'emoji': '🚗', 'name': 'Uber', 'desc': 'Book rides', 'status': 'Optional'},
      {'emoji': '💬', 'name': 'Slack', 'desc': 'Team communication', 'status': 'Optional'},
      {'emoji': '🍕', 'name': 'Food Delivery', 'desc': 'Order meals', 'status': 'Optional'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Text(
          'Connect your services',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
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
          'Enable AVA to help with your daily tasks',
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
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 24.0,
          tablet: 28.0,
          desktop: 32.0,
        )),
        ...services.asMap().entries.map((entry) {
          final index = entry.key;
          final service = entry.value;
          final isReady = service['status'] == 'Ready';
          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 16.0,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            service['emoji'] as String,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 24.0,
                                tablet: 26.0,
                                desktop: 28.0,
                              ),
                            ),
                          ),
                          SizedBox(width: Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          )),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['name'] as String,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 15.0,
                                    desktop: 16.0,
                                  ),
                                  fontWeight: FontWeight.w500,
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
                                service['desc'] as String,
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
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle connect/skip
                        },
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
                              mobile: 7.0,
                              tablet: 8.0,
                              desktop: 9.0,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: isReady
                                ? AppColors.cyan500.withOpacity(0.2)
                                : AppColors.textWhite.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                              context,
                              mobile: 8.0,
                              tablet: 9.0,
                              desktop: 10.0,
                            )),
                            border: Border.all(
                              color: isReady
                                  ? AppColors.cyan500.withOpacity(0.3)
                                  : AppColors.textWhite.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isReady ? 'Connect' : 'Skip',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 12.0,
                                tablet: 13.0,
                                desktop: 14.0,
                              ),
                              fontWeight: FontWeight.w500,
                              color: isReady
                                  ? AppColors.cyan400
                                  : AppColors.cyan400.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 100), duration: 300.ms)
                .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: index * 100), duration: 300.ms),
          );
        }),
        SizedBox(height: Responsive.getResponsiveValue(
          context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        )),
        Text(
          'You can connect more services later in Settings',
          textAlign: TextAlign.center,
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
    );
  }

  Widget _buildSelectableButton(
    BuildContext context,
    bool isMobile,
    String label,
    bool isSelected,
    VoidCallback onTap, {
    bool isFullWidth = false,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth
            ? double.infinity
            : isSmall
                ? null
                : null,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.getResponsiveValue(
            context,
            mobile: isSmall ? 10.0 : 14.0,
            tablet: isSmall ? 12.0 : 16.0,
            desktop: isSmall ? 14.0 : 18.0,
          ),
          vertical: Responsive.getResponsiveValue(
            context,
            mobile: isSmall ? 9.0 : 11.0,
            tablet: isSmall ? 10.0 : 12.0,
            desktop: isSmall ? 11.0 : 14.0,
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
        child: Text(
          label,
          textAlign: isFullWidth ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: isSmall ? 11.0 : 12.0,
              tablet: isSmall ? 12.0 : 13.0,
              desktop: isSmall ? 13.0 : 14.0,
            ),
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.textCyan300 : AppColors.cyan400.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
