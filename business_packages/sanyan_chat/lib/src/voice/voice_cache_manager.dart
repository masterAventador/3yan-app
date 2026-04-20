import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VoiceCacheManager {
  static const _dirName = 'sanyan_voice';
  static const _maxAgeMs = 7 * 24 * 60 * 60 * 1000; // 7 days

  /// Get voice cache directory, auto-create if missing
  static Future<Directory> getCacheDir() async {
    final cacheDir = await getApplicationCacheDirectory();
    final voiceDir = Directory('${cacheDir.path}/$_dirName');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    return voiceDir;
  }

  /// Generate a new voice file path with the given extension (e.g. 'wav', 'm4a')
  static Future<String> newVoiceFilePath(String uuid, String ext) async {
    final dir = await getCacheDir();
    return '${dir.path}/$uuid.$ext';
  }

  /// Delete a single file
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Clean up files older than 7 days
  static Future<void> cleanupOldFiles() async {
    try {
      final dir = await getCacheDir();
      final now = DateTime.now().millisecondsSinceEpoch;
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final ageMs = now - stat.modified.millisecondsSinceEpoch;
          if (ageMs > _maxAgeMs) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }
}
