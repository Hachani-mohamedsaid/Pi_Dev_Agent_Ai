import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/meeting_api_service.dart';
import '../../../services/meeting_service.dart';
import '../../../services/transcription_service.dart';
import '../../../services/suggestion_service.dart';
import '../data/meeting_hub_mock_data.dart';
import '../models/meeting_model.dart';

/// Active meeting UI: Zego video view, controls, AI suggestions, live transcript.
class ActiveMeetingScreen extends StatefulWidget {
  final String roomID;
  final String userID;
  final String userName;
  final bool isStart;

  const ActiveMeetingScreen({
    super.key,
    required this.roomID,
    required this.userID,
    required this.userName,
    this.isStart = true,
  });

  @override
  State<ActiveMeetingScreen> createState() => _ActiveMeetingScreenState();
}

class _ActiveMeetingScreenState extends State<ActiveMeetingScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  int? _copiedIndex;
  bool _meetingReady = false;
  bool _roomConnected = false;
  bool _permissionsGranted = false;
  bool _permissionsDenied = false;
  bool _initFailed = false;
  String _initErrorMessage = '';
  Widget? _previewWidget;
  final Map<String, Widget> _remoteViews = {};
  final Map<String, int> _remoteViewIds = {};
  String? _activeSpeakerStreamID;
  final List<String> _liveTranscriptLines = [];
  List<String> _suggestions = [];
  StreamSubscription<String>? _transcriptionSub;
  StreamSubscription<List<String>>? _suggestionSub;
  StreamSubscription<String>? _suggestionErrorSub;
  String? _suggestionErrorMessage;
  /// Backend meeting record id (set after createMeeting on start).
  String? _meetingId;
  DateTime? _meetingStartAt;
  final Set<String> _participantNames = <String>{};

  @override
  void initState() {
    super.initState();
    _participantNames.add(widget.userName.trim().isEmpty ? 'User' : widget.userName.trim());
    _initIfPermissionsGranted();
  }

  /// Permissions are requested on Meeting Hub before navigation. Here we only verify and init.
  Future<void> _initIfPermissionsGranted() async {
    if (mounted) {
      setState(() {
        _initFailed = false;
        _initErrorMessage = '';
      });
    }
    final cameraOk = (await Permission.camera.status).isGranted;
    final micOk = (await Permission.microphone.status).isGranted;
    if (!mounted) return;
    if (cameraOk && micOk) {
      setState(() => _permissionsGranted = true);
      await _initZegoAndMeeting();
    } else {
      setState(() => _permissionsDenied = true);
    }
  }

  Future<void> _initZegoAndMeeting() async {
    if (!_permissionsGranted) return;

    final engineReady = await MeetingService.instance.ensureInit();
    if (!engineReady || !mounted) {
      _setInitError(
        'Failed to initialize meeting engine.\nPlease check meeting configuration and try again.',
      );
      return;
    }

    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      if (state == ZegoRoomState.Connected && mounted) {
        setState(() => _roomConnected = true);
      }
    };
    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
      if (roomID != widget.roomID) return;
      for (final stream in streamList) {
        if (stream.user.userID == widget.userID) continue; // ignore own published stream
        if (updateType == ZegoUpdateType.Add) {
          final name = (stream.user.userName ?? '').trim();
          final fallback = (stream.user.userID ?? '').trim();
          _participantNames.add(name.isNotEmpty ? name : (fallback.isNotEmpty ? fallback : 'Participant'));
          _addRemoteStreamView(stream);
        } else if (updateType == ZegoUpdateType.Delete) {
          _removeRemoteStreamView(stream.streamID);
        }
      }
    };
    ZegoExpressEngine.onRemoteMicStateUpdate = (String streamID, ZegoRemoteDeviceState state) {
      if (!_remoteViews.containsKey(streamID) || !mounted) return;
      setState(() {
        if (state == ZegoRemoteDeviceState.Open) {
          _activeSpeakerStreamID = streamID;
        } else if (_activeSpeakerStreamID == streamID) {
          _activeSpeakerStreamID = null;
        }
      });
    };

    final isResumingCurrentMeeting =
        MeetingService.instance.hasActiveMeeting &&
        MeetingService.instance.currentRoomId == widget.roomID;

    if (!isResumingCurrentMeeting) {
      final ok = widget.isStart
          ? await MeetingService.instance.startMeeting(widget.roomID, widget.userID, widget.userName)
          : await MeetingService.instance.joinMeeting(widget.roomID, widget.userID, widget.userName);
      if (!ok || !mounted) {
        _setInitError(
          'Failed to join the meeting room.\nPlease verify your room ID and network, then try again.',
        );
        return;
      }
      // Create backend meeting record so we can append transcript and save summary later.
      try {
        _meetingStartAt = DateTime.now();
        final id = await MeetingApiService.instance.createMeeting(widget.roomID, DateTime.now());
        if (mounted) setState(() => _meetingId = id);
      } catch (_) {
        // Non-blocking: meeting still works; transcript/summary won't sync to backend.
      }
    } else if (mounted) {
      setState(() => _roomConnected = true);
    }
    Widget? preview;
    try {
      preview = await ZegoExpressEngine.instance.createCanvasView((viewID) async {
        await ZegoExpressEngine.instance.startPreview(
          canvas: ZegoCanvas.view(viewID),
          channel: ZegoPublishChannel.Main,
        );
        if (mounted) setState(() {});
      });
    } catch (_) {
      _setInitError(
        'Meeting preview failed to start.\nPlease close and reopen the meeting.',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _meetingReady = true;
      _previewWidget = preview ?? const SizedBox();
    });

    final transStream = TranscriptionService.instance.transcriptionStream(
      MeetingService.instance.audioChunkStream,
    ).asBroadcastStream();
    _transcriptionSub = transStream.listen((text) {
      // Transcript stream feeds ONLY the Live Transcript panel.
      if (!mounted) return;
      final cleaned = text.trim();
      if (cleaned.isEmpty) return;
      setState(() => _liveTranscriptLines.add(cleaned));
    });

    await _suggestionSub?.cancel();
    await _suggestionErrorSub?.cancel();
    if (!isResumingCurrentMeeting) {
      SuggestionService.instance.clearHistory();
      if (mounted) {
        setState(() {
          _suggestions = [];
          _suggestionErrorMessage = null;
        });
      }
    }
    SuggestionService.instance.startListening(transStream);
    _suggestionSub = SuggestionService.instance.suggestionStream.listen((list) {
      // Suggestion stream feeds ONLY the AI Suggestions panel cards.
      if (!mounted) return;
      print('Suggestion stream active, received list: $list');
      _applyIncomingSuggestions(list);
    });
    _suggestionErrorSub = SuggestionService.instance.errorStream.listen((error) {
      if (!mounted) return;
      setState(() {
        _suggestionErrorMessage = error.trim().isEmpty ? null : error;
      });
    });
  }

  void _applyIncomingSuggestions(List<String> incoming) {
    final normalized = incoming
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (normalized.isEmpty) return;

    // Prepend latest Claude suggestions, keep unique cards, max 3 visible.
    final merged = <String>[...normalized, ..._suggestions];
    final unique = <String>[];
    for (final s in merged) {
      if (!unique.contains(s)) unique.add(s);
      if (unique.length == 3) break;
    }
    setState(() => _suggestions = unique);
  }

  Future<void> _addRemoteStreamView(ZegoStream stream) async {
    final streamID = stream.streamID;
    if (_remoteViews.containsKey(streamID)) return;

    int? viewID;
    final widgetView = await ZegoExpressEngine.instance.createCanvasView((id) async {
      viewID = id;
      await ZegoExpressEngine.instance.startPlayingStream(
        streamID,
        canvas: ZegoCanvas.view(id),
      );
    });

    if (!mounted) {
      if (viewID != null) {
        await ZegoExpressEngine.instance.destroyCanvasView(viewID!);
      }
      return;
    }
    if (widgetView == null || viewID == null) return;

    setState(() {
      _remoteViews[streamID] = widgetView;
      _remoteViewIds[streamID] = viewID!;
    });
  }

  Future<void> _removeRemoteStreamView(String streamID) async {
    try {
      await ZegoExpressEngine.instance.stopPlayingStream(streamID);
    } catch (_) {}
    final viewID = _remoteViewIds.remove(streamID);
    if (viewID != null) {
      try {
        await ZegoExpressEngine.instance.destroyCanvasView(viewID);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _remoteViews.remove(streamID);
      if (_activeSpeakerStreamID == streamID) {
        _activeSpeakerStreamID = null;
      }
    });
  }

  Future<void> _clearRemoteViews() async {
    final streamIDs = _remoteViews.keys.toList();
    for (final streamID in streamIDs) {
      await _removeRemoteStreamView(streamID);
    }
  }

  void _setInitError(String message) {
    if (!mounted) return;
    setState(() {
      _initFailed = true;
      _initErrorMessage = message;
      _meetingReady = false;
      _roomConnected = false;
    });
  }

  void _copySuggestion(String text, int index) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedIndex = index);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIndex = null);
    });
  }

  Future<void> _endCall() async {
    final endAt = DateTime.now();
    await _clearRemoteViews();
    await MeetingService.instance.endMeeting();
    _transcriptionSub?.cancel();
    _suggestionSub?.cancel();
    _suggestionErrorSub?.cancel();
    final history = SuggestionService.instance.conversationHistory;
    final fullTranscript = history
        .map((text) => TranscriptLineModel(
              speaker: widget.userName.trim().isEmpty ? 'User' : widget.userName.trim(),
              text: text,
              timestamp: '',
            ))
        .toList();

    if (_meetingId != null && fullTranscript.isNotEmpty) {
      final startAt = _meetingStartAt;
      final durationMinutes = (startAt == null)
          ? null
          : endAt.difference(startAt).inSeconds <= 0
              ? 0
              : (endAt.difference(startAt).inSeconds / 60).ceil();
      final meetingTitle = 'Meeting - ${DateFormat('yyyy-MM-dd').format(endAt)}';
      try {
        await MeetingApiService.instance.appendTranscript(
          _meetingId!,
          fullTranscript,
          participants: _participantNames.toList(),
          durationMinutes: durationMinutes,
          endTime: endAt,
          title: meetingTitle,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    final meetingId = _meetingId ?? 'current';
    context.push('/meeting-transcript/$meetingId', extra: fullTranscript);
  }

  @override
  void dispose() {
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRemoteMicStateUpdate = null;
    _clearRemoteViews();
    _transcriptionSub?.cancel();
    _suggestionSub?.cancel();
    _suggestionErrorSub?.cancel();
    SuggestionService.instance.stopListening();
    super.dispose();
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
              _buildRoomIdChip(context, padding),
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

  void _copyRoomId() {
    Clipboard.setData(ClipboardData(text: widget.roomID));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cyan500,
      ),
    );
  }

  Future<void> _shareRoomInvite() async {
    final text =
        'Join my Ava meeting: https://stirring-sfogliatella-3cac75.netlify.app?room=${widget.roomID}';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Widget _buildRoomIdChip(BuildContext context, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 0, padding, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _copyRoomId,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan500.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Room: ${widget.roomID}',
                    style: TextStyle(
                      color: AppColors.textCyan200,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _copyRoomId,
                    child: Icon(LucideIcons.copy, size: 16, color: AppColors.cyan400),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _shareRoomInvite,
                    child: Icon(LucideIcons.share2, size: 16, color: AppColors.cyan400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share link & open on PC to join the same meeting',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
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
                  child: _buildVideoContent(),
                ),
              ],
            ),
          ),
          if (!_permissionsDenied && !_initFailed) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic,
                    isActive: _isMuted,
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      MeetingService.instance.setMute(_isMuted);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    icon: _isVideoOff ? LucideIcons.videoOff : LucideIcons.video,
                    isActive: _isVideoOff,
                    onTap: () {
                      setState(() => _isVideoOff = !_isVideoOff);
                      MeetingService.instance.setVideoOn(!_isVideoOff);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildControlButton(icon: LucideIcons.phone, isActive: true, onTap: _endCall, isEndCall: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_permissionsDenied) return _buildPermissionDeniedContent();
    if (_initFailed) return _buildInitFailedContent();
    if (!_meetingReady || !_roomConnected || _previewWidget == null) {
      return Center(
        child: Text(
          _meetingReady ? 'Connecting…' : 'Starting…',
          style: TextStyle(color: AppColors.textCyan200.withOpacity(0.8)),
        ),
      );
    }

    if (_remoteViews.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox.expand(child: _previewWidget),
      );
    }

    if (_remoteViews.length == 1) {
      final streamID = _remoteViews.keys.first;
      final remoteView = _remoteViews[streamID]!;
      return Stack(
        children: [
          Positioned.fill(child: _buildRemoteTile(streamID, remoteView)),
          _buildLocalOverlay(),
        ],
      );
    }

    final entries = _remoteViews.entries.toList();
    return Stack(
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: entries.length <= 4 ? 2 : 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final e = entries[index];
            return _buildRemoteTile(e.key, e.value);
          },
        ),
        _buildLocalOverlay(),
      ],
    );
  }

  Widget _buildRemoteTile(String streamID, Widget view) {
    final isActiveSpeaker = _activeSpeakerStreamID == streamID;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActiveSpeaker ? AppColors.cyan400 : Colors.transparent,
          width: isActiveSpeaker ? 2.5 : 1,
        ),
        boxShadow: isActiveSpeaker
            ? [
                BoxShadow(
                  color: AppColors.cyan400.withOpacity(0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: view,
      ),
    );
  }

  Widget _buildLocalOverlay() {
    return Positioned(
      right: 10,
      bottom: 10,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan500.withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _previewWidget ?? const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.videoOff, size: 48, color: AppColors.textCyan200.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Camera & microphone required',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textCyan200.withOpacity(0.9), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Go back to Meeting Hub and tap Start or Join again to see the permission prompts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textCyan200.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.chevronLeft, size: 20),
            label: const Text('Back to Meeting Hub'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.cyan500, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => openAppSettings(),
            icon: const Icon(LucideIcons.settings, size: 18),
            label: const Text('Open Settings'),
            style: TextButton.styleFrom(foregroundColor: AppColors.cyan400),
          ),
        ],
      ),
    );
  }

  Widget _buildInitFailedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertTriangle, size: 48, color: Colors.amber.withOpacity(0.9)),
          const SizedBox(height: 16),
          Text(
            'Meeting failed to start',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textCyan200.withOpacity(0.95), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _initErrorMessage.isEmpty ? 'Please try again.' : _initErrorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textCyan200.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _initIfPermissionsGranted,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.cyan500),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
            label: const Text('Back to Meeting Hub'),
            style: TextButton.styleFrom(foregroundColor: AppColors.cyan400),
          ),
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
    final liveTranscript = _liveTranscriptLines
        .map((t) => LiveTranscriptLine(speaker: 'Speaker', text: t, time: ''))
        .toList();
    final recentTranscript = liveTranscript.length > 6
        ? liveTranscript.sublist(liveTranscript.length - 6)
        : liveTranscript;
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
                itemCount: _suggestions.isEmpty ? 1 : _suggestions.length,
                itemBuilder: (context, index) {
                  if (_suggestions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Suggestions will appear here as the conversation continues.',
                        style: TextStyle(color: AppColors.textCyan200.withOpacity(0.7), fontSize: 13),
                      ),
                    );
                  }
                  final text = _suggestions[index];
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
                            child: Text(text, style: TextStyle(color: AppColors.textCyan200, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copySuggestion(text, index),
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
            if (_suggestionErrorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _suggestionErrorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
                  if (recentTranscript.isEmpty)
                    Text(
                      'No speech detected yet.',
                      style: TextStyle(color: AppColors.textCyan200.withOpacity(0.65), fontSize: 12),
                    )
                  else
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        itemCount: recentTranscript.length,
                        itemBuilder: (context, index) {
                          final line = recentTranscript[index];
                          return Padding(
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
                          );
                        },
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
}
