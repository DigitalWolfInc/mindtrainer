import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/session_tags.dart';
import 'package:mindtrainer/features/focus_session/domain/session_limit_service.dart';

/// Integration tests for Pro session limits feature
/// Tests the complete flow from free tier → Pro upgrade → unlimited access
void main() {
  group('Pro Session Limits Integration', () {
    late List<Session> testSessions;
    late DateTime today;
    
    setUp(() {
      final now = DateTime.now();
      today = DateTime(now.year, now.month, now.day);
      
      // Create 4 sessions today (approaching free limit)
      testSessions = List.generate(4, (i) => Session(
        id: 'session_$i',
        dateTime: today.add(Duration(hours: 8 + i * 2)),
        durationMinutes: 25,
        tags: ['focus'],
      ));
    });
    
    group('Free User Experience', () {
      test('should allow starting session when under limit', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        final result = service.checkCanStartSession(testSessions.take(3).toList());
        
        expect(result.canStart, true);
        expect(result.requiresUpgrade, false);
        expect(result.currentDailyCount, 3);
        expect(result.remainingToday, 2);
        expect(result.isUnlimited, false);
      });
      
      test('should warn on last free session', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        final result = service.checkCanStartSession(testSessions);
        
        expect(result.canStart, true);
        expect(result.requiresUpgrade, false);
        expect(result.currentDailyCount, 4);
        expect(result.remainingToday, 1);
        expect(result.statusMessage, contains('Last free session'));
      });
      
      test('should block session at daily limit', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        // Add 5th session to hit limit
        final fiveSessions = [...testSessions, Session(
          id: 'session_5',
          dateTime: today.add(const Duration(hours: 16)),
          durationMinutes: 25,
          tags: ['focus'],
        )];
        
        final result = service.checkCanStartSession(fiveSessions);
        
        expect(result.canStart, false);
        expect(result.requiresUpgrade, true);
        expect(result.currentDailyCount, 5);
        expect(result.remainingToday, 0);
        expect(result.message, contains('Upgrade to Pro'));
      });
      
      test('should provide usage summary for free tier', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        final summary = service.getUsageSummary(testSessions);
        
        expect(summary.todaySessions, 4);
        expect(summary.dailyLimit, 5);
        expect(summary.tier, 'Free');
        expect(summary.upgradeAvailable, true);
        expect(summary.dailyUsageText, '4/5 sessions today');
        expect(summary.dailyProgress, closeTo(0.8, 0.1));
      });
      
      test('should show upgrade hints for active users', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        expect(service.shouldShowUpgradeHint(testSessions), true);
      });
    });
    
    group('Pro User Experience', () {
      test('should allow unlimited sessions', () {
        final proGates = MindTrainerProGates.fromStatusCheck(() => true);
        final service = SessionLimitService(proGates);
        
        // Create 20 sessions to test unlimited
        final manySessions = List.generate(20, (i) => Session(
          id: 'session_$i',
          dateTime: today.add(Duration(minutes: i * 30)),
          durationMinutes: 25,
          tags: ['focus'],
        ));
        
        final result = service.checkCanStartSession(manySessions);
        
        expect(result.canStart, true);
        expect(result.requiresUpgrade, false);
        expect(result.currentDailyCount, 20);
        expect(result.remainingToday, null);
        expect(result.isUnlimited, true);
        expect(result.statusMessage, contains('Pro Unlimited'));
      });
      
      test('should provide usage summary for Pro tier', () {
        final proGates = MindTrainerProGates.fromStatusCheck(() => true);
        final service = SessionLimitService(proGates);
        
        final summary = service.getUsageSummary(testSessions);
        
        expect(summary.todaySessions, 4);
        expect(summary.dailyLimit, null);
        expect(summary.tier, 'Pro Unlimited');
        expect(summary.upgradeAvailable, false);
        expect(summary.dailyUsageText, '4 sessions today');
        expect(summary.isUnlimited, true);
      });
      
      test('should not show upgrade hints for Pro users', () {
        final proGates = MindTrainerProGates.fromStatusCheck(() => true);
        final service = SessionLimitService(proGates);
        
        expect(service.shouldShowUpgradeHint(testSessions), false);
      });
    });
    
    group('Free-to-Pro Transition', () {
      test('should handle upgrade during active session day', () {
        // Start as free user with sessions today
        bool isProActive = false;
        final dynamicGates = MindTrainerProGates.fromStatusCheck(() => isProActive);
        final service = SessionLimitService(dynamicGates);
        
        // Free user at limit
        final fiveSessions = [...testSessions, Session(
          id: 'session_5',
          dateTime: today.add(const Duration(hours: 16)),
          durationMinutes: 25,
          tags: ['focus'],
        )];
        
        var result = service.checkCanStartSession(fiveSessions);
        expect(result.canStart, false);
        expect(result.requiresUpgrade, true);
        
        // Simulate Pro upgrade
        isProActive = true;
        
        // Should now allow unlimited sessions
        result = service.checkCanStartSession(fiveSessions);
        expect(result.canStart, true);
        expect(result.requiresUpgrade, false);
        expect(result.isUnlimited, true);
        expect(result.statusMessage, contains('Pro Unlimited'));
      });
      
      test('should maintain session history across upgrade', () {
        bool isProActive = false;
        final dynamicGates = MindTrainerProGates.fromStatusCheck(() => isProActive);
        final service = SessionLimitService(dynamicGates);
        
        // Free user with sessions
        var summary = service.getUsageSummary(testSessions);
        expect(summary.todaySessions, 4);
        expect(summary.tier, 'Free');
        
        // Upgrade to Pro
        isProActive = true;
        
        // Same session count, but now Pro tier
        summary = service.getUsageSummary(testSessions);
        expect(summary.todaySessions, 4);
        expect(summary.tier, 'Pro Unlimited');
        expect(summary.upgradeAvailable, false);
      });
      
      test('should provide correct upgrade benefits', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        final benefits = service.getSessionUpgradeBenefits();
        
        expect(benefits, isNotEmpty);
        expect(benefits.any((b) => b.contains('Unlimited')), true);
        expect(benefits.any((b) => b.contains('interruptions')), true);
        expect(benefits.length, greaterThanOrEqualTo(3));
      });
    });
    
    group('Edge Cases', () {
      test('should handle empty session list', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        final result = service.checkCanStartSession([]);
        
        expect(result.canStart, true);
        expect(result.currentDailyCount, 0);
        expect(result.remainingToday, 5);
      });
      
      test('should only count sessions from today', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        // Mix of today's and yesterday's sessions
        final yesterday = today.subtract(const Duration(days: 1));
        final mixedSessions = [
          ...testSessions, // 4 today
          Session(id: 'old1', dateTime: yesterday, durationMinutes: 25, tags: []),
          Session(id: 'old2', dateTime: yesterday, durationMinutes: 25, tags: []),
        ];
        
        final result = service.checkCanStartSession(mixedSessions);
        
        expect(result.currentDailyCount, 4); // Only today's count
        expect(result.remainingToday, 1);
      });
      
      test('should handle midnight boundary correctly', () {
        final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
        final service = SessionLimitService(freeGates);
        
        // Sessions right at midnight boundary
        final todayStart = today;
        final yesterdayEnd = today.subtract(const Duration(minutes: 1));
        
        final boundarySessions = [
          Session(id: 'yesterday', dateTime: yesterdayEnd, durationMinutes: 25, tags: []),
          Session(id: 'today', dateTime: todayStart, durationMinutes: 25, tags: []),
        ];
        
        final result = service.checkCanStartSession(boundarySessions);
        
        expect(result.currentDailyCount, 1); // Only today's session
      });
    });
  });
}