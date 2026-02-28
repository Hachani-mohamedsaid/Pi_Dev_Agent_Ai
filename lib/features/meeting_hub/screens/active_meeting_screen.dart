import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/meeting_hub_mock_data.dart';

/// Active meeting UI: video grid, controls, AI suggestions, live transcript.
/// Same structure as phone_agent (feature screens + data).
class ActiveMeetingScreen extends StatefulWidget {
  const ActiveMeetingScreen({super.key});

  @override
  State<ActiveMeetingScreen> createState() => _ActiveMeetingScreenState();
}

class _ActiveMeetingScreenState extends State<ActiveMeetingScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  int? _copiedIndex;

  void _copySuggestion(String text, int index) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedIndex = index);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIndex = null);
    });
  }

  void _endCall() {
    context.push('/meeting-transcript/current');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, padding),
              Expanded(
                child: isMobile
                    ? _buildMobileLayout(context, padding)
                    : _buildDesktopLayout(context, padding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/meetings'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.chevronLeft, color: AppColors.cyan400, size: 22),
                const SizedBox(width: 6),
                Text('Exit Meeting', style: TextStyle(color: AppColors.cyan400, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.6), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Text('Recording', style: TextStyle(color: const Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double padding) {
    // No scroll: video fixed at top, AI panel expands to fill rest (no bottom bar).
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVideoSection(context, isMobile: true),
          const SizedBox(height: 12),
          Expanded(child: _buildAIPanel(context, isMobile: true)),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 7, child: _buildVideoSection(context, isMobile: false)),
          SizedBox(width: Responsive.getResponsiveValue(context, mobile: 0, tablet: 16, desktop: 20)),
          Expanded(flex: 3, child: _buildAIPanel(context, isMobile: false)),
        ],
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context, {required bool isMobile}) {
    final minH = Responsive.getResponsiveValue(context, mobile: 320.0, tablet: 380.0, desktop: 480.0);
    // On mobile we're inside SingleChildScrollView: give fixed height so inner Expanded has bounded constraints.
    return Container(
      height: isMobile ? minH : null,
      constraints: isMobile ? null : BoxConstraints(minHeight: minH),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0f172a).withOpacity(0.95),
            const Color(0xFF1e293b).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mainH = constraints.maxHeight * 0.6;
                      final tileH = (constraints.maxHeight - mainH - 12) / 2;
                      return Column(
                        children: [
                          _buildParticipantTile(context, label: 'Sarah Chen', initials: 'SC', isSpeaking: true, height: mainH),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildParticipantTile(context, label: 'Mike Rodriguez', initials: 'MR', height: tileH)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildParticipantTile(context, label: 'Alex Kim', initials: 'AK', height: tileH)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF334155), const Color(0xFF1e293b)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF14b8a6), AppColors.cyan500]),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text('You', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic, isActive: _isMuted, onTap: () => setState(() => _isMuted = !_isMuted)),
                const SizedBox(width: 16),
                _buildControlButton(icon: _isVideoOff ? LucideIcons.videoOff : LucideIcons.video, isActive: _isVideoOff, onTap: () => setState(() => _isVideoOff = !_isVideoOff)),
                const SizedBox(width: 16),
                _buildControlButton(icon: LucideIcons.phone, isActive: true, onTap: _endCall, isEndCall: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(
    BuildContext context, {
    required String label,
    required String initials,
    bool isSpeaking = false,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF334155), const Color(0xFF1e293b)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: height * 0.35,
            height: height * 0.35,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.cyan500, AppColors.blue500]), shape: BoxShape.circle),
            child: Center(child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: height * 0.12))),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          if (isSpeaking) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.volume2, size: 14, color: Colors.green.shade400),
                const SizedBox(width: 4),
                Text('Speaking', style: TextStyle(color: Colors.green.shade400, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required bool isActive, required VoidCallback onTap, bool isEndCall = false}) {
    final bg = isEndCall ? const Color(0xFFEF4444) : (isActive ? const Color(0xFFEF4444) : const Color(0xFF334155).withOpacity(0.85));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildAIPanel(BuildContext context, {required bool isMobile}) {
    final suggestions = mockAiSuggestions;
    final liveTranscript = mockLiveTranscript;
    // On mobile we're inside Expanded so no fixed height; on desktop use minHeight.
    return Container(
      constraints: isMobile ? null : const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight.withOpacity(0.6), AppColors.primaryDarker.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.cyan400,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.cyan400.withOpacity(0.5), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Suggestions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 17.0, desktop: 18.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final s = suggestions[index];
                  final copied = _copiedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.cyan500.withOpacity(0.15), AppColors.blue500.withOpacity(0.15)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cyan500.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.text, style: TextStyle(color: AppColors.textCyan200, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(s.context, style: TextStyle(color: AppColors.cyan400.withOpacity(0.65), fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copySuggestion(s.text, index),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cyan500.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: copied
                                  ? Text('✓', style: TextStyle(color: Colors.green.shade400, fontSize: 12, fontWeight: FontWeight.w600))
                                  : Icon(LucideIcons.copy, size: 16, color: AppColors.cyan400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.cyan500.withOpacity(0.2)))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Live Transcript', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...liveTranscript.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: AppColors.textCyan200.withOpacity(0.85), fontSize: 12),
                        children: [
                          TextSpan(text: '${line.speaker}: ', style: const TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600)),
                          TextSpan(text: '${line.text} '),
                          TextSpan(text: line.time, style: TextStyle(color: AppColors.cyan400.withOpacity(0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
