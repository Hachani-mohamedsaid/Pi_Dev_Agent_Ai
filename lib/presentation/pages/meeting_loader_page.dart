import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/meeting_service.dart';

/// Page qui récupère les meetings depuis le backend et redirige vers le premier.
class MeetingLoaderPage extends StatefulWidget {
  const MeetingLoaderPage({super.key});

  @override
  State<MeetingLoaderPage> createState() => _MeetingLoaderPageState();
}

class _MeetingLoaderPageState extends State<MeetingLoaderPage> {
  final MeetingService _service = MeetingService();
  bool _hasLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadAndNavigate() async {
    try {
      final meetings = await _service.fetchMeetings();
      if (!mounted) return;
      if (meetings.isNotEmpty) {
        context.go('/meeting/${meetings.first.meetingId}');
        return;
      }
    } catch (e) {
      if (mounted) _error = e.toString();
    }
    if (mounted) setState(() => _hasLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
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
          child: _hasLoaded
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error != null
                            ? 'Impossible de charger les réunions'
                            : 'Aucune réunion',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hasLoaded = false;
                            _error = null;
                          });
                          _loadAndNavigate();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
                  ),
                ),
        ),
      ),
    );
  }
}
