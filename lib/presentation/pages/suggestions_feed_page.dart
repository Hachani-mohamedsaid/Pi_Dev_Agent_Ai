import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/assistant_suggestion.dart';
import '../../data/services/assistant_service.dart';
import '../../injection_container.dart';
import '../../services/focus_session_manager.dart';
import '../../services/location_service.dart';
import '../../services/openai_suggestion_service.dart';
import '../../services/suggestion_preferences_store.dart';
import '../../services/weather_service.dart';
import '../state/auth_controller.dart';
import '../widgets/navigation_bar.dart';

class SuggestionsFeedPage extends StatefulWidget {
  const SuggestionsFeedPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<SuggestionsFeedPage> createState() => _SuggestionsFeedPageState();
}

/// Cache so when user closes and reopens Suggestions we show last list without auto-refresh.
List<Suggestion>? _cachedSuggestions;

class _SuggestionsFeedPageState extends State<SuggestionsFeedPage> {
  late final AssistantService _assistantService = AssistantService(
    authLocalDataSource: InjectionContainer.instance.authLocalDataSource,
  );
  /// null = checking, true = ready.
  bool? _allowRequest;
  Future<List<Suggestion>>? _futureSuggestions;
  /// Current list shown; set when load completes or from cache when re-opening.
  List<Suggestion>? _currentSuggestions;
  String? _userId;

  /// Current context sent to backend – displayed in the context card (no hardcoded text).
  String? _contextLocation;
  String? _contextTime;
  String? _contextWeather;
  String _contextMeetingsLabel = 'No meetings';

  final Set<String> _processedIds = {};
  final Map<String, String> _feedbackStatus = {};

  /// Last 15 suggestion messages shown, so the next batch avoids repeating the same ideas.
  final List<String> _recentlyShownSuggestionMessages = [];

