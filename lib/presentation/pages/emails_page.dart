import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/n8n_email_service.dart';
import '../widgets/navigation_bar.dart';

enum EmailPriority { action, info, wait }

class Email {
  final int id;
  final String sender;
  final String subject;
  final String summary;
  final EmailPriority priority;
  final String time;
  // NEW: optional fields from n8n email payload
  final String? emailId;
  final String? emailBody;
  final String? messageId;
  final String? threadId;
  final String? timestamp;
  final String? status;
  final String? actionItems;
  final String? deadline;

  Email({
    required this.id,
    required this.sender,
    required this.subject,
    required this.summary,
    required this.priority,
    required this.time,
    this.emailId,
    this.emailBody,
    this.messageId,
    this.threadId,
    this.timestamp,
    this.status,
    this.actionItems,
    this.deadline,
  });

  /// NEW: Parse n8n webhook email payload into Email model.
  factory Email.fromJson(Map<String, dynamic> json) {
    EmailPriority priority = EmailPriority.info;
    if (json['priority'] == 'High') priority = EmailPriority.action;
    if (json['priority'] == 'Low') priority = EmailPriority.wait;

    return Email(
      id: (json['emailId'] as String?)?.hashCode ?? 0,
      sender: json['emailFrom'] ?? 'Unknown',
      subject: json['emailSubject'] ?? 'No subject',
      summary: json['emailSummary'] ?? '',
      priority: priority,
      time: _formatTimestamp(json['timestamp'] as String?),
      emailId: json['emailId'] as String?,
      emailBody: json['emailBody'] as String?,
      messageId: json['messageId'] as String?,
      threadId: json['threadId'] as String?,
      timestamp: json['timestamp'] as String?,
      status: json['status'] as String?,
      actionItems: json['actionItems'] as String?,
      deadline: json['deadline'] as String?,
    );
  }

