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

class VoiceRecorder {
  static const _uuid = Uuid();
  static const maxDurationSeconds = 60;
  static const minDurationSeconds = 1;

  final _recorder = AudioRecorder();
  DateTime? _startTime;
  String? _currentFilePath;
  Timer? _maxDurationTimer;
  void Function()? _onMaxDurationReached;

  /// Check and request microphone permission
  Future<bool> ensurePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording. Returns false if permission denied or failed.
  Future<bool> start({void Function()? onMaxDurationReached}) async {
    if (!await ensurePermission()) return false;

    try {
      final uuid = _uuid.v4();
      _currentFilePath = await VoiceCacheManager.newVoiceFilePath(uuid);

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 24000,
          numChannels: 1,
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

  int get currentDurationSeconds {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  void dispose() {
    _maxDurationTimer?.cancel();
    _recorder.dispose();
  }
}
