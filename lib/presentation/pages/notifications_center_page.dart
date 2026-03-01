import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/assistant_notification.dart';
import '../../data/services/assistant_service.dart';
import '../../data/services/meeting_service.dart';
import '../../injection_container.dart';
import '../../services/focus_session_manager.dart';
import '../../services/n8n_email_service.dart';
import '../state/auth_controller.dart';
import '../widgets/navigation_bar.dart';

enum NotificationPriority { critical, important, canWait }

enum NotificationCategory { all, work, personal, travel, general }

class UiNotification {
  UiNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.category,
    required this.timeLabel,
    required this.actions,
    this.raw,
  });

  final String id;
  final String title;
  final String message;
  final NotificationPriority priority;
  final NotificationCategory category;
  final String timeLabel;
  final List<AssistantNotificationAction> actions;
  final AssistantNotification? raw;
}

class NotificationsCenterPage extends StatefulWidget {
  const NotificationsCenterPage({super.key});

  @override
  State<NotificationsCenterPage> createState() =>
      _NotificationsCenterPageState();
}

/// Cache so when user closes and reopens Notifications we show last list
/// immediately without waiting for AI generation.
List<UiNotification>? _cachedNotifications;

class _NotificationsCenterPageState extends State<NotificationsCenterPage> {
  late final AssistantService _assistantService = AssistantService(
    authLocalDataSource: InjectionContainer.instance.authLocalDataSource,
  );

  late final AuthController _authController = InjectionContainer.instance
      .buildAuthController();

  NotificationCategory _filter = NotificationCategory.all;
  final Set<String> _dismissedDedupeKeys = {};
  /// Fallback: same mail notif can come back with a different dedupeKey; we hide by title+message.
  final Set<String> _dismissedTitleMessage = {};
  final Set<String> _seenDedupeKeys = {};

  bool _loading = true;
  String? _error;
  List<UiNotification> _notifications = [];

  List<UiNotification> get _activeNotifications => _notifications
      .where((n) {
        if (n.raw != null &&
            n.raw!.dedupeKey.isNotEmpty &&
            _dismissedDedupeKeys.contains(n.raw!.dedupeKey)) {
          return false;
        }
        final key = _titleMessageKey(n.title, n.message);
        if (_dismissedTitleMessage.contains(key)) return false;
        return true;
      })
      .toList();

