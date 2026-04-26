import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/api_config.dart' show apiRootUrl;
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/google_connect_service.dart';
import '../../data/services/rag_upload_service.dart';
import '../../data/services/telegram_connect_service.dart';
import '../widgets/navigation_bar.dart';

Color _primaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textWhite
      : const Color(0xFF12263A);
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textCyan200
      : const Color(0xFF5B7B92);
}

Color _surfaceBorder(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.cyan500.withOpacity(0.12)
      : const Color(0xFFC7DDE9);
}

LinearGradient _panelGradient(BuildContext context, {double opacity = 0.4}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? [
            const Color(0xFF1e4a66).withOpacity(opacity),
            const Color(0xFF16384d).withOpacity(opacity),
          ]
        : const [Color(0xFFF9FCFF), Color(0xFFEAF4FB)],
  );
}

class ConnectedServicesPage extends StatefulWidget {
  const ConnectedServicesPage({super.key});

  @override
  State<ConnectedServicesPage> createState() => _ConnectedServicesPageState();
}

class _ConnectedServicesPageState extends State<ConnectedServicesPage> {
  static const _tokenKey = 'auth_access_token';
  static const _gmailIconUrl =
      'https://ssl.gstatic.com/ui/v1/icons/mail/rfr/gmail.ico';
  static const _calendarIconUrl =
      'https://ssl.gstatic.com/calendar/images/dynamiclogo_2020q4/calendar_31_2x.png';
  static const _telegramIconUrl = 'https://telegram.org/img/t_logo.png';
  static const _linkedinIconUrl =
      'https://static.licdn.com/sc/h/8s162nmbcnfkg7a0k8nq9wwqo';
  static const _driveIconUrl =
      'https://ssl.gstatic.com/images/branding/product/2x/drive_2020q4_48dp.png';

  final _googleService = GoogleConnectService();

  GoogleConnectStatus _googleStatus = GoogleConnectStatus.disconnected;
  bool _loadingGoogleStatus = true;
  bool _initialLoadDone = false;
  final _telegramService = TelegramConnectService();
  bool _telegramLinked = false;
  bool _loadingTelegramStatus = true;
  String? _telegramChatId;

  @override
  void initState() {
    super.initState();
    _loadGoogleStatus();
    _loadTelegramStatus();
  }

