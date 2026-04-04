import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/google_connect_service.dart';

enum _GoogleConnectState { idle, waiting, connected }

class GoogleConnectPage extends StatefulWidget {
  const GoogleConnectPage({super.key});

  @override
  State<GoogleConnectPage> createState() => _GoogleConnectPageState();
}

class _GoogleConnectPageState extends State<GoogleConnectPage> {
  static const _tokenKey = 'auth_access_token';
  static const _pollInterval = Duration(seconds: 3);
  static const _pollTimeout = Duration(minutes: 2);

  final _service = GoogleConnectService();

  _GoogleConnectState _state = _GoogleConnectState.idle;
  String? _connectedEmail;
  Timer? _pollTimer;
  DateTime? _pollStarted;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _onConnectTapped() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _showSnackBar('You must be logged in to connect Google.');
      return;
    }

    setState(() => _state = _GoogleConnectState.waiting);

    String authUrl;
    try {
      authUrl = await _service.getAuthUrl(token);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _GoogleConnectState.idle);
      _showSnackBar('Could not reach AVA server. Try again.');
      return;
    }

    final uri = Uri.parse(authUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);

    _startPolling(token);
  }

  void _startPolling(String token) {
    _pollStarted = DateTime.now();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }

      if (DateTime.now().difference(_pollStarted!) >= _pollTimeout) {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() => _state = _GoogleConnectState.idle);
        _showSnackBar('Connection timed out. Please try again.');
        return;
      }

      try {
        final status = await _service.getStatus(token);
        if (!mounted) return;
        if (status.sheetReady) {
          _pollTimer?.cancel();
          setState(() {
            _state = _GoogleConnectState.connected;
            _connectedEmail = status.googleEmail;
          });
        }
      } catch (_) {
        // Keep polling — transient network error
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textWhite, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _GoogleConnectState.idle:
        return _buildIdleState();
      case _GoogleConnectState.waiting:
        return _buildWaitingState();
      case _GoogleConnectState.connected:
        return _buildConnectedState();
    }
  }

  Widget _buildIdleState() {
    return Padding(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google icon badge
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cyan500.withValues(alpha: 0.2),
                  AppColors.blue500.withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cyan500.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Text('G', style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
                fontFamily: 'Georgia',
              )),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Connect your Google Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'AVA needs access to your Gmail and Google Sheets to power your Finance Tracker and Email Summary features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textCyan200.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _onConnectTapped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Connect with Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return Padding(
      key: const ValueKey('waiting'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Waiting for Google authorization...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete the sign-in in your browser, then return to AVA.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textCyan200.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              setState(() => _state = _GoogleConnectState.idle);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.cyan400.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedState() {
    return Padding(
      key: const ValueKey('connected'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 48,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Google Account Connected',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          if (_connectedEmail != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.cyan500.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _connectedEmail!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.cyan400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Your Finance Tracker and Email Summary sheets are ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textCyan200.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