  static String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Unknown';
    }
  }
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
  // NEW: n8n reply options are list of maps { id, type, subject, body, tone }
  List<Map<String, dynamic>>? _replyOptions;
  bool _showReplyModal = false;
  Email? _replyEmail;
  // NEW: n8n integration state
  String? _errorMessage;
  bool _isSendingReply = false;
  final _emailService = N8nEmailService();
  // NEW: confirm-send modal state
  bool _showConfirmSendModal = false;
  String _confirmSubject = '';
  String _confirmBody = '';

  // KEEP AS COMMENTED BACKUP – static list for fallback/reference (do not delete)
  // static List<Email> _mockEmails() => [
  //   Email(id: 1, sender: 'Sarah Johnson', subject: 'Updated deadline for Q1 report',
  //     summary: 'This email requires a response regarding the updated deadline.',
  //     priority: EmailPriority.action, time: '2 hours ago'),
  //   Email(id: 2, sender: 'HR Department', subject: 'Benefits enrollment reminder',
  //     summary: 'Action needed: Complete your benefits enrollment by Friday.',
  //     priority: EmailPriority.action, time: '3 hours ago'),
  //   Email(id: 3, sender: 'Marketing Team', subject: 'Weekly newsletter',
  //     summary: 'Informational update on this week\'s marketing activities.',
  //     priority: EmailPriority.info, time: '5 hours ago'),
  //   Email(id: 4, sender: 'John Smith', subject: 'Meeting notes from yesterday',
  //     summary: 'FYI: Summary of action items from yesterday\'s team meeting.',
  //     priority: EmailPriority.wait, time: '1 day ago'),
  //   Email(id: 5, sender: 'IT Support', subject: 'System maintenance scheduled',
  //     summary: 'Scheduled maintenance this weekend, no action required now.',
  //     priority: EmailPriority.wait, time: '2 days ago'),
  // ];

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  /// NEW: Load emails from n8n webhook (GET email-summaries). Keeps existing UI/styling.
  Future<void> _loadEmails() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final emailsData = await _emailService.fetchEmails();
      print('📧 Received emailsData count: ${emailsData.length}');
      if (!mounted) return;
      setState(() {
        _emails = (emailsData as List).map((e) {
          try {
            return Email.fromJson(Map<String, dynamic>.from(e as Map));
          } catch (error) {
            print('❌ Error parsing email: $error');
            print('   Raw email data: $e');
            return null;
          }
        }).whereType<Email>().toList();

        print('✅ Successfully parsed ${_emails.length} emails');

        // Sort: active first, replied last
        _emails.sort((a, b) {
          if (a.status == 'replied' && b.status != 'replied') return 1;
          if (a.status != 'replied' && b.status == 'replied') return -1;
          return 0;
        });
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> loadEmails() async {
    await _loadEmails();
  }

  Future<void> handleRefresh() async {
    setState(() => _refreshing = true);
    await _loadEmails();
    if (mounted) setState(() => _refreshing = false);
  }

  /// NEW: Draft reply via n8n generate-reply webhook. Opens reply options modal.
  Future<void> handleDraftReply() async {
    if (_selectedEmail == null || _selectedEmail!.emailId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email cannot be replied to (no emailId).')),
        );
      }
      return;
    }
    setState(() => _generatingReply = true);
    try {
      final response = await _emailService.generateReply(
        _selectedEmail!.emailId!,
        'professional',
        'polite',
      );
      if (!mounted) return;
      final options = response['replyOptions'] as List<dynamic>?;
      setState(() {
        _replyOptions = options
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _replyEmail = _selectedEmail;
        _selectedEmail = null;
        _generatingReply = false;
      });
      setState(() => _showReplyModal = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _generatingReply = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate replies: $e')),
      );
    }
  }

  /// NEW: Open confirm-send modal (To, subject, body, Send Reply / Cancel).
  void _openConfirmSendModal(String subject, String body) {
    setState(() {
      _showConfirmSendModal = true;
      _confirmSubject = subject;
      _confirmBody = body;
    });
  }

  void _closeConfirmSendModal() {
    setState(() {
      _showConfirmSendModal = false;
      _confirmSubject = '';
      _confirmBody = '';
    });
  }

  /// NEW: Send reply via n8n send-reply webhook. Closes modals, shows snackbar, refreshes list.
  Future<void> _handleSendReply(String subject, String body) async {
    if (_replyEmail?.emailId == null) return;
    setState(() => _isSendingReply = true);
    try {
      await _emailService.sendReply(_replyEmail!.emailId!, subject, body);
      if (!mounted) return;
      setState(() {
        _isSendingReply = false;
        _showConfirmSendModal = false;
        _showReplyModal = false;
        _replyOptions = null;
        _replyEmail = null;
        _confirmSubject = '';
        _confirmBody = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent successfully!')),
      );
      _loadEmails();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingReply = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
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

    // Hide nav bar when any modal is open so it doesn't cover the popup
    final bool anyModalOpen =
        _selectedEmail != null || _showReplyModal || _showConfirmSendModal;

    // Same structure as history_page / home_screen: gradient, SafeArea(bottom: false), Stack
    return Scaffold(
      backgroundColor: const Color(0xFF0f2940),
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
          child: SizedBox.expand(
            child: Stack(
              children: [
                // Main content – same bottom padding as other pages for nav bar space
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
                  ), // Space for navigation bar (matches history_page / home_screen)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    if (_loading)
                      _buildLoadingState(context, isMobile)
                    else if (_errorMessage != null)
                      _buildErrorState(context, isMobile)
                    else if (_emails.isEmpty)
                      _buildEmptyState(context, isMobile)
                    else
                      _buildEmailList(context, isMobile),
                  ],
                ),
              ),

              // Modals
              if (_selectedEmail != null)
                _buildEmailDetailModal(context, isMobile),
              if (_showReplyModal) _buildReplyModal(context, isMobile),
              if (_showConfirmSendModal) _buildConfirmSendModal(context, isMobile),

              // Navigation bar – same config as history_page / home_screen (position only when no modal)
              if (!anyModalOpen)
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
          onTap: (_loading || _refreshing) ? null : () => _loadEmails(),
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
    // Center loading indicator in the viewport (account for header + navbar space)
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = Responsive.getResponsiveValue(
      context,
      mobile: 80.0,
      tablet: 90.0,
      desktop: 100.0,
    );
    final navbarHeight = Responsive.getResponsiveValue(
      context,
      mobile: 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );
    // Available height for centering = screen - top padding - header - navbar
    final availableHeight = screenHeight - topPadding - headerHeight - navbarHeight;
    
    return SizedBox(
      height: availableHeight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  /// NEW: Error state when n8n fetch fails (all existing styling kept).
  Widget _buildErrorState(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.getResponsiveValue(
          context,
          mobile: 80.0,
          tablet: 100.0,
          desktop: 120.0,
        ),
      ),
      child: Center(
        child: Text(
          _errorMessage ?? 'Unknown error',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 13.0,
              tablet: 14.0,
              desktop: 15.0,
            ),
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
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
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getResponsiveValue(
                context,
                mobile: 4.0,
                tablet: 6.0,
                desktop: 8.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    height: 1.35,
                  ),
                  maxLines: 6,
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
                      // Reply Options (NEW: n8n replyOptions with type, subject, body, tone)
                      if (hasOptions)
                        ...(_replyOptions!.map((option) {
                          final type = (option['type'] as String?) ?? 'Reply';
                          final typeLabel = type.isEmpty
                              ? 'Reply'
                              : (type.length == 1
                                  ? type.toUpperCase()
                                  : type[0].toUpperCase() + type.substring(1).toLowerCase());
                          final subject = (option['subject'] as String?) ?? '';
                          final body = (option['body'] as String?) ?? '';
                          final bodyPreview = body.length > 150
                              ? '${body.substring(0, 150)}...'
                              : body;
                          final tone = (option['tone'] as String?) ?? '';
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: Responsive.getResponsiveValue(
                                context,
                                mobile: 8.0,
                                tablet: 10.0,
                                desktop: 12.0,
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(Responsive.getResponsiveValue(
                                context,
                                mobile: 14.0,
                                tablet: 16.0,
                                desktop: 18.0,
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
                                      Text(
                                        typeLabel,
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
                                      if (tone.isNotEmpty) ...[
                                        SizedBox(width: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 8.0,
                                          tablet: 10.0,
                                          desktop: 12.0,
                                        )),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Responsive.getResponsiveValue(
                                              context,
                                              mobile: 6.0,
                                              tablet: 8.0,
                                              desktop: 10.0,
                                            ),
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.cyan500.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tone,
                                            style: TextStyle(
                                              fontSize: Responsive.getResponsiveValue(
                                                context,
                                                mobile: 10.0,
                                                tablet: 11.0,
                                                desktop: 12.0,
                                              ),
                                              color: AppColors.cyan400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (subject.isNotEmpty) ...[
                                    SizedBox(height: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 4.0,
                                      tablet: 6.0,
                                      desktop: 8.0,
                                    )),
                                    Text(
                                      subject,
                                      style: TextStyle(
                                        fontSize: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 12.0,
                                          tablet: 13.0,
                                          desktop: 14.0,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textCyan200.withOpacity(0.9),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (bodyPreview.isNotEmpty) ...[
                                    SizedBox(height: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 4.0,
                                      tablet: 6.0,
                                      desktop: 8.0,
                                    )),
                                    Text(
                                      bodyPreview,
                                      style: TextStyle(
                                        fontSize: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 11.0,
                                          tablet: 12.0,
                                          desktop: 13.0,
                                        ),
                                        color: AppColors.textCyan200.withOpacity(0.7),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  SizedBox(height: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 10.0,
                                    tablet: 12.0,
                                    desktop: 14.0,
                                  )),
                                  GestureDetector(
                                    onTap: () =>
                                        _openConfirmSendModal(subject, body),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 8.0,
                                          tablet: 10.0,
                                          desktop: 12.0,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.cyan500.withOpacity(0.3),
                                            AppColors.cyan400.withOpacity(0.3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                          context,
                                          mobile: 10.0,
                                          tablet: 11.0,
                                          desktop: 12.0,
                                        )),
                                        border: Border.all(
                                          color: AppColors.cyan500.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            LucideIcons.send,
                                            size: Responsive.getResponsiveValue(
                                              context,
                                              mobile: 14.0,
                                              tablet: 16.0,
                                              desktop: 18.0,
                                            ),
                                            color: AppColors.textCyan300,
                                          ),
                                          SizedBox(width: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 6.0,
                                            tablet: 8.0,
                                            desktop: 10.0,
                                          )),
                                          Text(
                                            'Use this reply',
                                            style: TextStyle(
                                              fontSize: Responsive.getResponsiveValue(
                                                context,
                                                mobile: 12.0,
                                                tablet: 13.0,
                                                desktop: 14.0,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textCyan300,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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

  /// NEW: Confirm-send modal (To, subject, full body, Send Reply / Cancel). Same style as email modals.
  Widget _buildConfirmSendModal(BuildContext context, bool isMobile) {
    final to = _replyEmail?.sender ?? '';

    return GestureDetector(
      onTap: _closeConfirmSendModal,
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
                      Text(
                        'Send reply',
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
                        mobile: 16.0,
                        tablet: 18.0,
                        desktop: 20.0,
                      )),
                      Text(
                        'To: $to',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 13.0,
                            tablet: 14.0,
                            desktop: 15.0,
                          ),
                          color: AppColors.textCyan200.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 10.0,
                        desktop: 12.0,
                      )),
                      Text(
                        'Subject: $_confirmSubject',
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        padding: EdgeInsets.all(Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
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
                            color: AppColors.cyan500.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _confirmBody,
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 12.0,
                                tablet: 13.0,
                                desktop: 14.0,
                              ),
                              color: AppColors.textCyan200.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 24.0,
                      )),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _closeConfirmSendModal,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
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
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 13.0,
                                        tablet: 14.0,
                                        desktop: 15.0,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textCyan300,
                                    ),
                                  ),
                                ),
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
                            child: GestureDetector(
                              onTap: _isSendingReply
                                  ? null
                                  : () => _handleSendReply(
                                        _confirmSubject,
                                        _confirmBody,
                                      ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
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
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isSendingReply
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textWhite,
                                          ),
                                        )
                                      : Text(
                                          'Send Reply',
                                          style: TextStyle(
                                            fontSize: Responsive.getResponsiveValue(
                                              context,
                                              mobile: 13.0,
                                              tablet: 14.0,
                                              desktop: 15.0,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textWhite,
                                          ),
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
