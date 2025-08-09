import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/checkin_entry.dart';
import '../domain/animal_mood.dart';

class CheckinStorage {
  static const String _keyCheckins = 'animal_checkins';

  Future<void> saveCheckin(CheckinEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final checkins = await getRecentCheckins();
    checkins.insert(0, entry);
    
    // Keep only last 100 entries
    if (checkins.length > 100) {
      checkins.removeRange(100, checkins.length);
    }
    
    final jsonList = checkins.map((e) => e.toJson()).toList();
    await prefs.setString(_keyCheckins, jsonEncode(jsonList));
  }

  Future<List<CheckinEntry>> getRecentCheckins() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyCheckins);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => CheckinEntry.fromJson(json)).toList();
  }

  Future<List<CheckinEntry>> getCheckinsForWeek() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final allCheckins = await getRecentCheckins();
    
    return allCheckins
        .where((entry) => entry.timestamp.isAfter(weekAgo))
        .toList();
  }
}