  Future<void> _loadGoogleStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      if (mounted) {
        _initialLoadDone = true;
        setState(() => _loadingGoogleStatus = false);
      }
      return;
    }
    try {
      final status = await _googleService.getStatus(token);
      if (mounted) {
        _initialLoadDone = true;
        setState(() {
          _googleStatus = status;
          _loadingGoogleStatus = false;
        });
      }
    } catch (_) {
      if (mounted) {
        _initialLoadDone = true;
        setState(() => _loadingGoogleStatus = false);
      }
    }
  }

  Future<void> _loadTelegramStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ?? '';
    if (token.isEmpty) {
      if (mounted) setState(() => _loadingTelegramStatus = false);
      return;
    }
    try {
      final status = await _telegramService.getStatus(token);
      if (mounted) {
        setState(() {
          _telegramLinked = status.linked;
          _telegramChatId = status.chatId;
          _loadingTelegramStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTelegramStatus = false);
    }
  }

  Future<void> _connectTelegram() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ?? '';
    if (token.isEmpty) return;
    try {
      final linkToken = await _telegramService.generateLinkToken(token);
      final url = Uri.parse('https://t.me/Rocco4xbot?start=$linkToken');

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        builder: (sheetContext) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryDarker,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2AABEE).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2AABEE).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.send,
                        size: 32,
                        color: Color(0xFF2AABEE),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connect Telegram',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Tap "Open Telegram" below\n2. Press START in the bot\n3. Return here and tap "Done"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textCyan200.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        icon: const Icon(LucideIcons.externalLink, size: 18),
                        label: const Text(
                          'Open Telegram',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2AABEE),
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _loadTelegramStatus();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.cyan500,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Done — Return to AVA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cyan400,
                          side: const BorderSide(
                            color: AppColors.cyan500,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect Telegram: $e')),
      );
    }
  }

  /// Entrance animations only before Google status load completes (first paint).
  Widget _withEntranceAnimation(Widget child, Animate Function(Animate) apply) {
    if (_initialLoadDone) return child;
    return apply(child.animate());
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final connectedServices = <Map<String, dynamic>>[];
    const totalActions = 257; // mocked for now
    final googleConnected = _googleStatus.connected && !_loadingGoogleStatus;
    final connectedCountForStats = (googleConnected ? 3 : 0) +
        (_telegramLinked ? 1 : 0) +
        1;
    // +3 when Google connected = Gmail&Sheets + Calendar + Drive, +1 for LinkedIn

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
                    _withEntranceAnimation(
                      _buildHeader(context, isMobile),
                      (a) => a
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: -0.2, end: 0, duration: 500.ms),
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context, mobile: 20.0, tablet: 24.0, desktop: 28.0,
                    )),
                    // Stats
                    _withEntranceAnimation(
                      _buildStats(context, isMobile, connectedCountForStats, totalActions),
                      (a) => a.fadeIn(delay: 100.ms, duration: 300.ms),
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context, mobile: 20.0, tablet: 24.0, desktop: 28.0,
                    )),
                    // Connected Services label
                    _withEntranceAnimation(
                      Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context, mobile: 16.0, tablet: 17.0, desktop: 18.0,
                          ),
                          fontWeight: FontWeight.w600,
                          color: _primaryText(context),
                        ),
                      ),
                      (a) => a.fadeIn(delay: 200.ms, duration: 300.ms),
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                    )),
                    // Dynamic connected services
                    ...connectedServices.asMap().entries.map((entry) {
                      final index = entry.key;
                      final service = entry.value;
                      final delayMs = 300 + (index * 100);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: Responsive.getResponsiveValue(
                            context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                          ),
                        ),
                        child: _withEntranceAnimation(
                          _buildConnectedServiceCard(context, isMobile, service),
                          (a) => a
                              .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
                              .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delayMs), duration: 300.ms),
                        ),
                      );
                    }),
                    // Mocked "connected" calendar card
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Responsive.getResponsiveValue(
                          context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                        ),
                      ),
                      child: _withEntranceAnimation(
                        googleConnected
                            ? _buildConnectedCalendarCard(context)
                            : const SizedBox.shrink(),
                        (a) {
                          final delayMs = 300 + (connectedServices.length * 100);
                          return a
                              .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
                              .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delayMs), duration: 300.ms);
                        },
                      ),
                    ),
                    if (googleConnected)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: Responsive.getResponsiveValue(
                            context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                          ),
                        ),
                        child: _withEntranceAnimation(
                          _buildConnectedDriveCard(context),
                          (a) {
                            final delayMs =
                                300 + ((connectedServices.length + 1) * 100);
                            return a
                                .fadeIn(
                                    delay: Duration(milliseconds: delayMs),
                                    duration: 300.ms)
                                .slideY(
                                    begin: 0.2,
                                    end: 0,
                                    delay: Duration(milliseconds: delayMs),
                                    duration: 300.ms);
                          },
                        ),
                      ),
                    if (_telegramLinked)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildMockConnectedTelegramCard(context),
                      ),
                    // Mocked LinkedIn card
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Responsive.getResponsiveValue(
                          context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                        ),
                      ),
                      child: _withEntranceAnimation(
                        _buildMockConnectedLinkedInCard(context),
                        (a) {
                          final delayMs = 300 + ((connectedServices.length + 2) * 100);
                          return a
                              .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
                              .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delayMs), duration: 300.ms);
                        },
                      ),
                    ),
                    if (googleConnected)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: Responsive.getResponsiveValue(
                            context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                          ),
                        ),
                        child: _withEntranceAnimation(
                          _buildGoogleConnectedLikeUberCard(context),
                          (a) {
                            final delayMs = 300 + ((connectedServices.length + 3) * 100);
                            return a
                                .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
                                .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delayMs), duration: 300.ms);
                          },
                        ),
                      ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context, mobile: 24.0, tablet: 28.0, desktop: 32.0,
                    )),
                    // Available Services
                    _withEntranceAnimation(
                      Text(
                        'Available to Connect',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context, mobile: 16.0, tablet: 17.0, desktop: 18.0,
                          ),
                          fontWeight: FontWeight.w600,
                          color: _primaryText(context),
                        ),
                      ),
                      (a) => a.fadeIn(delay: 600.ms, duration: 300.ms),
                    ),
                    SizedBox(height: Responsive.getResponsiveValue(
                      context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                    )),
                    if (!googleConnected)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: Responsive.getResponsiveValue(
                            context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                          ),
                        ),
                        child: _withEntranceAnimation(
                          _buildGoogleDisconnectedRow(context),
                          (a) => a
                              .fadeIn(delay: 600.ms, duration: 300.ms)
                              .slideY(begin: 0.2, end: 0, delay: 600.ms, duration: 300.ms),
                        ),
                      ),
                    if (!googleConnected)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: Responsive.getResponsiveValue(
                            context, mobile: 10.0, tablet: 12.0, desktop: 14.0,
                          ),
                        ),
                        child: _buildMockDisconnectedLikeGoogleRow(
                          context,
                          leading: _mockIconLeading(
                            context,
                            Image.network(_calendarIconUrl, width: 26, height: 26),
                          ),
                          title: 'Google Calendar',
                          subtitle: 'Connect Gmail & Sheets to enable',
                          onConnect: () async {
                            await context.push('/google-connect');
                            if (mounted) _loadGoogleStatus();
                          },
                        ),
                      ),
                    if (!_telegramLinked)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        child: _buildMockDisconnectedLikeGoogleRow(
                          context,
                          leading: _mockIconLeading(
                            context,
                            Image.network(_telegramIconUrl, width: 26, height: 26),
                          ),
                          title: 'Telegram',
                          subtitle: _loadingTelegramStatus
                              ? 'Checking status...'
                              : 'Chat with Jackie AI · Send receipts',
                          onConnect: _connectTelegram,
                        ),
                      ),
                    if (!googleConnected)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: Responsive.getResponsiveValue(
                            context,
                            mobile: 10.0,
                            tablet: 12.0,
                            desktop: 14.0,
                          ),
                        ),
                        child: _withEntranceAnimation(
                          _buildMockDisconnectedDriveRow(context),
                          (a) => a
                              .fadeIn(delay: 600.ms, duration: 300.ms)
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 600.ms,
                                duration: 300.ms,
                              ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                      child: _withEntranceAnimation(
                        _buildMockDisconnectedQuadrantRow(context),
                        (a) => a
                            .fadeIn(delay: 700.ms, duration: 300.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0,
                              delay: 700.ms,
                              duration: 300.ms,
                            ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 12.0,
                          desktop: 14.0,
                        ),
                      ),
                      child: _withEntranceAnimation(
                        _buildMockDisconnectedRagRow(context),
                        (a) => a
                            .fadeIn(delay: 800.ms, duration: 300.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0,
                              delay: 800.ms,
                              duration: 300.ms,
                            ),
                      ),
                    ),

                    SizedBox(
                      height: Responsive.getResponsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                    ),

                    // Info Footer
                    _withEntranceAnimation(
                      _buildInfoFooter(context, isMobile),
                      (a) => a.fadeIn(delay: 1200.ms, duration: 300.ms),
                    ),
                  ],
                ),
              ),

              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/services'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected Services',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 26.0,
              tablet: 28.0,
              desktop: 32.0,
            ),
            fontWeight: FontWeight.bold,
            color: _primaryText(context),
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
          'Manage your integrations',
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(
              context,
              mobile: 13.0,
              tablet: 14.0,
              desktop: 15.0,
            ),
            color:
                (isDark
                        ? AppColors.textCyan200.withOpacity(0.7)
                        : const Color(0xFF5B7B92))
                    .withOpacity(1),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(
    BuildContext context,
    bool isMobile,
    int connectedCount,
    int totalActions,
  ) {
    return Row(
      children: [
        Expanded(
          child:
              Container(
                    padding: EdgeInsets.all(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 20.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      gradient: _panelGradient(context),
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                      ),
                      border: Border.all(
                        color: _surfaceBorder(context),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.checkCircle,
                              size: Responsive.getResponsiveValue(
                                context,
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                              color: const Color(0xFF10B981),
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
                              '$connectedCount',
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 22.0,
                                  tablet: 24.0,
                                  desktop: 26.0,
                                ),
                                fontWeight: FontWeight.bold,
                                color: _primaryText(context),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveValue(
                                context,
                                mobile: 3.0,
                                tablet: 4.0,
                                desktop: 5.0,
                              ),
                            ),
                            Text(
                              'Connected',
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
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 300.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    delay: 100.ms,
                    duration: 300.ms,
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
          child:
              Container(
                    padding: EdgeInsets.all(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 20.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      gradient: _panelGradient(context),
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                      ),
                      border: Border.all(
                        color: _surfaceBorder(context),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.trendingUp,
                              size: Responsive.getResponsiveValue(
                                context,
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                              color: AppColors.cyan400,
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
                              '$totalActions',
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 22.0,
                                  tablet: 24.0,
                                  desktop: 26.0,
                                ),
                                fontWeight: FontWeight.bold,
                                color: _primaryText(context),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveValue(
                                context,
                                mobile: 3.0,
                                tablet: 4.0,
                                desktop: 5.0,
                              ),
                            ),
                            Text(
                              'Total actions',
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
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    delay: 200.ms,
                    duration: 300.ms,
                  ),
        ),
      ],
    );
  }

  Widget _buildConnectedServiceCard(
    BuildContext context,
    bool isMobile,
    Map<String, dynamic> service,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissions = service['permissions'] as List<String>? ?? [];
    final usage = service['usage'] as int?;

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
        gradient: _panelGradient(context),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 16.0,
            tablet: 18.0,
            desktop: 20.0,
          ),
        ),
        border: Border.all(color: _surfaceBorder(context), width: 1),
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
          child: Column(
            children: [
              Row(
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
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.2),
                          AppColors.cyan500.withOpacity(0.2),
                        ],
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
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        service['emoji'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 22.0,
                            tablet: 24.0,
                            desktop: 26.0,
                          ),
                        ),
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
                          children: [
                            Expanded(
                              child: Text(
                                service['name'] as String,
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 15.0,
                                    desktop: 16.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText(context),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 6.0,
                                  tablet: 8.0,
                                  desktop: 10.0,
                                ),
                                vertical: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 2.0,
                                  tablet: 3.0,
                                  desktop: 4.0,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  Responsive.getResponsiveValue(
                                    context,
                                    mobile: 4.0,
                                    tablet: 5.0,
                                    desktop: 6.0,
                                  ),
                                ),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
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
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(
                                    width: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 3.0,
                                      tablet: 4.0,
                                      desktop: 5.0,
                                    ),
                                  ),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: Responsive.getResponsiveValue(
                                        context,
                                        mobile: 10.0,
                                        tablet: 11.0,
                                        desktop: 12.0,
                                      ),
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
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
                          service['description'] as String,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                            color: isDark
                                ? AppColors.textCyan200.withOpacity(0.6)
                                : const Color(0xFF5B7B92),
                          ),
                        ),
                        if (service['lastSync'] != null) ...[
                          SizedBox(
                            height: Responsive.getResponsiveValue(
                              context,
                              mobile: 6.0,
                              tablet: 8.0,
                              desktop: 10.0,
                            ),
                          ),
                          Text(
                            'Last sync: ${service['lastSync']}',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveValue(
                                context,
                                mobile: 11.0,
                                tablet: 12.0,
                                desktop: 13.0,
                              ),
                              color: isDark
                                  ? AppColors.cyan400.withOpacity(0.5)
                                  : const Color(0xFF7A96AA),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 6.0,
                      tablet: 8.0,
                      desktop: 10.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Handle settings
                    },
                    child: Container(
                      padding: EdgeInsets.all(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 7.0,
                          tablet: 8.0,
                          desktop: 9.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 8.0,
                            tablet: 9.0,
                            desktop: 10.0,
                          ),
                        ),
                        border: Border.all(
                          color: AppColors.cyan500.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.settings,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        color: AppColors.cyan400,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              // Permissions & Usage
              Container(
                padding: EdgeInsets.only(
                  top: Responsive.getResponsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  ),
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _surfaceBorder(context), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Wrap(
                      spacing: Responsive.getResponsiveValue(
                        context,
                        mobile: 4.0,
                        tablet: 5.0,
                        desktop: 6.0,
                      ),
                      runSpacing: Responsive.getResponsiveValue(
                        context,
                        mobile: 4.0,
                        tablet: 5.0,
                        desktop: 6.0,
                      ),
                      children: [
                        ...permissions.take(2).map((perm) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              ),
                              vertical: Responsive.getResponsiveValue(
                                context,
                                mobile: 2.0,
                                tablet: 3.0,
                                desktop: 4.0,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyan500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                ),
                              ),
                              border: Border.all(
                                color: AppColors.cyan500.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              perm,
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
                        }),
                        if (permissions.length > 2)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              ),
                              vertical: Responsive.getResponsiveValue(
                                context,
                                mobile: 2.0,
                                tablet: 3.0,
                                desktop: 4.0,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyan500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                ),
                              ),
                              border: Border.all(
                                color: AppColors.cyan500.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '+${permissions.length - 2}',
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
                          ),
                      ],
                    ),
                    if (usage != null)
                      Text(
                        '$usage actions',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: isDark
                              ? AppColors.cyan400.withOpacity(0.6)
                              : const Color(0xFF5B7B92),
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

  // ignore: unused_element
  Widget _buildAvailableServiceCard(
    BuildContext context,
    bool isMobile,
    Map<String, dynamic> service,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        gradient: _panelGradient(context, opacity: 0.2),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
        ),
        border: Border.all(color: _surfaceBorder(context), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                      color: AppColors.cyan500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 8.0,
                          tablet: 9.0,
                          desktop: 10.0,
                        ),
                      ),
                      border: Border.all(
                        color: AppColors.cyan500.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        service['emoji'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 22.0,
                            desktop: 24.0,
                          ),
                        ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 13.0,
                            tablet: 14.0,
                            desktop: 15.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: _primaryText(context),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 3.0,
                          tablet: 4.0,
                          desktop: 5.0,
                        ),
                      ),
                      Text(
                        service['description'] as String,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: isDark
                              ? AppColors.cyan400.withOpacity(0.5)
                              : const Color(0xFF7A96AA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Handle connect
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
                    color: AppColors.cyan500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 9.0,
                        desktop: 10.0,
                      ),
                    ),
                    border: Border.all(
                      color: AppColors.cyan500.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      fontWeight: FontWeight.w500,
                      color: AppColors.cyan400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockDisconnectedDriveRow(BuildContext context) {
    return _buildMockDisconnectedLikeGoogleRow(
      context,
      leading: _mockIconLeading(
        context,
        Image.network(_driveIconUrl, width: 26, height: 26),
      ),
      title: 'Google Drive',
      subtitle: 'Files and folders access',
      onConnect: () async {
        await context.push('/google-connect');
        if (mounted) _loadGoogleStatus();
      },
    );
  }

  Widget _buildMockDisconnectedQuadrantRow(BuildContext context) {
    return _buildMockDisconnectedLikeGoogleRow(
      context,
      leading: _mockIconLeading(
        context,
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Q',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      title: 'Quadrant',
      subtitle: 'Task prioritization and planning',
      onConnect: () => _showComingSoonSnack(context, 'Quadrant'),
    );
  }

  Widget _buildMockDisconnectedRagRow(BuildContext context) {
    return _buildMockDisconnectedLikeGoogleRow(
      context,
      leading: _mockIconLeading(
        context,
        Image.asset(
          'assets/images/rag_logo.png',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
        ),
      ),
      title: 'RAG Knowledge Base',
      subtitle: 'Upload PDF to train your AI assistant',
      onConnect: () => _showRagUploadBottomSheet(context),
      connectLabel: 'Upload PDF',
    );
  }

  Widget _buildMockDisconnectedLikeGoogleRow(
    BuildContext context, {
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onConnect,
    String connectLabel = 'Connect',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = Responsive.getResponsiveValue(
      context,
      mobile: 12.0,
      tablet: 13.0,
      desktop: 14.0,
    );

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
        gradient: _panelGradient(context, opacity: 0.2),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _surfaceBorder(context), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  leading,
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 13.0,
                            tablet: 14.0,
                            desktop: 15.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: _primaryText(context),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 3.0,
                          tablet: 4.0,
                          desktop: 5.0,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: isDark
                              ? AppColors.cyan400.withOpacity(0.5)
                              : const Color(0xFF7A96AA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: onConnect,
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
                    color: AppColors.cyan500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 9.0,
                        desktop: 10.0,
                      ),
                    ),
                    border: Border.all(
                      color: AppColors.cyan500.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    connectLabel,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      fontWeight: FontWeight.w500,
                      color: AppColors.cyan400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnack(BuildContext context, String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$serviceName connection coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRagUploadBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RagUploadSheet(),
    );
  }

  Widget _googleDualLogoLeading(BuildContext context, {required bool compact}) {
    final boxH = Responsive.getResponsiveValue(
      context,
      mobile: compact ? 36.0 : 44.0,
      tablet: compact ? 40.0 : 48.0,
      desktop: compact ? 44.0 : 52.0,
    );
    final boxW = Responsive.getResponsiveValue(
      context,
      mobile: compact ? 58.0 : 64.0,
      tablet: compact ? 62.0 : 68.0,
      desktop: compact ? 66.0 : 72.0,
    );
    final radius = Responsive.getResponsiveValue(
      context,
      mobile: compact ? 8.0 : 10.0,
      tablet: compact ? 9.0 : 11.0,
      desktop: compact ? 10.0 : 12.0,
    );
    return Container(
      width: boxW,
      height: boxH,
      decoration: BoxDecoration(
        color: AppColors.cyan500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(_gmailIconUrl, width: 26, height: 26),
            const SizedBox(width: 4),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF0F9D58),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.table_chart,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoogleReconnectBottomSheet(
    BuildContext context,
    String? googleEmail,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryDarker : const Color(0xFFF7FBFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Gmail & Sheets Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryText(context),
                    ),
                  ),
                  if (googleEmail != null && googleEmail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      googleEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.cyan400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: AppColors.cyan500.withOpacity(0.2), height: 1),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await context.push('/google-connect');
                      if (mounted) {
                        _loadGoogleStatus();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            color: AppColors.cyan400,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Reconnect account',
                              style: TextStyle(
                                fontSize: 16,
                                color: _primaryText(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: isDark
                              ? AppColors.primaryMedium
                              : const Color(0xFFF7FBFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Disconnect Google Account?',
                            style: TextStyle(
                              color: _primaryText(context),
                              fontSize: 18,
                            ),
                          ),
                          content: Text(
                            'This will remove access to Gmail and Google Sheets features.',
                            style: TextStyle(
                              color: _secondaryText(context),
                              fontSize: 14,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.cyan400.withOpacity(0.9),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final token = prefs.getString(_tokenKey);
                                  if (token == null || token.isEmpty) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to disconnect, please try again',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final res = await http.post(
                                    Uri.parse(
                                      '$apiRootUrl/google-connect/disconnect',
                                    ),
                                    headers: {
                                      'Authorization': 'Bearer $token',
                                      'Content-Type': 'application/json',
                                    },
                                  );

                                  if (!mounted) return;

                                  if (res.statusCode >= 200 &&
                                      res.statusCode < 300) {
                                    Navigator.of(dialogContext).pop();
                                    _loadGoogleStatus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Google account disconnected',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to disconnect, please try again',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to disconnect, please try again',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Disconnect',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.unplug,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Disconnect',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.close,
                            color: AppColors.textCyan200.withOpacity(0.8),
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.textCyan200.withOpacity(0.85)
                                  : const Color(0xFF5B7B92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Mirrors [_buildConnectedServiceCard] (Uber) layout for the Google integration.
  Widget _buildGoogleConnectedLikeUberCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = _googleStatus.googleEmail;
    final radius = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 14.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: _panelGradient(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _surfaceBorder(context), width: 1),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _googleDualLogoLeading(context, compact: false),
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
                        children: [
                          Expanded(
                            child: Text(
                              'Gmail & Sheets',
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 14.0,
                                  tablet: 15.0,
                                  desktop: 16.0,
                                ),
                                fontWeight: FontWeight.w600,
                                color: _primaryText(context),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              ),
                              vertical: Responsive.getResponsiveValue(
                                context,
                                mobile: 2.0,
                                tablet: 3.0,
                                desktop: 4.0,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                ),
                              ),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 3.0,
                                    tablet: 4.0,
                                    desktop: 5.0,
                                  ),
                                ),
                                Text(
                                  'Connected',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 10.0,
                                      tablet: 11.0,
                                      desktop: 12.0,
                                    ),
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
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
                        'Email summaries · Finance tracker',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          ),
                          color: isDark
                              ? AppColors.textCyan200.withOpacity(0.6)
                              : const Color(0xFF5B7B92),
                        ),
                      ),
                      if (email != null && email.isNotEmpty) ...[
                        SizedBox(
                          height: Responsive.getResponsiveValue(
                            context,
                            mobile: 6.0,
                            tablet: 8.0,
                            desktop: 10.0,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                            color: const Color(0xFF10B981).withOpacity(0.85),
                          ),
                        ),
                      ],
                      SizedBox(
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        ),
                      ),
                      Text(
                        'Last connected: just now',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: isDark
                              ? AppColors.cyan400.withOpacity(0.5)
                              : const Color(0xFF7A96AA),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showGoogleReconnectBottomSheet(context, email),
                  child: Container(
                    padding: EdgeInsets.all(
                      Responsive.getResponsiveValue(
                        context,
                        mobile: 7.0,
                        tablet: 8.0,
                        desktop: 9.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyan500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 8.0,
                          tablet: 9.0,
                          desktop: 10.0,
                        ),
                      ),
                      border: Border.all(
                        color: AppColors.cyan500.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.settings,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                      color: AppColors.cyan400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                top: Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: _surfaceBorder(context), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: Responsive.getResponsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 5.0,
                      desktop: 6.0,
                    ),
                    runSpacing: Responsive.getResponsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 5.0,
                      desktop: 6.0,
                    ),
                    children: ['Send emails', 'Manage sheets'].map((perm) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.getResponsiveValue(
                            context,
                            mobile: 6.0,
                            tablet: 8.0,
                            desktop: 10.0,
                          ),
                          vertical: Responsive.getResponsiveValue(
                            context,
                            mobile: 2.0,
                            tablet: 3.0,
                            desktop: 4.0,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.getResponsiveValue(
                              context,
                              mobile: 4.0,
                              tablet: 5.0,
                              desktop: 6.0,
                            ),
                          ),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          perm,
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
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same structure as [_buildAvailableServiceCard] for the not-connected state.
  Widget _buildGoogleDisconnectedRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        gradient: _panelGradient(context, opacity: 0.2),
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
        ),
        border: Border.all(color: _surfaceBorder(context), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 13.0,
            desktop: 14.0,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _googleDualLogoLeading(context, compact: true),
                  SizedBox(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gmail & Sheets',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 13.0,
                            tablet: 14.0,
                            desktop: 15.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: _primaryText(context),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.getResponsiveValue(
                          context,
                          mobile: 3.0,
                          tablet: 4.0,
                          desktop: 5.0,
                        ),
                      ),
                      Text(
                        'Email summaries · Finance tracker',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: isDark
                              ? AppColors.cyan400.withOpacity(0.5)
                              : const Color(0xFF7A96AA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _loadingGoogleStatus
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.cyan400,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () async {
                        await context.push('/google-connect');
                        if (mounted) {
                          _loadGoogleStatus();
                        }
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
                          color: AppColors.cyan500.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            Responsive.getResponsiveValue(
                              context,
                              mobile: 8.0,
                              tablet: 9.0,
                              desktop: 10.0,
                            ),
                          ),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                            fontWeight: FontWeight.w500,
                            color: AppColors.cyan400,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFooter(BuildContext context, bool isMobile) {
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
        'All connections are encrypted and can be removed at any time. You control what data AVA can access.',
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

  Widget _buildConnectedCalendarCard(BuildContext context) {
    final email = _googleStatus.googleEmail;
    return _buildMockConnectedLikeGoogleCard(
      context: context,
      leading: _mockIconLeading(
        context,
        Image.network(_calendarIconUrl, width: 26, height: 26),
      ),
      title: 'Google Calendar',
      subtitle: 'Meeting detection & scheduling',
      chips: const ['Read events', 'Create events'],
      secondary: (email != null && email.isNotEmpty)
          ? email
          : 'Powered by Gmail & Sheets connection',
      secondaryColor: (email != null && email.isNotEmpty)
          ? const Color(0xFF10B981)
          : null,
    );
  }

  Widget _buildConnectedDriveCard(BuildContext context) {
    final email = _googleStatus.googleEmail;
    return _buildMockConnectedLikeGoogleCard(
      context: context,
      leading: _mockIconLeading(
        context,
        Image.network(_driveIconUrl, width: 26, height: 26),
      ),
      title: 'Google Drive',
      subtitle: 'Knowledge base & file storage',
      chips: const ['Read files', 'Upload files'],
      secondary: (email != null && email.isNotEmpty)
          ? email
          : 'Powered by Google connection',
      secondaryColor: (email != null && email.isNotEmpty)
          ? const Color(0xFF10B981)
          : null,
    );
  }

  Widget _buildMockConnectedTelegramCard(BuildContext context) {
    return _buildMockConnectedLikeGoogleCard(
      context: context,
      leading: _mockIconLeading(
        context,
        Image.network(_telegramIconUrl, width: 26, height: 26),
      ),
      title: 'Telegram',
      subtitle: 'Chat assistant and notifications',
      chips: const ['Read messages', 'Send messages'],
      secondary: _telegramChatId != null
          ? 'Chat ID: $_telegramChatId'
          : 'Last sync: just now',
      secondaryColor: _telegramChatId != null
          ? const Color(0xFF10B981)
          : null,
    );
  }

  Widget _buildMockConnectedLinkedInCard(BuildContext context) {
    return _buildMockConnectedLikeGoogleCard(
      context: context,
      leading: _mockIconLeading(
        context,
        Image.network(_linkedinIconUrl, width: 26, height: 26),
      ),
      title: 'LinkedIn',
      subtitle: 'Network and job insights',
      chips: const ['Read profile', 'Post updates'],
      secondary: 'Last sync: 2 hours ago',
    );
  }

  Widget _mockIconLeading(BuildContext context, Widget child) {
    final size = Responsive.getResponsiveValue(
      context,
      mobile: 44.0,
      tablet: 48.0,
      desktop: 52.0,
    );
    final radius = Responsive.getResponsiveValue(
      context,
      mobile: 10.0,
      tablet: 11.0,
      desktop: 12.0,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cyan500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildMockConnectedLikeGoogleCard({
    required BuildContext context,
    required Widget leading,
    required String title,
    required String subtitle,
    required List<String> chips,
    required String secondary,
    Color? secondaryColor,
  }) {
    final radius = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(
        Responsive.getResponsiveValue(
          context,
          mobile: 14.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1), width: 1),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
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
                        children: [
                          Expanded(
                            child: Text(
                              title,
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
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              ),
                              vertical: Responsive.getResponsiveValue(
                                context,
                                mobile: 2.0,
                                tablet: 3.0,
                                desktop: 4.0,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Responsive.getResponsiveValue(
                                  context,
                                  mobile: 4.0,
                                  tablet: 5.0,
                                  desktop: 6.0,
                                ),
                              ),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.getResponsiveValue(
                                    context,
                                    mobile: 3.0,
                                    tablet: 4.0,
                                    desktop: 5.0,
                                  ),
                                ),
                                Text(
                                  'Connected',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 10.0,
                                      tablet: 11.0,
                                      desktop: 12.0,
                                    ),
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
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
                        subtitle,
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
                          mobile: 6.0,
                          tablet: 8.0,
                          desktop: 10.0,
                        ),
                      ),
                      Text(
                        secondary,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveValue(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                          color: secondaryColor ??
                              AppColors.cyan400.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  ),
                ),
                Container(
                  child: GestureDetector(
                    onTap: () =>
                        _showMockServiceSettingsBottomSheet(context, title),
                    child: Container(
                      padding: EdgeInsets.all(
                        Responsive.getResponsiveValue(
                          context,
                          mobile: 7.0,
                          tablet: 8.0,
                          desktop: 9.0,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          Responsive.getResponsiveValue(
                            context,
                            mobile: 8.0,
                            tablet: 9.0,
                            desktop: 10.0,
                          ),
                        ),
                        border: Border.all(
                          color: AppColors.cyan500.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.settings,
                        size: Responsive.getResponsiveValue(
                          context,
                          mobile: 14.0,
                          tablet: 16.0,
                          desktop: 18.0,
                        ),
                        color: AppColors.cyan400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: Responsive.getResponsiveValue(
                context,
                mobile: 10.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                top: Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: Responsive.getResponsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 5.0,
                      desktop: 6.0,
                    ),
                    runSpacing: Responsive.getResponsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 5.0,
                      desktop: 6.0,
                    ),
                    children: chips.take(2).map((perm) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.getResponsiveValue(
                            context,
                            mobile: 6.0,
                            tablet: 8.0,
                            desktop: 10.0,
                          ),
                          vertical: Responsive.getResponsiveValue(
                            context,
                            mobile: 2.0,
                            tablet: 3.0,
                            desktop: 4.0,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.getResponsiveValue(
                              context,
                              mobile: 4.0,
                              tablet: 5.0,
                              desktop: 6.0,
                            ),
                          ),
                          border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          perm,
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
                    }).toList(),
                  ),
                  Text(
                    '',
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
    );
  }

  void _showMockServiceSettingsBottomSheet(
    BuildContext context,
    String serviceName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryDarker,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$serviceName Settings',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.cyan500.withOpacity(0.2), height: 1),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$serviceName reconnect coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            color: AppColors.cyan400,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Reconnect account',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Disconnect feature coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.unplug,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Disconnect',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.close,
                            color: AppColors.textCyan200.withOpacity(0.8),
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textCyan200.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RagUploadSheet extends StatefulWidget {
  @override
  State<_RagUploadSheet> createState() => _RagUploadSheetState();
}

class _RagUploadSheetState extends State<_RagUploadSheet> {
  bool _isUploading = false;
  String? _errorMessage;
  String? _successFileName;
  final _service = RagUploadService();

  Future<void> _pickAndUpload() async {
    setState(() {
      _isUploading = false;
      _errorMessage = null;
      _successFileName = null;
    });

    // Pick PDF file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) {
      setState(() => _errorMessage = 'Could not access file path');
      return;
    }

    final file = File(picked.path!);
    final fileName = picked.name;

    setState(() => _isUploading = true);

    try {
      await _service.uploadPdf(file, fileName);
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _successFileName = fileName;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryDarker,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  _successFileName != null
                      ? LucideIcons.checkCircle
                      : LucideIcons.fileText,
                  size: 32,
                  color: _successFileName != null
                      ? const Color(0xFF10B981)
                      : const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _successFileName != null
                    ? 'Upload Complete!'
                    : 'Upload Knowledge Base',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _successFileName != null
                    ? '$_successFileName has been uploaded to your Google Drive and your AI assistant is being updated.'
                    : 'Upload a PDF to train your Vapi AI phone assistant. The file will be stored in your Google Drive (AVA Knowledge Base folder) and indexed automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textCyan200.withOpacity(0.65),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (_successFileName == null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.upload, size: 18),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Choose PDF File',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              if (_successFileName != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _pickAndUpload,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text(
                      'Replace with New PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isUploading
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan400,
                    side: const BorderSide(
                      color: AppColors.cyan500,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _successFileName != null ? 'Done' : 'Cancel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
