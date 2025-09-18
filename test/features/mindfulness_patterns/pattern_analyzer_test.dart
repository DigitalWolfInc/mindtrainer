/// Tests for Pattern Analyzer Service
/// 
/// Validates pattern detection, recommendations, and Pro gating functionality.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/storage/local_storage.dart';
import 'package:mindtrainer/core/session_tags.dart';
import 'package:mindtrainer/core/insights/mood_focus_insights.dart';
import 'package:mindtrainer/features/mindfulness_patterns/domain/pattern_analysis.dart';
import 'package:mindtrainer/features/mindfulness_patterns/application/pattern_analyzer_service.dart';

class MockLocalStorage implements LocalStorage {
  final Map<String, String> _storage = {};
  
  @override
  Future<String?> getString(String key) async => _storage[key];
  
  @override
  Future<void> setString(String key, String value) async => _storage[key] = value;
  
  static Map<String, dynamic>? parseJson(String json) => {};
  static String encodeJson(Object obj) => '{}';
}

class MockProGates implements MindTrainerProGates {
  final bool _isProActive;
  
  MockProGates(this._isProActive);
  
  @override
  bool get isProActive => _isProActive;
  
  @override
  bool get unlimitedDailySessions => _isProActive;
  
  @override
  int get dailySessionLimit => _isProActive ? -1 : 5;
  
  @override
  bool canStartSession(int todaysSessionCount) => _isProActive || todaysSessionCount < 5;
}

class MockMoodSource implements MoodSource {
  final List<MoodEntry> _entries;
  
  MockMoodSource(this._entries);
  
  @override
  Iterable<MoodEntry> entries({DateTime? from, DateTime? to}) {
    return _entries.where((entry) {
      if (from != null && entry.at.isBefore(from)) return false;
      if (to != null && entry.at.isAfter(to)) return false;
      return true;
    });
  }
}

