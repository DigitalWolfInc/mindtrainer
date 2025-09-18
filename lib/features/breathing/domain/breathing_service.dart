/// Breathing Service for MindTrainer Pro Integration
/// 
/// Manages breathing pattern access, Pro feature gating, and analytics tracking
/// for guided breathing exercises.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/analytics/engagement_analytics.dart';
import '../../../core/storage/local_storage.dart';
import 'breathing_pattern.dart';

/// Result of checking breathing pattern access
class BreathingAccessResult {
  final bool canAccess;
  final String message;
  final bool requiresUpgrade;
  final BreathingPatternConfig? pattern;
  
  const BreathingAccessResult({
    required this.canAccess,
    required this.message,
    required this.requiresUpgrade,
    this.pattern,
  });
  
  /// User can access pattern
  const BreathingAccessResult.allowed(BreathingPatternConfig pattern)
    : this(
        canAccess: true,
        message: 'Ready to breathe',
        requiresUpgrade: false,
        pattern: pattern,
      );
  
  /// Pattern requires Pro upgrade
  const BreathingAccessResult.upgradeRequired(BreathingPatternConfig pattern)
    : this(
        canAccess: false,
        message: 'This breathing pattern is available in Pro',
        requiresUpgrade: true,
        pattern: pattern,
      );
  
  /// Pattern not found
  const BreathingAccessResult.notFound()
    : this(
        canAccess: false,
        message: 'Breathing pattern not found',
        requiresUpgrade: false,
        pattern: null,
      );
}

/// Breathing session result for analytics
class BreathingSessionResult {
  final BreathingPatternType patternType;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalCycles;
  final int completedCycles;
  final bool wasCompleted;
  final int durationSeconds;
  final Map<String, dynamic> metadata;
  
  BreathingSessionResult({
    required this.patternType,
    required this.startTime,
    this.endTime,
    required this.totalCycles,
    required this.completedCycles,
    required this.wasCompleted,
    required this.durationSeconds,
    this.metadata = const {},
  });
  
  /// Completion percentage (0.0 to 1.0)
  double get completionRate => completedCycles / totalCycles;
  
  /// Whether session was successful (>75% completion)
  bool get isSuccessful => completionRate >= 0.75;
  
  /// Session effectiveness score (0-100)
  int get effectivenessScore {
    if (wasCompleted) return 100;
    if (completionRate >= 0.9) return 85;
    if (completionRate >= 0.75) return 70;
    if (completionRate >= 0.5) return 50;
    return (completionRate * 40).round();
  }
}

/// Main breathing service with Pro integration
class BreathingService {
  final MindTrainerProGates _proGates;
  final EngagementAnalytics _analytics;
  final LocalStorage _storage;
  
  static const String _breathingHistoryKey = 'breathing_session_history';
  static const String _breathingPreferencesKey = 'breathing_preferences';
  
  final Map<BreathingPatternType, BreathingSessionController> _activeControllers = {};
  
  BreathingService(this._proGates, this._analytics, this._storage);
  
  /// Check if user can access a breathing pattern
  BreathingAccessResult checkPatternAccess(BreathingPatternType type) {
    final pattern = BreathingPatterns.getPattern(type);
    if (pattern == null) {
      return const BreathingAccessResult.notFound();
    }
    
    // Free patterns always accessible
    if (!pattern.isProFeature) {
      return BreathingAccessResult.allowed(pattern);
    }
    
    // Pro patterns require active Pro subscription
    if (_proGates.isProActive) {
      return BreathingAccessResult.allowed(pattern);
    } else {
      return BreathingAccessResult.upgradeRequired(pattern);
    }
  }
  
  /// Get all available patterns for current user
  List<BreathingPatternConfig> getAvailablePatterns() {
    if (_proGates.isProActive) {
      return BreathingPatterns.getAllPatterns();
    } else {
      return BreathingPatterns.getFreePatterns();
    }
  }
  
