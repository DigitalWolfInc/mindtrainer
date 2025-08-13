/// SharedPreferences Implementation of LocalStorage
/// 
/// Concrete implementation using Flutter's SharedPreferences package.

import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage.dart';

/// SharedPreferences-based implementation of LocalStorage
class SharedPreferencesStorage implements LocalStorage {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  
  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}