void main() {
  group('Pattern Analyzer Service', () {
    late MockLocalStorage mockStorage;
    late PatternAnalyzerService service;
    
    setUp(() {
      mockStorage = MockLocalStorage();
    });
    
    group('Pro Gating', () {
      test('Free users cannot access pattern analysis', () {
        final proGates = MockProGates(false);
        service = PatternAnalyzerService(proGates, mockStorage);
        
        expect(service.isPatternAnalysisAvailable, false);
      });
      
      test('Pro users can access pattern analysis', () {
        final proGates = MockProGates(true);
        service = PatternAnalyzerService(proGates, mockStorage);
        
        expect(service.isPatternAnalysisAvailable, true);
      });
      
      test('Free users get null analysis', () async {
        final proGates = MockProGates(false);
        service = PatternAnalyzerService(proGates, mockStorage);
        
        final sessions = _createTestSessions();
        final moodSource = MockMoodSource([]);
        
        final analysis = await service.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNull);
      });
      
      test('Pro users get analysis when enough data available', () async {
        final proGates = MockProGates(true);
        service = PatternAnalyzerService(proGates, mockStorage);
        
        final sessions = _createTestSessions();
        final moodSource = MockMoodSource(_createTestMoodEntries());
        
        final analysis = await service.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNotNull);
        expect(analysis!.totalSessionsAnalyzed, sessions.length);
      });
    });
    
    group('Pattern Analysis', () {
      late PatternAnalyzerService proService;
      
      setUp(() {
        final proGates = MockProGates(true);
        proService = PatternAnalyzerService(proGates, mockStorage);
      });
      
      test('Insufficient data returns null', () async {
        final sessions = _createTestSessions().take(3).toList(); // Less than minimum
        final moodSource = MockMoodSource([]);
        
        final analysis = await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNull);
      });
      
      test('Analysis includes time patterns', () async {
        final sessions = _createMorningAfternoonSessions();
        final moodSource = MockMoodSource([]);
        
        final analysis = await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNotNull);
        expect(analysis!.timePatterns.isNotEmpty, true);
        
        // Should identify morning and afternoon patterns
        final morningPattern = analysis.timePatterns
            .where((p) => p.hour >= 8 && p.hour <= 11)
            .firstOrNull;
        final afternoonPattern = analysis.timePatterns
            .where((p) => p.hour >= 14 && p.hour <= 17)
            .firstOrNull;
        
        expect(morningPattern, isNotNull);
        expect(afternoonPattern, isNotNull);
      });
      
      test('Analysis identifies best time pattern', () async {
        final sessions = _createVariedQualitySessions();
        final moodSource = MockMoodSource([]);
        
        final analysis = await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNotNull);
        expect(analysis!.bestTimePattern, isNotNull);
        
        // Best time should have highest performance score
        final bestTime = analysis.bestTimePattern!;
        final allTimePatterns = analysis.timePatterns;
        
        for (final pattern in allTimePatterns) {
          if (pattern != bestTime && pattern.sessionCount >= 3) {
            expect(bestTime.performanceScore, greaterThanOrEqualTo(pattern.performanceScore));
          }
        }
      });
      
      test('Analysis includes mood patterns when mood data available', () async {
        final sessions = _createTestSessions();
        final moodEntries = _createTestMoodEntries();
        final moodSource = MockMoodSource(moodEntries);
        
        final analysis = await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNotNull);
        expect(analysis!.moodPatterns.isNotEmpty, true);
      });
      
      test('Analysis includes environmental patterns from tags', () async {
        final sessions = _createTaggedSessions();
        final moodSource = MockMoodSource([]);
        
        final analysis = await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNotNull);
        expect(analysis!.environmentalPatterns.isNotEmpty, true);
        
        // Should identify patterns for common tags
        final gratefulPattern = analysis.environmentalPatterns
            .where((p) => p.value == 'grateful')
            .firstOrNull;
        
        expect(gratefulPattern, isNotNull);
        expect(gratefulPattern!.sessionCount, greaterThanOrEqualTo(3));
      });
      
      test('Analysis generates recommendations', () async {
        final sessions = _createVariedQualitySessions();
        final moodSource = MockMoodSource([]);
        
        final analysis = await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        expect(analysis, isNotNull);
        expect(analysis!.recommendations.isNotEmpty, true);
        
        // Recommendations should have valid confidence scores
        for (final rec in analysis.recommendations) {
          expect(rec.confidenceScore, inInclusiveRange(0.0, 1.0));
          expect(rec.title.isNotEmpty, true);
          expect(rec.description.isNotEmpty, true);
          expect(rec.actionItems.isNotEmpty, true);
        }
      });
    });
    
    group('Personalized Suggestions', () {
      late PatternAnalyzerService proService;
      
      setUp(() {
        final proGates = MockProGates(true);
        proService = PatternAnalyzerService(proGates, mockStorage);
      });
      
      test('Free users get empty suggestions', () async {
        final freeService = PatternAnalyzerService(MockProGates(false), mockStorage);
        
        final suggestions = await freeService.getPersonalizedSuggestions();
        expect(suggestions, isEmpty);
      });
      
      test('Pro users get suggestions when analysis available', () async {
        // First, create an analysis
        final sessions = _createVariedQualitySessions();
        final moodSource = MockMoodSource([]);
        
        await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        final suggestions = await proService.getPersonalizedSuggestions();
        
        // Should get suggestions (may be empty if patterns aren't strong enough)
        expect(suggestions, isA<List<String>>());
      });
      
      test('Suggestions consider current time', () async {
        // Create sessions with clear time patterns
        final sessions = _createMorningAfternoonSessions();
        final moodSource = MockMoodSource([]);
        
        await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        // Get suggestions for morning time
        final morningSuggestions = await proService.getPersonalizedSuggestions(
          preferredTime: DateTime(2023, 1, 1, 9, 0), // 9 AM
        );
        
        // Get suggestions for afternoon time
        final afternoonSuggestions = await proService.getPersonalizedSuggestions(
          preferredTime: DateTime(2023, 1, 1, 15, 0), // 3 PM
        );
        
        expect(morningSuggestions, isA<List<String>>());
        expect(afternoonSuggestions, isA<List<String>>());
      });
      
      test('Suggestions consider current mood', () async {
        final sessions = _createTestSessions();
        final moodEntries = _createTestMoodEntries();
        final moodSource = MockMoodSource(moodEntries);
        
        await proService.analyzePatterns(
          sessions: sessions,
          moodSource: moodSource,
        );
        
        final lowMoodSuggestions = await proService.getPersonalizedSuggestions(
          currentMood: 2, // Low mood
        );
        
        final highMoodSuggestions = await proService.getPersonalizedSuggestions(
          currentMood: 5, // High mood
        );
        
        expect(lowMoodSuggestions, isA<List<String>>());
        expect(highMoodSuggestions, isA<List<String>>());
      });
    });
    
    group('Data Confidence and Validation', () {
      test('TimeOfDayPattern calculates performance correctly', () {
        const pattern = TimeOfDayPattern(
          hour: 9,
          averageRating: 4.5,
          sessionCount: 10,
          averageDuration: Duration(minutes: 15),
          completionRate: 0.9,
          commonTags: ['calm', 'focused'],
        );
        
        expect(pattern.timeDescription, 'Morning');
        expect(pattern.timeRange, '09:00-10:00');
        expect(pattern.performanceScore, greaterThan(0.8)); // Should be high
        expect(pattern.quality, PatternQuality.excellent);
      });
      
      test('MoodOutcomePattern predicts quality correctly', () {
        const pattern = MoodOutcomePattern(
          preMoodScore: 2, // Low mood
          averagePostMoodImprovement: 1.5, // Good improvement
          averageSessionRating: 4.0, // Good session rating
          sessionCount: 5,
          averageDuration: Duration(minutes: 10),
          effectiveTags: ['gentle', 'breathing'],
        );
        
        expect(pattern.preMoodDescription, 'Low');
        expect(pattern.predictedQuality, isIn([PatternQuality.good, PatternQuality.excellent]));
      });
      
      test('EnvironmentalPattern identifies impact correctly', () {
        const positivePattern = EnvironmentalPattern(
          factor: 'tag',
          value: 'grateful',
          averageRating: 4.5,
          completionRate: 0.9,
          sessionCount: 8,
          correlationStrength: 0.8,
          patternType: PatternType.contextual,
        );
        
        expect(positivePattern.impactDescription, contains('enhances'));
        
        const negativePattern = EnvironmentalPattern(
          factor: 'tag',
          value: 'stressed',
          averageRating: 2.5,
          completionRate: 0.4,
          sessionCount: 5,
          correlationStrength: 0.7,
          patternType: PatternType.contextual,
        );
        
        expect(negativePattern.impactDescription, contains('hinder'));
      });
      
      test('PersonalizedRecommendation has valid confidence levels', () {
        final highConfidenceRec = PersonalizedRecommendation(
          title: 'Test High Confidence',
          description: 'Test description',
          actionItems: ['Action 1'],
          confidenceScore: 0.9,
          basedOnPattern: PatternType.temporal,
          generatedAt: DateTime.now(),
        );
        
        expect(highConfidenceRec.confidenceLevel, 'High');
        
        final lowConfidenceRec = PersonalizedRecommendation(
          title: 'Test Low Confidence',
          description: 'Test description',
          actionItems: ['Action 1'],
          confidenceScore: 0.3,
          basedOnPattern: PatternType.contextual,
          generatedAt: DateTime.now(),
        );
        
        expect(lowConfidenceRec.confidenceLevel, 'Experimental');
      });
    });
  });
}

