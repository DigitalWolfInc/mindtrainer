import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Fake path provider for testing
class FakePathProviderPlatform extends PathProviderPlatform {
  static Directory? _tempDir;

  static void setUp() {
    _tempDir = Directory.systemTemp.createTempSync('test_path_provider');
  }

  static void tearDown() {
    if (_tempDir?.existsSync() == true) {
      _tempDir!.deleteSync(recursive: true);
    }
  }

  Directory get _getTempDir {
    if (_tempDir == null || !_tempDir!.existsSync()) {
      setUp();
    }
    return _tempDir!;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return _getTempDir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory('${_getTempDir.path}/support');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = Directory('${_getTempDir.path}/documents');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return null; // Not available on all platforms
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return null;
  }

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    return null;
  }

  @override
  Future<String?> getLibraryPath() async {
    final dir = Directory('${_getTempDir.path}/library');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    final dir = Directory('${_getTempDir.path}/cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    final dir = Directory('${_getTempDir.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}