import 'package:shared_preferences/shared_preferences.dart';

/// Session data model with tags and notes support
class Session {
  final DateTime dateTime;
  final int durationMinutes;
  final List<String> tags;
  final String? note;
  final String id;

  const Session({
    required this.dateTime,
    required this.durationMinutes,
    required this.tags,
    this.note,
    required this.id,
  });

  Session copyWith({
    DateTime? dateTime,
    int? durationMinutes,
    List<String>? tags,
    String? note,
    String? id,
    bool? clearNote,
  }) {
    return Session(
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tags: tags ?? this.tags,
      note: clearNote == true ? null : (note ?? this.note),
      id: id ?? this.id,
    );
  }
}

/// Filter parameters for session queries
class SessionFilter {
  final List<String>? tagsAny;
  final DateTime? from;
  final DateTime? to;
  final String? noteQuery;

  const SessionFilter({
    this.tagsAny,
    this.from,
    this.to,
    this.noteQuery,
  });
}

/// Service for managing session tags, notes, and filtering operations
class SessionTagsService {
  static const String _sessionHistoryKey = 'session_history';

  /// Load all sessions from storage with backward compatibility
  static Future<List<Session>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_sessionHistoryKey) ?? [];
    
    return historyJson.asMap().entries.map((entry) {
      final index = entry.key;
      final jsonString = entry.value;
      return _parseSession(jsonString, index);
    }).toList();
  }

  /// Add a tag to a specific session (idempotent)
  static Future<bool> addTag(String sessionId, String tag) async {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty) return false;

    return await _updateSession(sessionId, (session) {
      if (session.tags.contains(cleanTag)) {
        return session; // Tag already exists, no change
      }
      final newTags = [...session.tags, cleanTag];
      return session.copyWith(tags: newTags);
    });
  }

  /// Remove a tag from a specific session (no-op if tag doesn't exist)
  static Future<bool> removeTag(String sessionId, String tag) async {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty) return false;

    return await _updateSession(sessionId, (session) {
      if (!session.tags.contains(cleanTag)) {
        return session; // Tag doesn't exist, no change
      }
      final newTags = session.tags.where((t) => t != cleanTag).toList();
      return session.copyWith(tags: newTags);
    });
  }

  /// Set all tags for a specific session
  static Future<bool> setTags(String sessionId, List<String> tags) async {
    final cleanTags = _cleanTags(tags);
    
    return await _updateSession(sessionId, (session) {
      return session.copyWith(tags: cleanTags);
    });
  }

  /// Set note for a specific session
  static Future<bool> setNote(String sessionId, String note) async {
    final cleanNote = note.trim();
    
    return await _updateSession(sessionId, (session) {
      return session.copyWith(note: cleanNote.isEmpty ? null : cleanNote);
    });
  }

  /// Clear note for a specific session
  static Future<bool> clearNote(String sessionId) async {
    return await _updateSession(sessionId, (session) {
      return session.copyWith(clearNote: true);
    });
  }

  /// Filter sessions based on provided criteria (pure function, O(n))
  static List<Session> filterSessions(
    List<Session> sessions,
    SessionFilter filter,
  ) {
    // Defensive copy to ensure original list is not modified
    final filteredSessions = <Session>[];
    
    for (final session in sessions) {
      if (_matchesFilter(session, filter)) {
        filteredSessions.add(session);
      }
    }
    
    return filteredSessions;
  }

  // Private helper methods

  /// Parse session from storage string with backward compatibility
  static Session _parseSession(String jsonString, int index) {
    final parts = jsonString.split('|');
    final dateTime = DateTime.parse(parts[0]);
    final durationMinutes = int.parse(parts[1]);
    
    // Backward compatibility: handle old format (2 parts) and new format (4 parts)
    final tags = parts.length > 2 && parts[2].isNotEmpty
        ? parts[2].split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList()
        : <String>[];
    final note = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null;
    
    final id = _generateSessionId(dateTime, index);
    
    return Session(
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      tags: tags,
      note: note,
      id: id,
    );
  }

  /// Generate consistent session ID
  static String _generateSessionId(DateTime dateTime, int index) {
    return 'session_${dateTime.millisecondsSinceEpoch}_$index';
  }

  /// Update a specific session by ID
  static Future<bool> _updateSession(String sessionId, Session Function(Session) updater) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_sessionHistoryKey) ?? [];
    
    bool found = false;
    final updatedHistory = <String>[];
    
    for (int i = 0; i < historyJson.length; i++) {
      final session = _parseSession(historyJson[i], i);
      
      if (session.id == sessionId) {
        final updatedSession = updater(session);
        updatedHistory.add(_serializeSession(updatedSession));
        found = true;
      } else {
        updatedHistory.add(historyJson[i]);
      }
    }
    
    if (found) {
      await prefs.setStringList(_sessionHistoryKey, updatedHistory);
    }
    
    return found;
  }

  /// Serialize session back to storage format
  static String _serializeSession(Session session) {
    final dateTimeStr = '${session.dateTime.year.toString().padLeft(4, '0')}-${session.dateTime.month.toString().padLeft(2, '0')}-${session.dateTime.day.toString().padLeft(2, '0')} ${session.dateTime.hour.toString().padLeft(2, '0')}:${session.dateTime.minute.toString().padLeft(2, '0')}';
    
    if (session.tags.isEmpty && (session.note == null || session.note!.isEmpty)) {
      return '$dateTimeStr|${session.durationMinutes}';
    }
    
    final tagsStr = session.tags.join(',');
    final noteStr = session.note ?? '';
    return '$dateTimeStr|${session.durationMinutes}|$tagsStr|$noteStr';
  }

  /// Clean and deduplicate tags
  static List<String> _cleanTags(List<String> tags) {
    return tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Check if session matches filter criteria
  static bool _matchesFilter(Session session, SessionFilter filter) {
    // Tag filter (any match)
    if (filter.tagsAny != null && filter.tagsAny!.isNotEmpty) {
      final hasAnyTag = filter.tagsAny!.any((filterTag) => 
          session.tags.any((sessionTag) => 
              sessionTag.toLowerCase() == filterTag.toLowerCase()));
      if (!hasAnyTag) return false;
    }
    
    // Date range filter (inclusive, local time)
    final sessionDate = _toLocalDate(session.dateTime);
    
    if (filter.from != null) {
      final fromDate = _toLocalDate(filter.from!);
      if (sessionDate.isBefore(fromDate)) return false;
    }
    
    if (filter.to != null) {
      final toDate = _toLocalDate(filter.to!);
      if (sessionDate.isAfter(toDate)) return false;
    }
    
    // Note query filter (case-insensitive substring)
    if (filter.noteQuery != null && filter.noteQuery!.trim().isNotEmpty) {
      final query = filter.noteQuery!.trim().toLowerCase();
      final sessionNote = (session.note ?? '').toLowerCase();
      if (!sessionNote.contains(query)) return false;
    }
    
    return true;
  }

  /// Convert DateTime to local date (ignoring time)
  static DateTime _toLocalDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}