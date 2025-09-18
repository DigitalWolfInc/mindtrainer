import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/limits/session_limits.dart';
import 'package:mindtrainer/core/coach/coach_feature_gates.dart';
import 'package:mindtrainer/core/coach/conversational_coach.dart' as coach;
import 'package:mindtrainer/core/insights/insights_feature_gates.dart';

void main() {
  group('MindTrainerProGates', () {
    test('should correctly identify free user limitations', () {
      final gates = MindTrainerProGates.fromStatusCheck(() => false);
      
      expect(gates.isProActive, false);
      expect(gates.unlimitedDailySessions, false);
      expect(gates.dailySessionLimit, 5);
      expect(gates.extendedCoachingPhases, false);
      expect(gates.advancedAnalytics, false);
      expect(gates.dataExport, false);
      expect(gates.customGoals, false);
      expect(gates.adFree, false);
      expect(gates.premiumThemes, false);
    });
    
    test('should correctly identify Pro user privileges', () {
      final gates = MindTrainerProGates.fromStatusCheck(() => true);
      
      expect(gates.isProActive, true);
      expect(gates.unlimitedDailySessions, true);
      expect(gates.dailySessionLimit, -1);
      expect(gates.extendedCoachingPhases, true);
      expect(gates.advancedAnalytics, true);
      expect(gates.dataExport, true);
      expect(gates.customGoals, true);
      expect(gates.adFree, true);
      expect(gates.premiumThemes, true);
    });
    
    test('should handle session limit checking for free users', () {
      final gates = MindTrainerProGates.fromStatusCheck(() => false);
      
      expect(gates.canStartSession(0), true);
      expect(gates.canStartSession(4), true);
      expect(gates.canStartSession(5), false);
      expect(gates.canStartSession(10), false);
    });
    
    test('should allow unlimited sessions for Pro users', () {
      final gates = MindTrainerProGates.fromStatusCheck(() => true);
      
      expect(gates.canStartSession(0), true);
      expect(gates.canStartSession(10), true);
      expect(gates.canStartSession(100), true);
    });
    
    test('should provide correct coaching phase access', () {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      
      // Free users - basic phases only
      expect(freeGates.isCoachPhaseAvailable(coach.CoachPhase.stabilize), true);
      expect(freeGates.isCoachPhaseAvailable(coach.CoachPhase.open), true);
      expect(freeGates.isCoachPhaseAvailable(coach.CoachPhase.reflect), false);
      expect(freeGates.isCoachPhaseAvailable(coach.CoachPhase.reframe), false);
      expect(freeGates.isCoachPhaseAvailable(coach.CoachPhase.plan), false);
      expect(freeGates.isCoachPhaseAvailable(coach.CoachPhase.close), false);
      
      // Pro users - all phases available
      for (final phase in coach.CoachPhase.values) {
        expect(proGates.isCoachPhaseAvailable(phase), true);
      }
    });
    
    test('should provide correct feature lists', () {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      
      expect(freeGates.availableFeatures, isEmpty);
      expect(freeGates.lockedFeatures.length, 7);
      
      expect(proGates.availableFeatures.length, 7);
      expect(proGates.lockedFeatures, isEmpty);
    });
  });
  
  group('SessionLimitEnforcer', () {
    late SessionLimitEnforcer freeEnforcer;
    late SessionLimitEnforcer proEnforcer;
    
    setUp(() {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      freeEnforcer = SessionLimitEnforcer(freeGates);
      proEnforcer = SessionLimitEnforcer(proGates);
    });
    
    test('should allow sessions within free limit', () {
      final result = freeEnforcer.checkSessionLimit(3);
      
      expect(result.canStart, true);
      expect(result.currentCount, 3);
      expect(result.limit, 5);
      expect(result.remaining, 2);
      expect(result.isUnlimited, false);
    });
    
    test('should block sessions at free limit', () {
      final result = freeEnforcer.checkSessionLimit(5);
      
      expect(result.canStart, false);
      expect(result.currentCount, 5);
      expect(result.limit, 5);
      expect(result.remaining, 0);
      expect(result.reason, 'Daily limit reached');
    });
    
    test('should allow unlimited sessions for Pro users', () {
      final result = proEnforcer.checkSessionLimit(15);
      
      expect(result.canStart, true);
      expect(result.currentCount, 15);
      expect(result.limit, null);
      expect(result.remaining, null);
      expect(result.isUnlimited, true);
    });
    
    test('should provide appropriate display messages', () {
      final freeAllowed = freeEnforcer.checkSessionLimit(2);
      final freeBlocked = freeEnforcer.checkSessionLimit(5);
      final proUnlimited = proEnforcer.checkSessionLimit(10);
      
      expect(freeAllowed.displayMessage, 'Sessions today: 2/5');
      expect(freeBlocked.displayMessage, 'Daily limit reached');
      expect(proUnlimited.displayMessage, 'Sessions today: 10');
    });
    
    test('should count today sessions correctly', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      final sessions = [
        {'start': today.toIso8601String(), 'durationMinutes': 25},
        {'start': today.toIso8601String(), 'durationMinutes': 30},
        {'start': yesterday.toIso8601String(), 'durationMinutes': 20},
      ];
      
      final count = freeEnforcer.countTodaysSessions(sessions);
      expect(count, 2);
    });
    
    test('should provide appropriate warning messages', () {
      expect(freeEnforcer.getLimitWarning(4), contains('last free session'));
      expect(freeEnforcer.getLimitWarning(3), contains('2 free sessions left'));
      expect(freeEnforcer.getLimitWarning(1), isNull);
      expect(proEnforcer.getLimitWarning(10), isNull);
    });
  });
  
  group('CoachingFeatureGates', () {
    late CoachingFeatureGates freeCoaching;
    late CoachingFeatureGates proCoaching;
    
    setUp(() {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      freeCoaching = CoachingFeatureGates(freeGates);
      proCoaching = CoachingFeatureGates(proGates);
    });
    
    test('should allow basic coaching phases for free users', () {
      final stabilizeResult = freeCoaching.checkPhaseAccess(coach.CoachPhase.stabilize);
      final openResult = freeCoaching.checkPhaseAccess(coach.CoachPhase.open);
      
      expect(stabilizeResult.allowed, true);
      expect(openResult.allowed, true);
    });
    
    test('should block advanced coaching phases for free users', () {
      final reflectResult = freeCoaching.checkPhaseAccess(coach.CoachPhase.reflect);
      final reframeResult = freeCoaching.checkPhaseAccess(coach.CoachPhase.reframe);
      final planResult = freeCoaching.checkPhaseAccess(coach.CoachPhase.plan);
      final closeResult = freeCoaching.checkPhaseAccess(coach.CoachPhase.close);
      
      expect(reflectResult.allowed, false);
      expect(reframeResult.allowed, false);
      expect(planResult.allowed, false);
      expect(closeResult.allowed, false);
      
      expect(reflectResult.upgradeMessage, contains('deeper reflection'));
      expect(reframeResult.upgradeMessage, contains('cognitive reframing'));
    });
    
    test('should allow all coaching phases for Pro users', () {
      for (final phase in coach.CoachPhase.values) {
        final result = proCoaching.checkPhaseAccess(phase);
        expect(result.allowed, true, reason: 'Phase $phase should be allowed for Pro');
      }
    });
    
    test('should provide correct available phases', () {
      final freePhases = freeCoaching.getAvailablePhases();
      final proPhases = proCoaching.getAvailablePhases();
      
      expect(freePhases.length, 2);
      expect(freePhases, contains(coach.CoachPhase.stabilize));
      expect(freePhases, contains(coach.CoachPhase.open));
      
      expect(proPhases.length, 6);
      expect(proPhases, equals(coach.CoachPhase.values));
    });
    
    test('should identify max available phase correctly', () {
      expect(freeCoaching.getMaxAvailablePhase(), coach.CoachPhase.open);
      expect(proCoaching.getMaxAvailablePhase(), coach.CoachPhase.close);
    });
    
    test('should detect free coaching limits', () {
      final completedPhases = [coach.CoachPhase.stabilize, coach.CoachPhase.open];
      
      expect(freeCoaching.hasReachedFreeLimit(completedPhases), true);
      expect(proCoaching.hasReachedFreeLimit(completedPhases), false);
    });
  });
  
  group('InsightsFeatureGates', () {
    late InsightsFeatureGates freeInsights;
    late InsightsFeatureGates proInsights;
    
    setUp(() {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      freeInsights = InsightsFeatureGates(freeGates);
      proInsights = InsightsFeatureGates(proGates);
    });
    
    test('should block advanced insights for free users', () {
      final correlations = freeInsights.checkMoodFocusCorrelations();
      final associations = freeInsights.checkTagAssociations();
      final keywords = freeInsights.checkKeywordUplift();
      final history = freeInsights.checkExtendedHistory();
      
      expect(correlations.allowed, false);
      expect(associations.allowed, false);
      expect(keywords.allowed, false);
      expect(history.allowed, false);
      
      expect(correlations.upgradeMessage, contains('mood affects focus'));
      expect(associations.upgradeMessage, contains('best focus days'));
    });
    
    test('should allow advanced insights for Pro users', () {
      final correlations = proInsights.checkMoodFocusCorrelations();
      final associations = proInsights.checkTagAssociations();
      final keywords = proInsights.checkKeywordUplift();
      final history = proInsights.checkExtendedHistory();
      
      expect(correlations.allowed, true);
      expect(associations.allowed, true);
      expect(keywords.allowed, true);
      expect(history.allowed, true);
    });
    
    test('should provide correct feature lists', () {
      final freeFeatures = freeInsights.getAvailableFeatures();
      final proFeatures = proInsights.getAvailableFeatures();
      
      expect(freeFeatures.length, 2);
      expect(freeFeatures, contains('Basic Statistics'));
      
      expect(proFeatures.length, 7);
      expect(proFeatures, contains('Mood-Focus Correlations'));
      expect(proFeatures, contains('Extended Historical Data'));
    });
    
    test('should enforce date limits correctly', () {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final twoMonthsAgo = now.subtract(const Duration(days: 60));
      
      // Free users limited to 30 days
      expect(freeInsights.isDateRangeAllowed(oneWeekAgo, now), true);
      expect(freeInsights.isDateRangeAllowed(twoMonthsAgo, now), false);
      
      // Pro users have no date limits
      expect(proInsights.isDateRangeAllowed(oneWeekAgo, now), true);
      expect(proInsights.isDateRangeAllowed(twoMonthsAgo, now), true);
    });
    
    test('should filter date ranges for free users', () {
      final now = DateTime.now();
      final twoMonthsAgo = now.subtract(const Duration(days: 60));
      
      final filtered = freeInsights.getFilteredDateRange(twoMonthsAgo, now);
      
      expect(filtered.to, now);
      expect(filtered.from.isAfter(twoMonthsAgo), true);
      expect(filtered.from.difference(now).inDays.abs(), lessThanOrEqualTo(30));
    });
    
    test('should provide correct insights tier descriptions', () {
      expect(freeInsights.getInsightsTierDescription(), contains('Free Analytics'));
      expect(proInsights.getInsightsTierDescription(), contains('Pro Analytics'));
      expect(proInsights.getInsightsTierDescription(), contains('unlimited history'));
    });
  });
  
  group('ProFeature Extensions', () {
    test('should provide human-readable names and descriptions', () {
      for (final feature in ProFeature.values) {
        expect(feature.displayName.isNotEmpty, true);
        expect(feature.description.isNotEmpty, true);
        expect(feature.icon.isNotEmpty, true);
      }
      
      expect(ProFeature.unlimitedSessions.displayName, 'Unlimited Daily Sessions');
      expect(ProFeature.extendedCoaching.displayName, 'Extended AI Coaching');
      expect(ProFeature.advancedAnalytics.icon, '📊');
    });
  });
}