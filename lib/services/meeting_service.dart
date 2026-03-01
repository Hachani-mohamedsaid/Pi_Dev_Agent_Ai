import 'dart:async';
import 'dart:math' show sqrt;
import 'dart:typed_data';

import 'package:pi_dev_agentia/core/config/meeting_env.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// Zegocloud meeting: init, start/join/end room, mixed audio stream with silence-based chunking.
class MeetingService {
  MeetingService._();
  static final MeetingService instance = MeetingService._();

  static const _silenceThresholdDuration = Duration(milliseconds: 1500);
  static const _silenceRmsThreshold = 900; // higher threshold to avoid noise-only chunks
  static const _minChunkBytes = 24000; // avoid tiny chunks that confuse transcription

  final _audioChunkController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioChunkStream => _audioChunkController.stream;

  List<int> _audioBuffer = [];
  DateTime? _segmentStartedAt;
  DateTime? _lastLoudAt;
  bool _observerStarted = false;
  String? _currentStreamId;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentUserName;

  int _appId = 0;
  String _appSign = '';

  bool get hasActiveMeeting => _currentRoomId != null && _currentStreamId != null;
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;

  /// Initialize Zego engine using .env keys. Call once before start/join.
  Future<bool> ensureInit() async {
    if (_appId != 0) return true;
    final appIdStr = getMeetingEnv('ZEGOCLOUD_APP_ID');
    _appSign = getMeetingEnv('ZEGOCLOUD_APP_SIGN');
    if (appIdStr.isEmpty || _appSign.isEmpty) return false;
    _appId = int.tryParse(appIdStr) ?? 0;
    if (_appId == 0) return false;
    try {
      await ZegoExpressEngine.createEngineWithProfile(
        ZegoEngineProfile(_appId, ZegoScenario.Default, appSign: _appSign),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Start a new meeting (create room and publish).
  Future<bool> startMeeting(String roomID, String userID, String userName) async {
    if (!await ensureInit()) return false;
    _currentRoomId = roomID;
    _currentStreamId = '${userID}_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserId = userID;
    _currentUserName = userName;
    final user = ZegoUser(userID, userName);
    final config = ZegoRoomConfig(0, true, '');
    try {
      await ZegoExpressEngine.instance.loginRoom(roomID, user, config: config);
      await ZegoExpressEngine.instance.startPublishingStream(
        _currentStreamId!,
        channel: ZegoPublishChannel.Main,
      );
      await _startMixedAudioObserver();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Join an existing meeting (subscribe to existing streams).
  Future<bool> joinMeeting(String roomID, String userID, String userName) async {
    if (!await ensureInit()) return false;
    _currentRoomId = roomID;
    _currentStreamId = '${userID}_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserId = userID;
    _currentUserName = userName;
    final user = ZegoUser(userID, userName);
    final config = ZegoRoomConfig(0, true, '');
    try {
      await ZegoExpressEngine.instance.loginRoom(roomID, user, config: config);
      await ZegoExpressEngine.instance.startPublishingStream(
        _currentStreamId!,
        channel: ZegoPublishChannel.Main,
      );
      await _startMixedAudioObserver();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startMixedAudioObserver() async {
    if (_observerStarted) return;
    final param = ZegoAudioFrameParam(
      ZegoAudioSampleRate.SampleRate16K,
      ZegoAudioChannel.Mono,
    );
    ZegoExpressEngine.onMixedAudioData = _onMixedAudioData;
    await ZegoExpressEngine.instance.startAudioDataObserver(
      ZegoAudioDataCallbackBitMask.Mixed,
      param,
    );
    _observerStarted = true;
  }

  void _onMixedAudioData(Uint8List data, int dataLength, ZegoAudioFrameParam param) {
    if (dataLength <= 0) return;
    final bytes = dataLength < data.length ? data.sublist(0, dataLength) : data;
    final rms = _computeRms(bytes);
    final now = DateTime.now();

    if (rms >= _silenceRmsThreshold) {
      _segmentStartedAt ??= now;
      _lastLoudAt = now;
      for (var i = 0; i < bytes.length; i++) {
        _audioBuffer.add(bytes[i]);
      }
      return;
    }

    // Do not keep appending silence forever (causes hallucinated/random transcription).
    // We only emit once a speech segment ended with enough duration + bytes.
    if (_lastLoudAt != null && _segmentStartedAt != null) {
      final silenceDuration = now.difference(_lastLoudAt!);
      if (silenceDuration >= _silenceThresholdDuration) {
        final speechDuration = _lastLoudAt!.difference(_segmentStartedAt!);
        if (_audioBuffer.length >= _minChunkBytes &&
            speechDuration >= const Duration(milliseconds: 900)) {
          _audioChunkController.add(Uint8List.fromList(_audioBuffer));
        }
        _audioBuffer = [];
        _segmentStartedAt = null;
        _lastLoudAt = null;
      }
    }
  }

  int _computeRms(Uint8List b) {
    if (b.length < 2) return 0;
    var sum = 0.0;
    for (var i = 0; i < b.length - 1; i += 2) {
      final s = b[i] | (b[i + 1] << 8);
      final sample = s > 32767 ? s - 65536 : s;
      sum += sample * sample;
    }
    final n = (b.length ~/ 2).clamp(1, 0x7fffffff);
    return sqrt(sum / n).round();
  }

  /// Leave room and stop publishing/observing.
  Future<void> endMeeting() async {
    try {
      if (_observerStarted) {
        ZegoExpressEngine.onMixedAudioData = null;
        await ZegoExpressEngine.instance.stopAudioDataObserver();
        _observerStarted = false;
      }
      if (_currentStreamId != null) {
        await ZegoExpressEngine.instance.stopPublishingStream(channel: ZegoPublishChannel.Main);
        _currentStreamId = null;
      }
      if (_currentRoomId != null) {
        await ZegoExpressEngine.instance.logoutRoom(_currentRoomId);
        _currentRoomId = null;
      }
      _currentUserId = null;
      _currentUserName = null;
    } catch (_) {}
    _audioBuffer = [];
    _segmentStartedAt = null;
    _lastLoudAt = null;
  }

  /// Call when user toggles mute (optional, for UI sync).
  Future<void> setMute(bool mute) async {
    await ZegoExpressEngine.instance.mutePublishStreamAudio(mute, channel: ZegoPublishChannel.Main);
  }

  /// Call when user toggles video (optional).
  Future<void> setVideoOn(bool on) async {
    await ZegoExpressEngine.instance.enableCamera(on, channel: ZegoPublishChannel.Main);
  }

  void dispose() {
    _audioChunkController.close();
  }
}