  List<UiNotification> get _filteredNotifications {
    if (_filter == NotificationCategory.all) {
      return _activeNotifications;
    }
    return _activeNotifications.where((n) => n.category == _filter).toList();
  }

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _loadDismissedFromStorage();
    if (!mounted) return;
    if (_cachedNotifications != null && _cachedNotifications!.isNotEmpty) {
      setState(() {
        _notifications = List.from(_cachedNotifications!);
        _loading = false;
      });
    }
    await _loadNotifications(showSpinner: _notifications.isEmpty);
  }

  Future<void> _loadNotifications({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }
    try {
      final userId =
          await InjectionContainer.instance.authLocalDataSource.getUserId();
      final signals = await _collectSignals();

      // POST /assistant/notifications : signaux front (réunions, mails, focus, etc.)
      // + le backend ajoute contexte + ML si besoin.
      final generated = await _assistantService.fetchNotifications(
        userId: userId,
        locale: WidgetsBinding.instance.platformDispatcher.locale
            .toLanguageTag(),
        timezone: 'Africa/Tunis',
        tone: 'professional',
        maxItems: 20,
        signals: signals,
      );

      // Deduplicate by dedupeKey; also hide any already dismissed by title+message.
      final deduped = <String, AssistantNotification>{};
      for (final n in generated) {
        final titleMessageKey = _titleMessageKey(n.title, n.message);
        if (_dismissedTitleMessage.contains(titleMessageKey)) continue;
        if (n.dedupeKey.isNotEmpty && _dismissedDedupeKeys.contains(n.dedupeKey)) {
          continue;
        }
        if (n.dedupeKey.isEmpty) {
          deduped[n.id] = n;
        } else if (!_seenDedupeKeys.contains(n.dedupeKey)) {
          deduped[n.dedupeKey] = n;
          _seenDedupeKeys.add(n.dedupeKey);
        }
      }

      final mapped = deduped.values.map(_mapAssistantNotificationToUi).toList()
        ..sort((a, b) => a.priority.index.compareTo(b.priority.index));

      if (!mounted) return;
      setState(() {
        _notifications = mapped;
        _cachedNotifications = mapped;
      });
    } on AssistantUnauthorizedException {
      if (mounted) {
        _authController.logout();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load notifications';
      });
    } finally {
      if (mounted && showSpinner) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  static const _prefsDismissedKey =
      'assistant_notifications_dismissed_dedupeKeys';
  static const _prefsDismissedTitleMessageKey =
      'assistant_notifications_dismissed_titleMessage';

  static String _titleMessageKey(String title, String message) =>
      '$title|$message';

  Future<List<Map<String, dynamic>>> _collectSignals() async {
    final nowUtc = DateTime.now().toUtc();
    final occurredAt = nowUtc.toIso8601String();
    final signals = <Map<String, dynamic>>[];

    // Focus -> BREAK_SUGGESTED (dès 1h de focus).
    final focusMinutes = FocusSessionManager.instance.getFocusMinutes();
    if (focusMinutes >= 60) {
      final focusHours = (focusMinutes / 60).round().clamp(1, 24);
      signals.add({
        'signalType': 'BREAK_SUGGESTED',
        'payload': {'focusHours': focusHours},
        'scores': {'priority': 0.6, 'confidence': 0.8},
        'occurredAt': occurredAt,
        'source': 'frontend',
      });
    }

    // Meetings -> MEETING_SOON (prochaine réunion dans 2 h).
    final meetingService = MeetingService();
    try {
      final meetings = await meetingService.fetchMeetings();
      final upcoming = meetings
          .where((m) => m.startTime.isAfter(DateTime.now()))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (upcoming.isNotEmpty) {
        final next = upcoming.first;
        final startsInMin = next.startTime.difference(DateTime.now()).inMinutes;
        if (startsInMin >= 0 && startsInMin <= 120) {
          signals.add({
            'signalType': 'MEETING_SOON',
            'payload': {
              'title': next.subject,
              'startsInMin': startsInMin,
              'location': next.timezone,
              'meetingId': next.meetingId,
            },
            'scores': {'priority': 0.9, 'confidence': 0.85},
            'occurredAt': occurredAt,
            'source': 'n8n',
          });
        }
      }
    } catch (_) {
      // ignore
    } finally {
      meetingService.dispose();
    }

    // Emails -> EMAIL_REQUIRES_RESPONSE (emails importants).
    try {
      final emailService = N8nEmailService();
      final emails = await emailService.fetchEmails();
      final important = emails
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) {
            final priority = (e['priority'] ?? '').toString().toLowerCase();
            final status = (e['status'] ?? '').toString().toLowerCase();
            final actionItems = (e['actionItems'] ?? '').toString().trim();
            final hasId = (e['emailId'] ?? '').toString().trim().isNotEmpty;
            final isReplied = status == 'replied';
            final isHigh = priority == 'high';
            final needsAction = actionItems.isNotEmpty;
            return hasId && !isReplied && (isHigh || needsAction);
          })
          .toList();
      for (final e in important.take(3)) {
        signals.add({
          'signalType': 'EMAIL_REQUIRES_RESPONSE',
          'payload': {
            'subject': (e['emailSubject'] ?? '').toString(),
            'from': (e['emailFrom'] ?? '').toString(),
            'emailId': (e['emailId'] ?? '').toString(),
          },
          'scores': {'priority': 0.85, 'confidence': 0.8},
          'occurredAt': occurredAt,
          'source': 'n8n',
        });
      }
    } catch (_) {
      // ignore
    }

    // Traffic -> TRAFFIC_ALERT (heures de pointe).
    final nowLocal = DateTime.now();
    final hour = nowLocal.hour;
    final isCommuteMorning = hour >= 7 && hour <= 9;
    final isCommuteEvening = hour >= 17 && hour <= 19;
    if (isCommuteMorning || isCommuteEvening) {
      signals.add({
        'signalType': 'TRAFFIC_ALERT',
        'payload': {
          'route': isCommuteMorning ? 'Home → Office' : 'Office → Home',
          'destination': isCommuteMorning ? 'Office' : 'Home',
          'etaMin': 30,
          'extraDelayMin': 10,
        },
        'scores': {'priority': 0.7, 'confidence': 0.6},
        'occurredAt': occurredAt,
        'source': 'frontend',
      });
    }

    // Late night -> BREAK_SUGGESTED.
    if (hour >= 23 || hour < 6) {
      final lateFocusHours = ((focusMinutes / 60).round()).clamp(1, 24);
      signals.add({
        'signalType': 'BREAK_SUGGESTED',
        'payload': {
          'focusHours': lateFocusHours,
          'reason': 'late_night',
          'localTime': nowLocal.toIso8601String(),
        },
        'scores': {'priority': 0.95, 'confidence': 0.8},
        'occurredAt': occurredAt,
        'source': 'frontend',
      });
    }

    // Fallback si aucun signal : le backend peut quand même renvoyer du contexte + ML.
    if (signals.isEmpty) {
      signals.add({
        'signalType': 'WEEKLY_SUMMARY_READY',
        'payload': {},
        'scores': {'priority': 0.2, 'confidence': 0.6},
        'occurredAt': occurredAt,
        'source': 'frontend',
      });
    }

    return signals;
  }

  Future<void> _loadDismissedFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsDismissedKey) ?? const <String>[];
    final storedTitleMessage =
        prefs.getStringList(_prefsDismissedTitleMessageKey) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _dismissedDedupeKeys.addAll(stored);
      _dismissedTitleMessage.addAll(storedTitleMessage);
    });
  }

  Future<void> _saveDismissedToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsDismissedKey,
      _dismissedDedupeKeys.toList(),
    );
    await prefs.setStringList(
      _prefsDismissedTitleMessageKey,
      _dismissedTitleMessage.toList(),
    );
  }

  UiNotification _mapAssistantNotificationToUi(AssistantNotification n) {
    final category = _mapCategory(n.category);
    final priority = _mapPriority(n.priority);
    return UiNotification(
      id: n.id,
      title: n.title,
      message: n.message,
      priority: priority,
      category: category,
      timeLabel: 'Just now',
      actions: n.actions,
      raw: n,
    );
  }

  NotificationCategory _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return NotificationCategory.work;
      case 'personal':
        return NotificationCategory.personal;
      case 'travel':
        return NotificationCategory.travel;
      default:
        return NotificationCategory.general;
    }
  }

  NotificationPriority _mapPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return NotificationPriority.critical;
      case 'high':
        return NotificationPriority.important;
      case 'medium':
      case 'low':
      default:
        return NotificationPriority.canWait;
    }
  }

  void _handleDismiss(UiNotification notif) {
    final key = notif.raw?.dedupeKey;
    if (!mounted) return;
    setState(() {
      _notifications = _notifications.where((n) => n.id != notif.id).toList();
      if (key != null && key.isNotEmpty) {
        _dismissedDedupeKeys.add(key);
      }
      _dismissedTitleMessage.add(_titleMessageKey(notif.title, notif.message));
      _cachedNotifications = List.from(_notifications);
    });
    _saveDismissedToStorage();
  }

  Map<String, dynamic> _getPriorityConfig(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return {
          'bg': [
            const Color(0xFFFF0000).withOpacity(0.2),
            const Color(0xFFFFA500).withOpacity(0.2),
          ],
          'border': const Color(0xFFFF0000).withOpacity(0.3),
          'icon': LucideIcons.alertCircle,
          'iconColor': const Color(0xFFFF6B6B),
          'label': 'Critical',
        };
      case NotificationPriority.important:
        return {
          'bg': [
            const Color(0xFFFFB800).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.2),
          ],
          'border': const Color(0xFFFFB800).withOpacity(0.3),
          'icon': LucideIcons.bell,
          'iconColor': const Color(0xFFFFD93D),
          'label': 'Important',
        };
      case NotificationPriority.canWait:
        return {
          'bg': [
            AppColors.cyan500.withOpacity(0.2),
            AppColors.blue500.withOpacity(0.2),
          ],
          'border': AppColors.cyan500.withOpacity(0.3),
          'icon': LucideIcons.clock,
          'iconColor': AppColors.cyan400,
          'label': 'Can wait',
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

    // Même bleu que le dégradé pour éviter la bande noire sous la nav (safe area / première ouverture).
    const Color _scaffoldBg = Color(0xFF0f2940);
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
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

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                    ),

                    // Filter
                    _buildFilter(context, isMobile),

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),

                    // Notifications List
                    _buildNotificationsSection(context, isMobile),

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),

                    // Info
                    _buildInfo(
                      context,
                      isMobile,
                    ).animate().fadeIn(delay: 600.ms, duration: 300.ms),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(
                  currentPath: '/notifications-center',
                ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
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
            if (_activeNotifications.isNotEmpty)
              Container(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: 28.0,
                  tablet: 32.0,
                  desktop: 36.0,
                ),
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 28.0,
                  tablet: 32.0,
                  desktop: 36.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF0000).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_activeNotifications.length}',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: Responsive.getResponsiveValue(
            context,
            mobile: 6.0,
            tablet: 8.0,
            desktop: 10.0,
          ),
        ),
        Text(
          'AI-filtered and prioritized',
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

  Widget _buildFilter(BuildContext context, bool isMobile) {
    final categories = [
      {'id': NotificationCategory.all, 'label': 'All'},
      {'id': NotificationCategory.work, 'label': 'Work'},
      {'id': NotificationCategory.personal, 'label': 'Personal'},
      {'id': NotificationCategory.travel, 'label': 'Travel'},
      {'id': NotificationCategory.general, 'label': 'General'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _filter == cat['id'] as NotificationCategory;
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
              onTap: () =>
                  setState(() => _filter = cat['id'] as NotificationCategory),
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
                  color: isSelected
                      ? null
                      : AppColors.textWhite.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(
                    Responsive.getResponsiveValue(
                      context,
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                  ),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.cyan500.withOpacity(0.5)
                        : AppColors.textWhite.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
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
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, bool isMobile) {
    if (_loading && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveValue(
              context,
              mobile: 40.0,
              tablet: 50.0,
              desktop: 60.0,
            ),
          ),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveValue(
              context,
              mobile: 40.0,
              tablet: 50.0,
              desktop: 60.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.alertTriangle,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 40.0,
                  tablet: 44.0,
                  desktop: 48.0,
                ),
                color: AppColors.cyan400.withOpacity(0.7),
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
              ),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 14.0,
                    tablet: 15.0,
                    desktop: 16.0,
                  ),
                  color: AppColors.cyan400.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 6.0,
                  tablet: 8.0,
                  desktop: 10.0,
                ),
              ),
              TextButton(
                onPressed: _loadNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(
              height: Responsive.getResponsiveValue(
                context,
                mobile: 40.0,
                tablet: 50.0,
                desktop: 60.0,
              ),
            ),
            Icon(
              LucideIcons.check,
              size: Responsive.getResponsiveValue(
                context,
                mobile: 60.0,
                tablet: 64.0,
                desktop: 72.0,
              ),
              color: AppColors.cyan400.withOpacity(0.3),
            ),
            SizedBox(
              height: Responsive.getResponsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
            ),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 15.0,
                  tablet: 16.0,
                  desktop: 17.0,
                ),
                color: AppColors.cyan400.withOpacity(0.7),
              ),
            ),
            SizedBox(
              height: Responsive.getResponsiveValue(
                context,
                mobile: 6.0,
                tablet: 8.0,
                desktop: 10.0,
              ),
            ),
            Text(
              'No notifications in this category',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 13.0,
                  desktop: 14.0,
                ),
                color: AppColors.cyan400.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredNotifications.asMap().entries.map((entry) {
        final index = entry.key;
        final notif = entry.value;
        final config = _getPriorityConfig(notif.priority);

        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildNotificationCard(
            context,
            isMobile,
            notif,
            config,
            index,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    bool isMobile,
    UiNotification notif,
    Map<String, dynamic> config,
    int index,
  ) {
    return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: config['bg'] as List<Color>),
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),
            border: Border.all(color: config['border'] as Color, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                children: [
                  // Priority bar for critical
                  if (notif.priority == NotificationPriority.critical)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 2.0,
                          tablet: 2.5,
                          desktop: 3.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF0000),
                              const Color(0xFFFFA500),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                              Responsive.getResponsiveValue(
                                context,
                                mobile: 16.0,
                                tablet: 18.0,
                                desktop: 20.0,
                              ),
                            ),
                            topRight: Radius.circular(
                              Responsive.getResponsiveValue(
                                context,
                                mobile: 16.0,
                                tablet: 18.0,
                                desktop: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 20.0,
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: config['bg'] as List<Color>,
                            ),
                            borderRadius: BorderRadius.circular(
                              Responsive.getResponsiveValue(
                                context,
                                mobile: 10.0,
                                tablet: 11.0,
                                desktop: 12.0,
                              ),
                            ),
                            border: Border.all(
                              color: config['border'] as Color,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            config['icon'] as IconData,
                            color: config['iconColor'] as Color,
                            size: Responsive.getResponsiveValue(
                              context,
                              mobile: 18.0,
                              tablet: 20.0,
                              desktop: 22.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
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
                                  GestureDetector(
                                    onTap: () => _handleDismiss(notif),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        Responsive.getResponsiveValue(
                                          context,
                                          mobile: 4.0,
                                          tablet: 5.0,
                                          desktop: 6.0,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.textWhite.withOpacity(
                                          0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Responsive.getResponsiveValue(
                                            context,
                                            mobile: 6.0,
                                            tablet: 7.0,
                                            desktop: 8.0,
                                          ),
                                        ),
                                        border: Border.all(
                                          color: AppColors.textWhite
                                              .withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.x,
                                        size: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 14.0,
                                          tablet: 16.0,
                                          desktop: 18.0,
                                        ),
                                        color: AppColors.cyan400.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                ),
                              ),
                              Text(
                                notif.message,
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
                              SizedBox(
                                height: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 8.0,
                                  tablet: 10.0,
                                  desktop: 12.0,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.clock,
                                        size: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 12.0,
                                          tablet: 13.0,
                                          desktop: 14.0,
                                        ),
                                        color: config['iconColor'] as Color,
                                      ),
                                      SizedBox(
                                        width: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 4.0,
                                          tablet: 5.0,
                                          desktop: 6.0,
                                        ),
                                      ),
                                      Text(
                                        notif.timeLabel,
                                        style: TextStyle(
                                          fontSize:
                                              Responsive.getResponsiveValue(
                                                context,
                                                mobile: 10.0,
                                                tablet: 11.0,
                                                desktop: 12.0,
                                              ),
                                          color: AppColors.cyan400.withOpacity(
                                            0.5,
                                          ),
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
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 + (index * 50)),
          duration: 300.ms,
        )
        .slideX(
          begin: -0.2,
          end: 0,
          delay: Duration(milliseconds: 100 + (index * 50)),
          duration: 300.ms,
        );
  }

  Widget _buildInfo(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 14.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.cyan500.withOpacity(0.05),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
        ),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: Text(
        'AVA automatically filters and prioritizes notifications based on your context and preferences',
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
