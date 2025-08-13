/// File-backed email opt-in preference store
/// 
/// Provides atomic file operations using temp-file-rename pattern
/// for safe persistence of email opt-in preferences.

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EmailOptInStore {
  static EmailOptInStore? _instance;
  static EmailOptInStore get instance => _instance ??= EmailOptInStore._();
  
  EmailOptInStore._();
  
  bool _optedIn = false;
  bool _initialized = false;
  
  /// Get the storage file path
  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File(path.join(dir.path, 'email_optin.json'));
  }
  
  /// Initialize store by loading from disk (defaults to false if missing/malformed)
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      final file = await _file;
      
      if (!await file.exists()) {
        _optedIn = false;
        _initialized = true;
        return;
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      _optedIn = data['optedIn'] as bool? ?? false;
    } catch (e) {
      // Malformed file or read error - safe recover to false
      _optedIn = false;
    }
    
    _initialized = true;
  }
  
  /// Current opt-in status
  bool get optedIn {
    if (!_initialized) {
      throw StateError('EmailOptInStore not initialized. Call init() first.');
    }
    return _optedIn;
  }
  
  /// Set opt-in preference with atomic write
  Future<void> setOptIn(bool value) async {
    if (!_initialized) {
      await init();
    }
    
    _optedIn = value;
    
    final file = await _file;
    final data = {
      'optedIn': value,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    // Atomic write using temp-file-rename pattern
    final tempFile = File('${file.path}.tmp');
    final content = jsonEncode(data);
    
    await tempFile.writeAsString(content);
    await tempFile.rename(file.path);
  }
  
  /// Reset instance for testing
  static void resetInstance() {
    _instance = null;
  }
}