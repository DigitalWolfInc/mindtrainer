/// Local Storage Interface for MindTrainer
/// 
/// Provides abstraction for local data persistence.

import 'dart:convert';

/// Abstract interface for local storage operations
abstract class LocalStorage {
  /// Get string value for key
  Future<String?> getString(String key);
  
  /// Set string value for key
  Future<void> setString(String key, String value);
  
  /// Parse JSON string to Map
  static Map<String, dynamic>? parseJson(String? json) {
    if (json == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }
  
  /// Encode object to JSON string
  static String encodeJson(Object obj) {
    try {
      return jsonEncode(obj);
    } catch (e) {
      return '{}';
    }
  }
}