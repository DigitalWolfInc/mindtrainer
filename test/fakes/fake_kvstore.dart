/// Fake KVStore implementation for testing
/// 
/// In-memory storage that implements the KVStore interface for testing
/// email opt-in and other consent management features.

import 'package:mindtrainer/core/consent/email_optin.dart';

/// In-memory implementation of KVStore for testing
class FakeKVStore implements KVStore {
  final Map<String, dynamic> _storage = {};
  
  @override
  Future<void> setBool(String key, bool value) async {
    _storage[key] = value;
  }
  
  @override
  bool? getBool(String key) {
    final value = _storage[key];
    return value is bool ? value : null;
  }
  
  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }
  
  @override
  String? getString(String key) {
    final value = _storage[key];
    return value is String ? value : null;
  }
  
  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
  
  /// Test helper: Clear all stored data
  void clear() {
    _storage.clear();
  }
  
  /// Test helper: Get read-only view of internal storage
  Map<String, dynamic> get storage => Map.unmodifiable(_storage);
  
  /// Test helper: Check if key exists
  bool containsKey(String key) => _storage.containsKey(key);
  
  /// Test helper: Get all stored keys
  Set<String> get keys => _storage.keys.toSet();
}