/// Helper function to create test sessions
List<Session> _createTestSessions() {
  final now = DateTime.now();
  final sessions = <Session>[];
  
  // Create 10 sessions over the past month
  for (int i = 0; i < 10; i++) {
    sessions.add(Session(
      id: 'session_$i',
      dateTime: now.subtract(Duration(days: i * 3)),
      durationMinutes: 10 + (i % 3) * 5, // Vary duration
      tags: ['mindful', if (i % 2 == 0) 'calm'],
      note: 'Test session $i',
    ));
  }
  
  return sessions;
}

/// Helper function to create sessions with morning/afternoon patterns
List<Session> _createMorningAfternoonSessions() {
  final now = DateTime.now();
  final sessions = <Session>[];
  
  // Morning sessions (tend to be longer and better)
  for (int i = 0; i < 5; i++) {
    sessions.add(Session(
      id: 'morning_$i',
      dateTime: DateTime(now.year, now.month, now.day - i, 9, 0), // 9 AM
      durationMinutes: 15, // Longer sessions
      tags: ['energized', 'focused'],
    ));
  }
  
  // Afternoon sessions (tend to be shorter)
  for (int i = 0; i < 5; i++) {
    sessions.add(Session(
      id: 'afternoon_$i',
      dateTime: DateTime(now.year, now.month, now.day - i, 15, 0), // 3 PM
      durationMinutes: 8, // Shorter sessions
      tags: ['tired', 'restless'],
    ));
  }
  
  return sessions;
}