  /// Get locked patterns that require upgrade
  List<BreathingPatternConfig> getLockedPatterns() {
    if (_proGates.isProActive) {
      return []; // No locked patterns for Pro users
    } else {
      return BreathingPatterns.getProPatterns();
    }
  }
  
  /// Create and start a breathing session
  Future<BreathingSessionController?> startBreathingSession(BreathingPatternType type) async {
    final access = checkPatternAccess(type);
    if (!access.canAccess || access.pattern == null) {
      // Track blocked access for analytics
      if (access.requiresUpgrade) {
        await _analytics.trackProFeatureUsage(
          ProFeatureCategory.breathingPatterns,
          action: 'blocked',
          properties: {
            'pattern_type': type.name,
            'pattern_name': access.pattern?.name ?? 'unknown',
          },
        );
      }
      return null;
    }
    
    final pattern = access.pattern!;
    
    // Dispose existing controller if any
    await _disposeController(type);
    
    // Create new controller
    final controller = BreathingSessionController(pattern);
    _activeControllers[type] = controller;
    
    // Track session start
    await _analytics.trackProFeatureUsage(
      ProFeatureCategory.breathingPatterns,
      action: 'started',
      properties: {
        'pattern_type': type.name,
        'pattern_name': pattern.name,
        'total_cycles': pattern.totalCycles,
        'duration_seconds': pattern.totalDuration,
        'is_pro_pattern': pattern.isProFeature,
      },
    );
    
    if (kDebugMode) {
      print('Started breathing session: ${pattern.name}');
    }
    
    return controller;
  }
  
  /// Get active breathing session controller
  BreathingSessionController? getActiveSession(BreathingPatternType type) {
    return _activeControllers[type];
  }
  
  /// Complete a breathing session and record results
  Future<void> completeBreathingSession(
    BreathingPatternType type,
    BreathingSessionResult result,
  ) async {
    await _disposeController(type);
    
    // Save to history
    await _saveSessionResult(result);
    
    // Track analytics
    await _analytics.trackProFeatureUsage(
      ProFeatureCategory.breathingPatterns,
      action: 'completed',
      properties: {
        'pattern_type': type.name,
        'completed_cycles': result.completedCycles,
        'total_cycles': result.totalCycles,
        'completion_rate': result.completionRate,
        'was_completed': result.wasCompleted,
        'effectiveness_score': result.effectivenessScore,
        'duration_seconds': result.durationSeconds,
      },
    );
    
    if (kDebugMode) {
      print('Completed breathing session: ${type.name} (${result.completionRate * 100}% complete)');
    }
  }
  
