import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/focus_session_statistics.dart';

class FocusSessionStatisticsStorage {
  static const String _statisticsKey = 'focus_session_statistics';

  static Future<FocusSessionStatistics> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statisticsJson = prefs.getString(_statisticsKey);
    
    if (statisticsJson == null) {
      return FocusSessionStatistics.empty();
    }
    
    try {
      final decoded = jsonDecode(statisticsJson);
      return FocusSessionStatistics.fromJson(decoded);
    } catch (e) {
      return FocusSessionStatistics.empty();
    }
  }

  static Future<void> saveStatistics(FocusSessionStatistics statistics) async {
    final prefs = await SharedPreferences.getInstance();
    final statisticsJson = jsonEncode(statistics.toJson());
    await prefs.setString(_statisticsKey, statisticsJson);
  }

  static Future<void> clearStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statisticsKey);
  }
}