import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/focus_session_repository.dart';
import '../domain/focus_session_state.dart';
import '../domain/focus_session_statistics.dart';
import 'focus_session_statistics_storage.dart';

class FocusSessionRepositoryImpl implements FocusSessionRepository {
  static const String _activeSessionKey = 'active_focus_session';
  static const String _sessionHistoryKey = 'session_history';

  @override
  Future<FocusSessionState?> loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_activeSessionKey);
    
    if (sessionJson == null) {
      return null;
    }
    
    try {
      final decoded = jsonDecode(sessionJson);
      return FocusSessionState.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveActiveSession(FocusSessionState state) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = jsonEncode(state.toJson());
    await prefs.setString(_activeSessionKey, sessionJson);
  }

  @override
  Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey);
  }

  @override
  Future<void> saveCompletedSession({
    required DateTime completedAt,
    required int durationMinutes,
    List<String>? tags,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionRecord = _buildSessionRecord(completedAt, durationMinutes, tags, note);
    
    final history = prefs.getStringList(_sessionHistoryKey) ?? [];
    history.insert(0, sessionRecord);
    await prefs.setStringList(_sessionHistoryKey, history);

    final currentStats = await loadStatistics();
    final updatedStats = currentStats.addSession(durationMinutes);
    await saveStatistics(updatedStats);
  }

  String _buildSessionRecord(DateTime completedAt, int durationMinutes, List<String>? tags, String? note) {
    final dateTime = '${completedAt.year.toString().padLeft(4, '0')}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')} ${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';
    
    final cleanTags = _cleanTagsList(tags);
    final cleanNote = _cleanNote(note);
    
    if (cleanTags.isEmpty && cleanNote.isEmpty) {
      return '$dateTime|$durationMinutes';
    }
    
    final tagsStr = cleanTags.join(',');
    return '$dateTime|$durationMinutes|$tagsStr|$cleanNote';
  }

  List<String> _cleanTagsList(List<String>? tags) {
    if (tags == null) return [];
    return tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  String _cleanNote(String? note) {
    if (note == null) return '';
    return note.trim();
  }

  @override
  Future<FocusSessionStatistics> loadStatistics() async {
    return await FocusSessionStatisticsStorage.loadStatistics();
  }

  @override
  Future<void> saveStatistics(FocusSessionStatistics statistics) async {
    await FocusSessionStatisticsStorage.saveStatistics(statistics);
  }

  @override
  Future<void> clearStatistics() async {
    await FocusSessionStatisticsStorage.clearStatistics();
  }
}