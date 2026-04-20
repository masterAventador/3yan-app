import 'dart:async';

import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'voice_cache_manager.dart';

class RecordingResult {
  final String filePath;
  final int durationSeconds;
  RecordingResult(this.filePath, this.durationSeconds);
}

abstract class IVoiceRecorder {
  Future<bool> isPermissionGranted();
  Future<bool> requestPermission();
  Future<bool> start({void Function()? onMaxDurationReached});
  Future<RecordingResult?> stop();
  Future<void> cancel();
  int get currentDurationSeconds;
  void dispose();
}

class VoiceRecorder implements IVoiceRecorder {
  static const _uuid = Uuid();
  static const maxDurationSeconds = 60;
  static const minDurationSeconds = 1;
  static const _fileExt = 'm4a';

  final _recorder = AudioRecorder();
  DateTime? _startTime;
  String? _currentFilePath;
  Timer? _maxDurationTimer;
  void Function()? _onMaxDurationReached;

  /// Check current microphone permission status WITHOUT triggering system dialog.
  @override
  Future<bool> isPermissionGranted() async {
    return Permission.microphone.isGranted;
  }

  /// Request microphone permission (may trigger iOS system dialog).
  @override
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording. Caller must ensure permission is already granted
  /// (first-time grant should NOT immediately start recording — the long-press
  /// gesture is lost while the system permission dialog is showing).
  @override
  Future<bool> start({void Function()? onMaxDurationReached}) async {
    try {
      final uuid = _uuid.v4();
      _currentFilePath =
          await VoiceCacheManager.newVoiceFilePath(uuid, _fileExt);

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          // 44100 是 AAC 最稳的标准采样率；24000 在某些 iOS 版本上编码器初始化有 bug
          sampleRate: 44100,
          numChannels: 1,
          // AppDelegate 启动时已经 setCategory(.playAndRecord) + setActive(true)，
          // record 包不要再重复整套 session 初始化（会累加 500ms~2s 延迟）。
          // manageAudioSession 字段标 deprecated 但 record 5.x 目前没提供替代 API，仍然生效。
          // ignore: deprecated_member_use
          iosConfig: IosRecordConfig(manageAudioSession: false),
        ),
        path: _currentFilePath!,
      );

      _startTime = DateTime.now();
      _onMaxDurationReached = onMaxDurationReached;
      _maxDurationTimer = Timer(const Duration(seconds: maxDurationSeconds), () {
        _onMaxDurationReached?.call();
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stop and return result, or null if too short (< 1s)
  @override
  Future<RecordingResult?> stop() async {
    _maxDurationTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path == null || _startTime == null) return null;

      final duration = DateTime.now().difference(_startTime!).inSeconds;
      _startTime = null;
      _currentFilePath = null;

      if (duration < minDurationSeconds) {
        await VoiceCacheManager.deleteFile(path);
        return null;
      }

      final clampedDuration =
          duration > maxDurationSeconds ? maxDurationSeconds : duration;
      return RecordingResult(path, clampedDuration);
    } catch (_) {
      return null;
    }
  }

  /// Cancel and delete local file
  @override
  Future<void> cancel() async {
    _maxDurationTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path != null) {
        await VoiceCacheManager.deleteFile(path);
      }
    } catch (_) {}
    _startTime = null;
    _currentFilePath = null;
  }

  @override
  int get currentDurationSeconds {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  @override
  void dispose() {
    _maxDurationTimer?.cancel();
    _recorder.dispose();
  }
}
