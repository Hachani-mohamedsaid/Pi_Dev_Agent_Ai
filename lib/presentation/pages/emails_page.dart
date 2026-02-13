import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../widgets/navigation_bar.dart';

enum EmailPriority { action, info, wait }

class Email {
  final int id;
  final String sender;
  final String subject;
  final String summary;
  final EmailPriority priority;
  final String time;

  Email({
    required this.id,
    required this.sender,
    required this.subject,
    required this.summary,
    required this.priority,
    required this.time,
  });
}

class EmailsPage extends StatefulWidget {
  const EmailsPage({super.key});

  @override
  State<EmailsPage> createState() => _EmailsPageState();
}

class _EmailsPageState extends State<EmailsPage> {
  Email? _selectedEmail;
  List<Email> _emails = [];
  bool _loading = true;
  bool _refreshing = false;
  bool _generatingReply = false;
  List<String>? _replyOptions;
  bool _showReplyModal = false;
  Email? _replyEmail;

  static List<Email> _mockEmails() => [
    Email(
      id: 1,
      sender: 'Sarah Johnson',
      subject: 'Updated deadline for Q1 report',
      summary: 'This email requires a response regarding the updated deadline.',
      priority: EmailPriority.action,
      time: '2 hours ago',
    ),
    Email(
      id: 2,
      sender: 'HR Department',
      subject: 'Benefits enrollment reminder',
      summary: 'Action needed: Complete your benefits enrollment by Friday.',
      priority: EmailPriority.action,
      time: '3 hours ago',
    ),
    Email(
      id: 3,
      sender: 'Marketing Team',
      subject: 'Weekly newsletter',
      summary: 'Informational update on this week\'s marketing activities.',
      priority: EmailPriority.info,
      time: '5 hours ago',
    ),
    Email(
      id: 4,
      sender: 'John Smith',
      subject: 'Meeting notes from yesterday',
      summary: 'FYI: Summary of action items from yesterday\'s team meeting.',
      priority: EmailPriority.wait,
      time: '1 day ago',
    ),
    Email(
      id: 5,
      sender: 'IT Support',
      subject: 'System maintenance scheduled',
      summary: 'Scheduled maintenance this weekend, no action required now.',
      priority: EmailPriority.wait,
      time: '2 days ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    loadEmails();
  }

  Future<void> loadEmails() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _emails = _mockEmails();
        _loading = false;
      });
    }
  }

  Future<void> handleRefresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _emails = _mockEmails();
        _refreshing = false;
      });
    }
  }

  Future<void> handleDraftReply() async {
    if (_selectedEmail == null) return;
    setState(() => _generatingReply = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final options = [
      'Thanks for the update. I\'ll have the report ready by end of day Friday.',
      'I need a short extension until Monday — can we push the deadline?',
      'Acknowledged. I\'ll confirm once the draft is submitted.',
    ];
    setState(() {
      _replyOptions = options;
      _showReplyModal = true;
      _replyEmail = _selectedEmail;
      _selectedEmail = null;
      _generatingReply = false;
    });
  }

  Map<String, dynamic> _getPriorityBadge(EmailPriority priority) {
    switch (priority) {
      case EmailPriority.action:
        return {
          'text': 'Requires action',
          'bg': const Color(0xFFFF0000).withOpacity(0.1),
          'border': const Color(0xFFFF0000).withOpacity(0.2),
          'color': const Color(0xFFFF6B6B),
          'icon': LucideIcons.alertCircle,
        };
      case EmailPriority.info:
        return {
          'text': 'Informational',
          'bg': AppColors.blue500.withOpacity(0.1),
          'border': AppColors.blue500.withOpacity(0.2),
          'color': AppColors.blue500,
          'icon': LucideIcons.mail,
        };
      case EmailPriority.wait:
        return {
          'text': 'Can wait',
          'bg': AppColors.cyan500.withOpacity(0.1),
          'border': AppColors.cyan500.withOpacity(0.2),
          'color': AppColors.cyan400,
          'icon': LucideIcons.clock,
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

                    // Loading / Empty / Email List
                    if (_loading)
                      _buildLoadingState(context, isMobile)
                    else if (_emails.isEmpty)
                      _buildEmptyState(context, isMobile)
                    else
                      _buildEmailList(context, isMobile),
                  ],
                ),
              ),
              // Email Detail Modal
              if (_selectedEmail != null)
                _buildEmailDetailModal(context, isMobile),
              // Reply Modal
              if (_showReplyModal) _buildReplyModal(context, isMobile),
              
              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/emails'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emails',
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
              'AI-powered inbox summary',
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
        ),
        GestureDetector(
          onTap: (_loading || _refreshing) ? null : () => handleRefresh(),
          child: Container(
            padding: EdgeInsets.all(Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            )),
            decoration: BoxDecoration(
              color: AppColors.cyan500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              )),
              border: Border.all(
                color: AppColors.cyan500.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: _refreshing
                ? SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 20.0,
                      tablet: 22.0,
                      desktop: 24.0,
                    ),
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: 20.0,
                      tablet: 22.0,
                      desktop: 24.0,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cyan400,
                    ),
                  )
                : Icon(
                    LucideIcons.refreshCw,
                    size: Responsive.getResponsiveValue(
                      context,
                      mobile: 20.0,
                      tablet: 22.0,
                      desktop: 24.0,
                    ),
                    color: AppColors.cyan400,
                  ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(delay: 100.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.getResponsiveValue(
          context,
          mobile: 80.0,
          tablet: 100.0,
          desktop: 120.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: Responsive.getResponsiveValue(
              context,
              mobile: 32.0,
              tablet: 36.0,
              desktop: 40.0,
            ),
            height: Responsive.getResponsiveValue(
              context,
              mobile: 32.0,
              tablet: 36.0,
              desktop: 40.0,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.cyan400,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 300.ms),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          )),
          Text(
            'Loading emails...',
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.getResponsiveValue(
          context,
          mobile: 80.0,
          tablet: 100.0,
          desktop: 120.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.mail,
            size: Responsive.getResponsiveValue(
              context,
              mobile: 48.0,
              tablet: 52.0,
              desktop: 56.0,
            ),
            color: AppColors.cyan400.withOpacity(0.3),
          ),
          SizedBox(height: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          )),
          Text(
            'No emails found',
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
      ),
    );
  }

  Widget _buildEmailList(BuildContext context, bool isMobile) {
    return Column(
      children: _emails.asMap().entries.map((entry) {
        final index = entry.key;
        final email = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildEmailCard(context, isMobile, email, index),
        );
      }).toList(),
    );
  }

  Widget _buildEmailCard(
    BuildContext context,
    bool isMobile,
    Email email,
    int index,
  ) {
    final badge = _getPriorityBadge(email.priority);

    return GestureDetector(
      onTap: () => setState(() => _selectedEmail = email),
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
                // Email Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.sender,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 3.0,
                            tablet: 4.0,
                            desktop: 5.0,
                          )),
                          Text(
                            email.time,
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
                        ],
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
                        color: badge['bg'] as Color,
                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        )),
                        border: Border.all(
                          color: badge['border'] as Color,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            badge['icon'] as IconData,
                            size: Responsive.getResponsiveValue(
                              context,
                              mobile: 13.0,
                              tablet: 14.0,
                              desktop: 15.0,
                            ),
                            color: badge['color'] as Color,
                          ),
                          SizedBox(width: Responsive.getResponsiveValue(
                            context,
                            mobile: 4.0,
                            tablet: 5.0,
                            desktop: 6.0,
                          )),
                          Text(
                            badge['text'] as String,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 11.0,
                                desktop: 12.0,
                              ),
                              fontWeight: FontWeight.w500,
                              color: badge['color'] as Color,
                            ),
                          ),
                        ],
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
                // Email Content
                Text(
                  email.subject,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 13.0,
                      tablet: 14.0,
                      desktop: 15.0,
                    ),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textWhite.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.getResponsiveValue(
                  context,
                  mobile: 4.0,
                  tablet: 5.0,
                  desktop: 6.0,
                )),
                Text(
                  email.summary,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(
                      context,
                      mobile: 11.0,
                      tablet: 12.0,
                      desktop: 13.0,
                    ),
                    color: AppColors.textCyan200.withOpacity(0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildEmailDetailModal(BuildContext context, bool isMobile) {
    if (_selectedEmail == null) return const SizedBox.shrink();

    final badge = _getPriorityBadge(_selectedEmail!.priority);

    return GestureDetector(
      onTap: () => setState(() => _selectedEmail = null),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping modal content
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 22.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a3a52),
                      Color(0xFF0f2940),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 26.0,
                      desktop: 28.0,
                    )),
                    topRight: Radius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 26.0,
                      desktop: 28.0,
                    )),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.cyan500.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedEmail!.sender,
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
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                )),
                                Text(
                                  _selectedEmail!.time,
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
                              ],
                            ),
                          ),
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
                                mobile: 5.0,
                                tablet: 6.0,
                                desktop: 7.0,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: badge['bg'] as Color,
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                context,
                                mobile: 8.0,
                                tablet: 9.0,
                                desktop: 10.0,
                              )),
                              border: Border.all(
                                color: badge['border'] as Color,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  badge['icon'] as IconData,
                                  size: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                  color: badge['color'] as Color,
                                ),
                                SizedBox(width: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                )),
                                Text(
                                  badge['text'] as String,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 11.0,
                                      tablet: 12.0,
                                      desktop: 13.0,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    color: badge['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      Text(
                        _selectedEmail!.subject,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 15.0,
                            tablet: 16.0,
                            desktop: 17.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWhite.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      )),
                      // AI Summary
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
                                LucideIcons.mail,
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
                                    'Summary',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 13.0,
                                        tablet: 14.0,
                                        desktop: 15.0,
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
                                    _selectedEmail!.summary,
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      )),
                      // Actions
                      Column(
                        children: [
                          _buildDraftReplyButton(context, isMobile),
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 6.0,
                            tablet: 8.0,
                            desktop: 10.0,
                          )),
                          _buildActionButton(
                            context,
                            isMobile,
                            'Remind me later',
                            false,
                            LucideIcons.clock,
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
                            'Ignore',
                            false,
                            LucideIcons.x,
                            isSecondary: true,
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
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 1.0, end: 0.0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildDraftReplyButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: _generatingReply ? null : () => handleDraftReply(),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cyan500,
              AppColors.cyan400,
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          )),
          border: Border.all(
            color: AppColors.cyan500.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
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
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_generatingReply)
              SizedBox(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textWhite,
                ),
              )
            else
              Icon(
                LucideIcons.check,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
                color: AppColors.textWhite,
              ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            )),
            Text(
              _generatingReply ? 'Generating...' : 'Draft reply',
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
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isMobile,
    String label,
    bool isPrimary,
    IconData icon, {
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: () {
        // Handle action
        if (label == 'Ignore') {
          setState(() => _selectedEmail = null);
        }
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
          color: isPrimary ? null : (isSecondary ? AppColors.textWhite.withOpacity(0.05) : AppColors.cyan500.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          )),
          border: Border.all(
            color: isPrimary
                ? AppColors.cyan500.withOpacity(0.3)
                : (isSecondary ? AppColors.textWhite.withOpacity(0.1) : AppColors.cyan500.withOpacity(0.2)),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
              color: isPrimary
                  ? AppColors.textWhite
                  : (isSecondary ? AppColors.cyan400.withOpacity(0.7) : AppColors.textCyan300),
            ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            )),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 13.0,
                  tablet: 14.0,
                  desktop: 15.0,
                ),
                fontWeight: FontWeight.w500,
                color: isPrimary
                    ? AppColors.textWhite
                    : (isSecondary ? AppColors.cyan400.withOpacity(0.7) : AppColors.textCyan300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyModal(BuildContext context, bool isMobile) {
    final email = _replyEmail;
    if (email == null) return const SizedBox.shrink();

    final badge = _getPriorityBadge(email.priority);
    final hasOptions = _replyOptions != null && _replyOptions!.isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() {
        _showReplyModal = false;
        _replyOptions = null;
        _replyEmail = null;
      }),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: EdgeInsets.all(Responsive.getResponsiveValue(
                  context,
                  mobile: 22.0,
                  tablet: 24.0,
                  desktop: 28.0,
                )),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a3a52),
                      Color(0xFF0f2940),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 26.0,
                      desktop: 28.0,
                    )),
                    topRight: Radius.circular(Responsive.getResponsiveValue(
                      context,
                      mobile: 24.0,
                      tablet: 26.0,
                      desktop: 28.0,
                    )),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.cyan500.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email.sender,
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
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                )),
                                Text(
                                  email.time,
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
                              ],
                            ),
                          ),
                          _buildBadgeChip(context, isMobile, badge),
                        ],
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      Text(
                        email.subject,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 15.0,
                            tablet: 16.0,
                            desktop: 17.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWhite.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      )),
                      // AI Summary
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
                                LucideIcons.mail,
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
                                    'Summary',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 13.0,
                                        tablet: 14.0,
                                        desktop: 15.0,
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
                                    email.summary,
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      )),
                      // Reply Options
                      if (hasOptions)
                        ...(_replyOptions!.map((reply) {
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
                              onTap: () {
                                // Use reply (e.g. send or copy)
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                  vertical: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
                                  ),
                                ),
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
                                      LucideIcons.send,
                                      size: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 16.0,
                                        tablet: 18.0,
                                        desktop: 20.0,
                                      ),
                                      color: AppColors.textCyan300,
                                    ),
                                    SizedBox(width: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 8.0,
                                      tablet: 10.0,
                                      desktop: 12.0,
                                    )),
                                    Expanded(
                                      child: Text(
                                        reply,
                                        style: TextStyle(
                                          fontSize: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 13.0,
                                            tablet: 14.0,
                                            desktop: 15.0,
                                          ),
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textCyan300,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }))
                      else
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.getResponsiveValue(
                            context,
                            mobile: 14.0,
                            tablet: 16.0,
                            desktop: 20.0,
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
                          child: Text(
                            'No reply options available at this time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 13.0,
                                tablet: 14.0,
                                desktop: 15.0,
                              ),
                              color: const Color(0xFFFFB800),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 1.0, end: 0.0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildBadgeChip(
    BuildContext context,
    bool isMobile,
    Map<String, dynamic> badge,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        ),
        vertical: Responsive.getResponsiveValue(
          context,
          mobile: 5.0,
          tablet: 6.0,
          desktop: 7.0,
        ),
      ),
      decoration: BoxDecoration(
        color: badge['bg'] as Color,
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 8.0,
          tablet: 9.0,
          desktop: 10.0,
        )),
        border: Border.all(
          color: badge['border'] as Color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badge['icon'] as IconData,
            size: Responsive.getResponsiveValue(
              context,
              mobile: 14.0,
              tablet: 16.0,
              desktop: 18.0,
            ),
            color: badge['color'] as Color,
          ),
          SizedBox(width: Responsive.getResponsiveValue(
            context,
            mobile: 4.0,
            tablet: 5.0,
            desktop: 6.0,
          )),
          Text(
            badge['text'] as String,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 11.0,
                tablet: 12.0,
                desktop: 13.0,
              ),
              fontWeight: FontWeight.w500,
              color: badge['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }
}
