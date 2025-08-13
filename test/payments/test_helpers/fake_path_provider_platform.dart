import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  static String? _tempPath;
  
  @override
  Future<String?> getApplicationDocumentsPath() async {
    _tempPath ??= Directory.systemTemp.createTempSync('mindtrainer_test').path;
    return _tempPath;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return getApplicationDocumentsPath();
  }

  @override
  Future<String?> getLibraryPath() async {
    return getApplicationDocumentsPath();
  }

  @override
  Future<String?> getExternalCachePath() async {
    return getTemporaryPath();
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    final path = await getExternalCachePath();
    return path != null ? [path] : null;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return getTemporaryPath();
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    final path = await getExternalStoragePath();
    return path != null ? [path] : null;
  }

  @override
  Future<String?> getDownloadsPath() async {
    return getTemporaryPath();
  }

  static void cleanup() {
    if (_tempPath != null) {
      try {
        Directory(_tempPath!).deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
      _tempPath = null;
    }
  }
}