  /// Auto-refresh suggestions every 10 minutes.
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    FocusSessionManager.instance.onResume();
    _initLoad();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer(String userId) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      if (!mounted) return;
      try {
        final list = await _loadSuggestionsWithContext(userId)
            .timeout(const Duration(seconds: 25), onTimeout: () => <Suggestion>[]);
        _cachedSuggestions = list;
        if (mounted) setState(() => _currentSuggestions = list);
      } catch (_) {
        if (mounted) setState(() => _currentSuggestions = _currentSuggestions ?? []);
      }
    });
  }

  Future<String?> getUserId() async {
    return InjectionContainer.instance.authLocalDataSource.getUserId();
  }

  /// Load location, time, weather, focus for the Current Context card. Timeout so the page never stays stuck on loading.
  Future<void> _loadCurrentContext() async {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    String location = 'home';
    String weather = 'sunny';
    try {
      if (widget.controller.currentProfile == null) {
        await widget.controller.loadProfile().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      }
      location = await LocationService.getLogicalLocation()
          .timeout(const Duration(seconds: 5), onTimeout: () => 'home');
      final city =
          widget.controller.currentProfile?.location?.trim().isNotEmpty == true
              ? widget.controller.currentProfile!.location!
              : null;
      weather = await WeatherService.getWeatherCondition(cityName: city)
          .timeout(const Duration(seconds: 5), onTimeout: () => 'sunny');
    } catch (_) {
      // keep defaults: location = home, weather = sunny
    }
    if (!mounted) return;
    setState(() {
      _contextLocation = location;
      _contextTime = _formatTimeForDisplay(time);
      _contextWeather = weather;
      _contextMeetingsLabel = 'No meetings';
    });
  }

  /// On first enter: load suggestions. When re-opening after close: show cached list, no auto-refresh.
  Future<void> _initLoad() async {
    final userId = await getUserId();
    final effectiveUserId = (userId != null && userId.isNotEmpty) ? userId : 'ml_test_user';
    if (!mounted) return;
    setState(() => _userId = effectiveUserId);

    await _loadCurrentContext();
    if (!mounted) return;

    // Re-opening page: show last suggestions from cache, do not refresh automatically.
    if (_cachedSuggestions != null && _cachedSuggestions!.isNotEmpty) {
      setState(() {
        _allowRequest = true;
        _currentSuggestions = List.from(_cachedSuggestions!);
        _futureSuggestions = null;
      });
      _startAutoRefreshTimer(effectiveUserId);
      return;
    }

    // First time or empty cache: load suggestions.
    setState(() {
      _allowRequest = true;
      _currentSuggestions = null;
      _futureSuggestions = _loadSuggestionsWithContext(effectiveUserId)
          .timeout(const Duration(seconds: 25), onTimeout: () => <Suggestion>[])
          .then((list) {
        _cachedSuggestions = list;
        if (mounted) setState(() => _currentSuggestions = list);
        return list;
      }).catchError((_, __) {
        if (mounted) setState(() => _currentSuggestions = []);
        return <Suggestion>[];
      });
    });
    _startAutoRefreshTimer(effectiveUserId);
  }

  /// No duplication: one per id, then one per (type+message) so the same suggestion text never appears twice.
  List<Suggestion> _deduplicateSuggestionsById(List<Suggestion> list) {
    final byId = <String, Suggestion>{};
    var emptyIdCount = 0;
    for (final s in list) {
      final key = s.id.isEmpty ? '_noId_${emptyIdCount++}' : s.id;
      byId.putIfAbsent(key, () => s);
    }
    final byMessage = <String, Suggestion>{};
    for (final s in byId.values) {
      final key = '${s.type}|${s.message.trim()}';
      byMessage.putIfAbsent(key, () => s);
    }
    return byMessage.values.toList();
  }

  /// Load suggestions from OpenAI using context (time, duration, weather, temp, user data, time-in-app counter).
  /// Falls back to backend if OpenAI returns empty (e.g. no API key or error).
  Future<List<Suggestion>> _loadSuggestionsWithContext(String userId) async {
    try {
      if (widget.controller.currentProfile == null) {
        await widget.controller.loadProfile();
      }
      final now = DateTime.now();
      final timeHhMm =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final timeDisplay = _formatTimeForDisplay(timeHhMm);
      final location = await LocationService.getLogicalLocation();
      final city =
          widget.controller.currentProfile?.location?.trim().isNotEmpty == true
              ? widget.controller.currentProfile!.location!
              : null;
      final weather = await WeatherService.getWeatherCondition(cityName: city);
      final temperatureCelsius = await WeatherService.getTemperature(cityName: city);
      final meetings = <Map<String, String>>[];
      final focusMinutes = FocusSessionManager.instance.getFocusMinutes();
      final timeInAppMinutes = focusMinutes;
      final profile = widget.controller.currentProfile;
      if (mounted) {
        setState(() {
          _contextLocation = location;
          _contextTime = timeDisplay;
          _contextWeather = weather;
          _contextMeetingsLabel =
              meetings.isEmpty ? 'No meetings' : '${meetings.length} meetings today';
        });
      }
      final learnedPreferences = await SuggestionPreferencesStore.getLearnedSummary();
      final ctx = OpenAISuggestionContext(
        time: timeDisplay,
        focusMinutes: focusMinutes,
        timeInAppMinutes: timeInAppMinutes,
        location: location,
        weather: weather,
        temperatureCelsius: temperatureCelsius,
        userName: profile?.name,
        userEmail: profile?.email,
        userRole: profile?.role,
        userBio: profile?.bio,
        meetingsLabel: meetings.isEmpty ? 'No meetings' : '${meetings.length} meetings today',
        learnedPreferences: learnedPreferences.isEmpty ? null : learnedPreferences,
      );
      final list = await OpenAISuggestionService.getSuggestions(
        ctx,
        recentlyShownMessages: _recentlyShownSuggestionMessages.isEmpty
            ? null
            : _recentlyShownSuggestionMessages,
      );
      final deduped = _deduplicateSuggestionsById(list);
      final capped = deduped.take(3).toList();
      if (capped.isNotEmpty) {
        if (mounted) {
          for (final s in capped) {
            final msg = s.message.trim();
            if (msg.isNotEmpty && !_recentlyShownSuggestionMessages.contains(msg)) {
              _recentlyShownSuggestionMessages.add(msg);
              while (_recentlyShownSuggestionMessages.length > 15) {
                _recentlyShownSuggestionMessages.removeAt(0);
              }
            }
          }
        }
        await FocusSessionManager.instance.markSuggestionShown();
        return capped;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _contextLocation ??= 'home';
          _contextTime ??= _formatTimeForDisplay(
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          );
          _contextWeather ??= 'sunny';
        });
      }
    }
    // Fallback: backend
    try {
      final now = DateTime.now();
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final focusMinutes = FocusSessionManager.instance.getFocusMinutes();
      final focusHours = (focusMinutes / 60).round().clamp(0, 24);
      final payload = AssistantContextPayload(
        userId: userId,
        time: time,
        location: _contextLocation ?? 'home',
        weather: _contextWeather ?? 'sunny',
        focusHours: focusHours,
        meetings: null,
      );
      final list = await _assistantService.sendContext(payload);
      final deduped = _deduplicateSuggestionsById(list);
      final capped = deduped.take(3).toList();
      if (capped.isNotEmpty) await FocusSessionManager.instance.markSuggestionShown();
      return capped;
    } on AssistantUnauthorizedException {
      if (mounted) widget.controller.logout();
      return [];
    } catch (_) {
      final list = await _assistantService.fetchSuggestions(userId: userId);
      return _deduplicateSuggestionsById(list).take(3).toList();
    }
  }

  String _formatTimeForDisplay(String hhMm) {
    final parts = hhMm.split(':');
    if (parts.length != 2) return hhMm;
    final h = int.tryParse(parts[0]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:${parts[1]} $period';
  }

  /// Pull-to-refresh: load new suggestions (same as tapping "Nouvelles suggestions").
  Future<void> _refreshSuggestions() async {
    final userId = _userId ?? await getUserId();
    if (userId == null || userId.isEmpty) return;
    if (!mounted) return;
    _loadNewSuggestions();
  }

  /// Load new suggestions only when user taps "Nouvelles suggestions" (or pull-to-refresh). Replaces current list.
  Future<void> _loadNewSuggestions() async {
    final userId = _userId ?? await getUserId() ?? 'ml_test_user';
    if (!mounted) return;
    setState(() {
      _allowRequest = true;
      _currentSuggestions = null;
      _futureSuggestions = _loadSuggestionsWithContext(userId).then((list) {
        _cachedSuggestions = list;
        if (mounted) setState(() => _currentSuggestions = list);
        return list;
      });
    });
  }

  Future<void> _handleAccept(Suggestion suggestion) async {
    final alreadyAnswered =
        _feedbackStatus[suggestion.id] == 'accepted' ||
        _feedbackStatus[suggestion.id] == 'dismissed';
    if (alreadyAnswered) return;

    try {
      await _assistantService.sendFeedback(
        suggestion.id,
        'accepted',
        userId: _userId,
        message: suggestion.message,
        type: suggestion.type,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send feedback. Try again.')),
        );
      }
      return;
    }
    if (!mounted) return;
    await SuggestionPreferencesStore.addAccepted(
      type: suggestion.type,
      message: suggestion.message,
    );
    setState(() {
      _feedbackStatus[suggestion.id] = 'accepted';
      _processedIds.add(suggestion.id);
      if (_currentSuggestions != null) {
        _currentSuggestions = List.from(_currentSuggestions!)
          ..removeWhere((s) => s.id == suggestion.id);
        _cachedSuggestions = _currentSuggestions;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great! I will learn from this 👍')),
    );
    await FocusSessionManager.instance.markSuggestionShown();
  }

  Future<void> _handleDismiss(Suggestion suggestion) async {
    final alreadyAnswered =
        _feedbackStatus[suggestion.id] == 'accepted' ||
        _feedbackStatus[suggestion.id] == 'dismissed';
    if (alreadyAnswered) return;

    try {
      await _assistantService.sendFeedback(
        suggestion.id,
        'dismissed',
        userId: _userId,
        message: suggestion.message,
        type: suggestion.type,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send feedback. Try again.')),
        );
      }
      return;
    }
    if (!mounted) return;
    await SuggestionPreferencesStore.addDismissed(
      type: suggestion.type,
      message: suggestion.message,
    );
    setState(() {
      _feedbackStatus[suggestion.id] = 'dismissed';
      _processedIds.add(suggestion.id);
      if (_currentSuggestions != null) {
        _currentSuggestions = List.from(_currentSuggestions!)
          ..removeWhere((s) => s.id == suggestion.id);
        _cachedSuggestions = _currentSuggestions;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Got it. I'll improve next time 👌")),
    );
    await FocusSessionManager.instance.markSuggestionShown();
  }

  List<Color> _getGradientForType(String type) {
    switch (type) {
      case 'coffee':
        return [
          const Color(0xFF9333EA).withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ];
      case 'leave_home':
        return [
          const Color(0xFFFFB800).withOpacity(0.2),
          const Color(0xFFFF9800).withOpacity(0.2),
        ];
      case 'umbrella':
        return [
          AppColors.cyan500.withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ];
      case 'break':
        return [
          const Color(0xFF10B981).withOpacity(0.2),
          const Color(0xFF22C55E).withOpacity(0.2),
        ];
      default:
        return [
          AppColors.cyan500.withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ];
    }
  }

  Color _getBorderForType(String type) {
    switch (type) {
      case 'coffee':
        return const Color(0xFF9333EA).withOpacity(0.3);
      case 'leave_home':
        return const Color(0xFFFFB800).withOpacity(0.3);
      case 'umbrella':
        return AppColors.cyan500.withOpacity(0.3);
      case 'break':
        return const Color(0xFF10B981).withOpacity(0.3);
      default:
        return AppColors.cyan500.withOpacity(0.2);
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
              // Main Content – pull to refresh
              RefreshIndicator(
                onRefresh: _refreshSuggestions,
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
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      )),
                      _buildCurrentContext(context, isMobile)
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 300.ms)
                          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 100.ms, duration: 300.ms),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      _buildNewSuggestionsButton(context, isMobile),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      _buildSuggestionsSection(context, isMobile),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      )),
                      _buildSettingsButton(context, isMobile)
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 300.ms),
                      SizedBox(height: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      _buildInfo(context, isMobile)
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 300.ms),
                    ],
                  ),
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/suggestions'),
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
          'Suggestions',
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
          'Personalized recommendations from AVA',
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

  Widget _buildCurrentContext(BuildContext context, bool isMobile) {
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
                  LucideIcons.sun,
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
                      'Current Context',
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
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    )),
                    _buildContextItem(LucideIcons.mapPin, _contextLocation ?? '—'),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    _buildContextItem(LucideIcons.clock, _contextTime ?? '—'),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    _buildContextItem(LucideIcons.cloudSun, _contextWeather ?? '—'),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    _buildContextItem(LucideIcons.calendar, _contextMeetingsLabel),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    )),
                    _buildContextItem(
                      LucideIcons.clock,
                      'Time in app: ${FocusSessionManager.instance.getFocusMinutes()} min (stops when you exit)',
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

  Widget _buildContextItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
          color: const Color(0xFFC084FC).withOpacity(0.7),
        ),
        SizedBox(width: Responsive.getResponsiveValue(
          context,
          mobile: 6.0,
          tablet: 7.0,
          desktop: 8.0,
        )),
        Expanded(
          child: Text(
            text,
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
        ),
      ],
    );
  }

  Widget _buildNewSuggestionsButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => _loadNewSuggestions(),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
          horizontal: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
        ),
        decoration: BoxDecoration(
          color: AppColors.cyan500.withOpacity(0.15),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
          border: Border.all(color: AppColors.cyan400.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.refreshCw, size: 18, color: AppColors.cyan400),
            SizedBox(width: Responsive.getResponsiveValue(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
            Text(
              'Nouvelles suggestions',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                fontWeight: FontWeight.w600,
                color: AppColors.cyan400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(BuildContext context, bool isMobile) {
    if (_userId == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveValue(context, mobile: 40.0, tablet: 50.0, desktop: 60.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.logIn, size: 48, color: AppColors.cyan400.withOpacity(0.6)),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              Text(
                'Please sign in to see suggestions',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                  color: AppColors.cyan400.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_allowRequest == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveValue(context, mobile: 40.0, tablet: 50.0, desktop: 60.0),
          ),
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_allowRequest == false) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveValue(context, mobile: 40.0, tablet: 50.0, desktop: 60.0),
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.clock, size: 56, color: AppColors.cyan400.withOpacity(0.7)),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
              Text(
                "Keep going! I'll suggest something when you need it.",
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
                  color: AppColors.cyan400.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
              Text(
                'Time in app: ${FocusSessionManager.instance.getFocusMinutes()} min',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 13.0, desktop: 14.0),
                  color: AppColors.cyan400.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // No suggestions loaded yet: show empty state. New suggestions only when user taps "Nouvelles suggestions".
    if (_futureSuggestions == null && _currentSuggestions == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: Responsive.getResponsiveValue(context, mobile: 40.0, tablet: 50.0, desktop: 60.0),
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.sparkles, size: 56, color: AppColors.cyan400.withOpacity(0.7)),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
              Text(
                "Tap 'Nouvelles suggestions' to load suggestions.",
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
                  color: AppColors.cyan400.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    // Show current list (user can check all, accept/refuse; new batch only on refresh).
    if (_currentSuggestions != null) {
      return _buildSuggestionsList(_currentSuggestions!, isMobile);
    }
    // Loading new suggestions.
    return FutureBuilder<List<Suggestion>>(
      future: _futureSuggestions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                  const CircularProgressIndicator(),
                  SizedBox(height: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
                  Text(
                    'Loading AI suggestion...',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      color: AppColors.cyan400.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          if (snapshot.error is AssistantUnauthorizedException) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.controller.logout();
            });
            return const Center(child: CircularProgressIndicator());
          }
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
                    'Unable to load suggestions',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 15.0,
                        desktop: 16.0,
                      ),
                      color: AppColors.cyan400.withOpacity(0.8),
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
                    'Please try again later.',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      color: AppColors.cyan400.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final all = snapshot.data ?? [];
        if (mounted) setState(() => _currentSuggestions = all);
        return _buildSuggestionsList(all, isMobile);
      },
    );
  }

  Widget _buildSuggestionsList(List<Suggestion> suggestions, bool isMobile) {
    if (suggestions.isEmpty) {
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
              LucideIcons.checkCircle,
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
              'No suggestions right now.',
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
              "Tap 'Nouvelles suggestions' for more.",
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
      children: suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final suggestion = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: _buildSuggestionCard(context, isMobile, suggestion, index),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    bool isMobile,
    Suggestion suggestion,
    int index,
  ) {
    final colors = _getGradientForType(suggestion.type);
    final status = _feedbackStatus[suggestion.id];
    final alreadyAnswered =
        status == 'accepted' || status == 'dismissed';
    final borderColor = status == 'accepted'
        ? Colors.green
        : status == 'dismissed'
            ? Colors.red
            : _getBorderForType(suggestion.type);
    final confidencePercent =
        (suggestion.confidence * 100).clamp(0, 100).round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: borderColor,
          width: alreadyAnswered ? 2 : 1,
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
          child: Stack(
            children: [
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
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                    colors: colors,
                                  ),
                                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 10.0,
                                    tablet: 11.0,
                                    desktop: 12.0,
                                  )),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  suggestion.icon,
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
                                mobile: 10.0,
                                tablet: 12.0,
                                desktop: 14.0,
                              )),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.message,
                                      style: TextStyle(
                                        fontSize: Responsive.getResponsiveValue(
                                          context,
                                          mobile: 14.0,
                                          tablet: 15.0,
                                          desktop: 16.0,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                    SizedBox(height: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 6.0,
                                      tablet: 7.0,
                                      desktop: 8.0,
                                    )),
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.sparkles,
                                          size: Responsive.getResponsiveValue(
                                            context,
                                            mobile: 11.0,
                                            tablet: 12.0,
                                            desktop: 13.0,
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
                                          'Relevance $confidencePercent%',
                                          style: TextStyle(
                                            fontSize: Responsive.getResponsiveValue(
                                              context,
                                              mobile: 10.0,
                                              tablet: 11.0,
                                              desktop: 12.0,
                                            ),
                                            color: AppColors.cyan400.withOpacity(0.5),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _handleDismiss(suggestion),
                          child: Container(
                            padding: EdgeInsets.all(Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 7.0,
                              desktop: 8.0,
                            )),
                            decoration: BoxDecoration(
                              color: AppColors.textWhite.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 7.0,
                                desktop: 8.0,
                              )),
                              border: Border.all(
                                color: AppColors.textWhite.withOpacity(0.1),
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
                              color: AppColors.cyan400.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Accepter / Refuser – un seul feedback par suggestion
                    SizedBox(height: Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    )),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: alreadyAnswered
                                ? null
                                : () => _handleAccept(suggestion),
                            child: Opacity(
                              opacity: alreadyAnswered ? 0.5 : 1,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 9.0,
                                    tablet: 10.0,
                                    desktop: 11.0,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.cyan500.withOpacity(0.3),
                                      AppColors.blue500.withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 13.0,
                                    desktop: 14.0,
                                  )),
                                  border: Border.all(
                                    color: AppColors.cyan500.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Accepter',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 13.0,
                                        desktop: 14.0,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textCyan300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.getResponsiveValue(
                          context,
                          mobile: 8.0,
                          tablet: 10.0,
                          desktop: 12.0,
                        )),
                        Expanded(
                          child: GestureDetector(
                            onTap: alreadyAnswered
                                ? null
                                : () => _handleDismiss(suggestion),
                            child: Opacity(
                              opacity: alreadyAnswered ? 0.5 : 1,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 9.0,
                                    tablet: 10.0,
                                    desktop: 11.0,
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
                                    color: AppColors.textWhite.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Refuser',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 13.0,
                                        desktop: 14.0,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.cyan400.withOpacity(0.8),
                                    ),
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
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + (index * 100)), duration: 300.ms)
        .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: 200 + (index * 100)), duration: 300.ms);
  }

  Widget _buildSettingsButton(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () {
        // Navigate to suggestion preferences
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
              child: Text(
                'Suggestion Preferences',
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
            ),
            Padding(
              padding: EdgeInsets.only(
                right: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
              child: Icon(
                LucideIcons.chevronRight,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
                color: AppColors.cyan400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isMobile) {
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
        'Suggestions are personalized by AI from your profile and context (time, weather, habits). Your Accept/Refuse choices help AVA learn your preferences. Tap "Nouvelles suggestions" for more.',
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