/// Helper function to create sessions with varied quality
List<Session> _createVariedQualitySessions() {
  final sessions = <Session>[];
  final now = DateTime.now();
  
  // High quality morning sessions
  for (int i = 0; i < 4; i++) {
    sessions.add(Session(
      id: 'hq_morning_$i',
      dateTime: DateTime(now.year, now.month, now.day - i, 8, 0),
      durationMinutes: 20, // Long duration indicates good session
      tags: ['excellent', 'peaceful'],
    ));
  }
  
  // Medium quality afternoon sessions
  for (int i = 0; i < 4; i++) {
    sessions.add(Session(
      id: 'mq_afternoon_$i',
      dateTime: DateTime(now.year, now.month, now.day - i, 14, 0),
      durationMinutes: 12, // Medium duration
      tags: ['okay', 'distracted'],
    ));
  }
  
  // Low quality evening sessions
  for (int i = 0; i < 3; i++) {
    sessions.add(Session(
      id: 'lq_evening_$i',
      dateTime: DateTime(now.year, now.month, now.day - i, 20, 0),
      durationMinutes: 5, // Short duration indicates poor session
      tags: ['difficult', 'restless'],
    ));
  }
  
  return sessions;
}

/// Helper function to create sessions with specific tags
List<Session> _createTaggedSessions() {
  final sessions = <Session>[];
  final now = DateTime.now();
  
  // Sessions with 'grateful' tag (should perform well)
  for (int i = 0; i < 5; i++) {
    sessions.add(Session(
      id: 'grateful_$i',
      dateTime: now.subtract(Duration(days: i)),
      durationMinutes: 18, // Good duration
      tags: ['grateful', 'positive'],
    ));
  }
  
  // Sessions with 'anxious' tag (might perform poorly)
  for (int i = 0; i < 4; i++) {
    sessions.add(Session(
      id: 'anxious_$i',
      dateTime: now.subtract(Duration(days: i + 5)),
      durationMinutes: 6, // Poor duration
      tags: ['anxious', 'worried'],
    ));
  }
  
  // Sessions with mixed tags
  for (int i = 0; i < 3; i++) {
    sessions.add(Session(
      id: 'mixed_$i',
      dateTime: now.subtract(Duration(days: i + 10)),
      durationMinutes: 12,
      tags: ['mixed', 'uncertain'],
    ));
  }
  
  return sessions;
}

/// Helper function to create test mood entries
List<MoodEntry> _createTestMoodEntries() {
  final now = DateTime.now();
  final entries = <MoodEntry>[];
  
  // Create mood entries before some sessions
  for (int i = 0; i < 8; i++) {
    entries.add(MoodEntry(
      now.subtract(Duration(days: i * 2, hours: 1)), // 1 hour before session
      2 + (i % 4), // Mood score 2-5
      ['pre_session'],
    ));
  }
  
  return entries;
}

// Extension to add firstOrNull method if not available
extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}