  /// Get breathing session history
  Future<List<BreathingSessionResult>> getSessionHistory({
    int? limitDays,
    BreathingPatternType? filterType,
  }) async {
    final historyJson = await _storage.getString(_breathingHistoryKey);
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> historyList = json.decode(historyJson);
      List<BreathingSessionResult> history = historyList
          .map((json) => _sessionResultFromJson(json))
          .toList();
      
      // Apply filters
      if (limitDays != null) {
        final cutoff = DateTime.now().subtract(Duration(days: limitDays));
        history = history.where((result) => result.startTime.isAfter(cutoff)).toList();
      }
      
      if (filterType != null) {
        history = history.where((result) => result.patternType == filterType).toList();
      }
      
      // Sort by most recent first
      history.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      return history;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading breathing session history: $e');
      }
      return [];
    }
  }
  
  /// Get breathing session statistics
  Future<Map<String, dynamic>> getBreathingStats({int? limitDays}) async {
    final history = await getSessionHistory(limitDays: limitDays);
    
    if (history.isEmpty) {
      return {
        'total_sessions': 0,
        'completed_sessions': 0,
        'completion_rate': 0.0,
        'average_effectiveness': 0.0,
        'total_minutes': 0.0,
        'favorite_pattern': null,
        'streak_days': 0,
      };
    }
    
    final completedSessions = history.where((h) => h.wasCompleted).length;
    final totalMinutes = history.fold(0.0, (sum, h) => sum + (h.durationSeconds / 60.0));
    final avgEffectiveness = history.fold(0.0, (sum, h) => sum + h.effectivenessScore) / history.length;
    
    // Find most used pattern
    final patternCounts = <BreathingPatternType, int>{};
    for (final session in history) {
      patternCounts[session.patternType] = (patternCounts[session.patternType] ?? 0) + 1;
    }
    
    final favoritePattern = patternCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Calculate streak
    final streakDays = _calculateBreathingStreak(history);
    
    return {
      'total_sessions': history.length,
      'completed_sessions': completedSessions,
      'completion_rate': completedSessions / history.length,
      'average_effectiveness': avgEffectiveness,
      'total_minutes': totalMinutes,
      'favorite_pattern': favoritePattern.name,
      'streak_days': streakDays,
    };
  }
  
  /// Track when user views a locked pattern (for conversion analytics)
  Future<void> trackLockedPatternView(BreathingPatternType type) async {
    final pattern = BreathingPatterns.getPattern(type);
    if (pattern != null && pattern.isProFeature && !_proGates.isProActive) {
      await _analytics.trackProFeatureUsage(
        ProFeatureCategory.breathingPatterns,
        action: 'locked_viewed',
        properties: {
          'pattern_type': type.name,
          'pattern_name': pattern.name,
        },
      );
    }
  }
  
  /// Dispose all active controllers
  Future<void> disposeAll() async {
    for (final type in _activeControllers.keys.toList()) {
      await _disposeController(type);
    }
  }
  
  // Private helper methods
  
  Future<void> _disposeController(BreathingPatternType type) async {
    final controller = _activeControllers.remove(type);
    controller?.dispose();
  }
  
  Future<void> _saveSessionResult(BreathingSessionResult result) async {
    final history = await getSessionHistory();
    history.insert(0, result); // Add to front
    
    // Keep only last 100 sessions to manage storage
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    final historyJson = json.encode(
      history.map((result) => _sessionResultToJson(result)).toList()
    );
    await _storage.setString(_breathingHistoryKey, historyJson);
  }
  
  Map<String, dynamic> _sessionResultToJson(BreathingSessionResult result) {
    return {
      'patternType': result.patternType.name,
      'startTime': result.startTime.toIso8601String(),
      'endTime': result.endTime?.toIso8601String(),
      'totalCycles': result.totalCycles,
      'completedCycles': result.completedCycles,
      'wasCompleted': result.wasCompleted,
      'durationSeconds': result.durationSeconds,
      'metadata': result.metadata,
    };
  }
  
  BreathingSessionResult _sessionResultFromJson(Map<String, dynamic> json) {
    return BreathingSessionResult(
      patternType: BreathingPatternType.values.firstWhere(
        (t) => t.name == json['patternType'],
        orElse: () => BreathingPatternType.fourSevenEight,
      ),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      totalCycles: json['totalCycles'] ?? 0,
      completedCycles: json['completedCycles'] ?? 0,
      wasCompleted: json['wasCompleted'] ?? false,
      durationSeconds: json['durationSeconds'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  int _calculateBreathingStreak(List<BreathingSessionResult> history) {
    if (history.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Group sessions by date
    final sessionsByDate = <DateTime, List<BreathingSessionResult>>{};
    for (final session in history) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      sessionsByDate[date] = (sessionsByDate[date] ?? [])..add(session);
    }
    
    // Count consecutive days with successful sessions
    int streak = 0;
    DateTime currentDate = todayDate;
    
    while (true) {
      final daysSessions = sessionsByDate[currentDate];
      if (daysSessions == null || daysSessions.isEmpty) {
        break;
      }
      
      // Check if there was at least one successful session this day
      final hasSuccessfulSession = daysSessions.any((s) => s.isSuccessful);
      if (!hasSuccessfulSession) {
        break;
      }
      
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }
}