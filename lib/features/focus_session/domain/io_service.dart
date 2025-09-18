import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../achievements/achievements_store.dart';
import '../../../achievements/snapshot.dart';
import '../../../achievements/badge.dart';

class IOResult {
  final bool success;
  final String? errorMessage;
  final String? data;

  const IOResult.success({this.data}) : success = true, errorMessage = null;
  const IOResult.error(this.errorMessage) : success = false, data = null;
}

class FocusSessionIOService {
  static const String _sessionHistoryKey = 'session_history';

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> _loadAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_sessionHistoryKey) ?? [];
    
    return historyJson.asMap().entries.map((entry) {
      final index = entry.key;
      final jsonString = entry.value;
      final parts = jsonString.split('|');
      final dateTime = DateTime.parse(parts[0]);
      
      // Handle backward compatibility: old format has 2 parts, new format has 4
      final durationMinutes = int.parse(parts[1]);
      final tags = parts.length > 2 ? parts[2] : '';
      final notes = parts.length > 3 ? parts[3] : '';
      
      return {
        'id': _generateSessionId(dateTime, index),
        'start': parts[0],
        'end': _calculateEndTime(dateTime, durationMinutes),
        'durationMinutes': durationMinutes,
        'notes': notes,
        'tags': tags,
      };
    }).toList();
  }

  static String _generateSessionId(DateTime dateTime, int index) {
    return 'session_${dateTime.millisecondsSinceEpoch}_$index';
  }

  static String _calculateEndTime(DateTime start, int durationMinutes) {
    final end = start.add(Duration(minutes: durationMinutes));
    return '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')} ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  static Future<IOResult> exportCsv(String path) async {
    try {
      final sessions = await _loadAllSessions();
      final csvContent = _generateCsvContent(sessions);
      
      final file = File(path);
      await file.writeAsString(csvContent);
      
      return IOResult.success(data: path);
    } catch (e) {
      return IOResult.error('Failed to export CSV: $e');
    }
  }

  @visibleForTesting
  static String _generateCsvContent(List<Map<String, dynamic>> sessions) {
    final buffer = StringBuffer();
    
    buffer.writeln('id,start,end,durationMinutes,notes,tags');
    
    for (final session in sessions) {
      final id = _escapeCsvField(session['id'].toString());
      final start = _escapeCsvField(session['start'].toString());
      final end = _escapeCsvField(session['end'].toString());
      final duration = session['durationMinutes'];
      final notes = _escapeCsvField(session['notes'].toString());
      final tags = _escapeCsvField(session['tags'].toString());
      
      buffer.writeln('$id,$start,$end,$duration,$notes,$tags');
    }
    
    return buffer.toString();
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static Future<IOResult> exportJson(String path) async {
    try {
      final sessions = await _loadAllSessions();
      
      // Export achievements alongside sessions
      final achievementsStore = AchievementsStore.instance;
      await achievementsStore.init();
      final achievements = achievementsStore.snapshot.toJson();
      
      final jsonContent = jsonEncode({
        'exportTimestamp': DateTime.now().toIso8601String(),
        'sessions': sessions,
        'achievements': achievements,
      });
      
      final file = File(path);
      await file.writeAsString(jsonContent);
      
      return IOResult.success(data: path);
    } catch (e) {
      return IOResult.error('Failed to export JSON: $e');
    }
  }

  static Future<IOResult> importJson(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return const IOResult.error('Import file does not exist');
      }
      
      final jsonContent = await file.readAsString();
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      if (!data.containsKey('sessions')) {
        return const IOResult.error('Invalid JSON format: missing sessions array');
      }
      
      final importSessions = (data['sessions'] as List)
          .cast<Map<String, dynamic>>();
      
      final existingSessions = await _loadAllSessions();
      final existingKeys = existingSessions
          .map((s) => '${s['start']}_${s['durationMinutes']}')
          .toSet();
      
      final newSessions = importSessions
          .where((session) => !existingKeys.contains('${session['start']}_${session['durationMinutes']}'))
          .toList();
      
      // Import achievements if present
      int importedBadges = 0;
      if (data.containsKey('achievements')) {
        try {
          final achievementsStore = AchievementsStore.instance;
          await achievementsStore.init();
          
          final importAchievements = AchievementsSnapshot.fromJson(
            data['achievements'] as Map<String, dynamic>
          );
          
          final currentSnapshot = achievementsStore.snapshot;
          final mergedBadges = <String, Badge>{};
          
          // Add existing badges
          mergedBadges.addAll(currentSnapshot.unlocked);
          
          // Merge imported badges (newest unlockedAt wins on conflicts)
          for (final badge in importAchievements.badges) {
            final existing = mergedBadges[badge.id];
            if (existing == null || badge.unlockedAt.isAfter(existing.unlockedAt)) {
              mergedBadges[badge.id] = badge;
            }
          }
          
          // Count newly imported badges
          importedBadges = mergedBadges.length - currentSnapshot.count;
          
          final mergedSnapshot = AchievementsSnapshot.create(
            unlocked: mergedBadges,
            updatedAt: DateTime.now(),
          );
          
          await achievementsStore.replaceAll(mergedSnapshot);
        } catch (e) {
          // Log error but don't fail the entire import
          debugPrint('Failed to import achievements: $e');
        }
      }
      
      if (newSessions.isEmpty && importedBadges == 0) {
        return const IOResult.success(data: 'No new data to import');
      }
      
      if (newSessions.isNotEmpty) {
        await _saveImportedSessions(newSessions);
      }
      
      final messages = <String>[];
      if (newSessions.isNotEmpty) {
        messages.add('${newSessions.length} sessions');
      }
      if (importedBadges > 0) {
        messages.add('$importedBadges badges');
      }
      
      return IOResult.success(data: 'Imported ${messages.join(' and ')}');
    } catch (e) {
      return IOResult.error('Failed to import JSON: $e');
    }
  }

  static Future<void> _saveImportedSessions(List<Map<String, dynamic>> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final existingHistory = prefs.getStringList(_sessionHistoryKey) ?? [];
    
    final newHistoryEntries = sessions.map((session) {
      final start = session['start'].toString();
      final duration = session['durationMinutes'];
      final tags = session['tags']?.toString() ?? '';
      final notes = session['notes']?.toString() ?? '';
      
      if (tags.isEmpty && notes.isEmpty) {
        return '$start|$duration';
      }
      
      return '$start|$duration|$tags|$notes';
    }).toList();
    
    final updatedHistory = [...newHistoryEntries, ...existingHistory];
    await prefs.setStringList(_sessionHistoryKey, updatedHistory);
  }
}