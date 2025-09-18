import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/session_tags.dart';
import 'package:mindtrainer/features/focus_session/domain/session_limit_service.dart';

void main() {
  group('SessionLimitService', () {
    late SessionLimitService freeService;
    late SessionLimitService proService;
    late List<Session> testSessions;
    
    setUp(() {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      freeService = SessionLimitService(freeGates);
      proService = SessionLimitService(proGates);
      
      // Create test sessions for today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      testSessions = [
        Session(
          id: '1',
          dateTime: today.add(const Duration(hours: 9)),
          durationMinutes: 25,
          tags: ['morning'],
        ),
        Session(
          id: '2',
          dateTime: today.add(const Duration(hours: 11)),
          durationMinutes: 30,
          tags: ['deep-work'],
        ),
        Session(
          id: '3',
          dateTime: today.add(const Duration(hours: 14)),
          durationMinutes: 20,
          tags: ['afternoon'],
        ),
      ];
    });
    
    group('Free User Session Limits', () {
      test('should allow sessions within daily limit', () {
        final result = freeService.checkCanStartSession(testSessions.take(3).toList());
        
        expect(result.canStart, true);
        expect(result.currentDailyCount, 3);
        expect(result.remainingToday, 2);
        expect(result.requiresUpgrade, false);
        expect(result.isUnlimited, false);
      });
      
      test('should show warning on last free session', () {
        final fourSessions = testSessions + [
          Session(
            id: '4',
            dateTime: DateTime.now(),
            durationMinutes: 25,
            tags: ['late'],
          ),
        ];
        
        final result = freeService.checkCanStartSession(fourSessions);
        
        expect(result.canStart, true);
        expect(result.currentDailyCount, 4);
        expect(result.remainingToday, 1);
        expect(result.message, contains('last free session'));
      });
      
      test('should block sessions at daily limit', () {
        final fiveSessions = testSessions + [
          Session(id: '4', dateTime: DateTime.now(), durationMinutes: 25, tags: []),
          Session(id: '5', dateTime: DateTime.now(), durationMinutes: 25, tags: []),
        ];
        
        final result = freeService.checkCanStartSession(fiveSessions);
        
        expect(result.canStart, false);
        expect(result.currentDailyCount, 5);
        expect(result.remainingToday, 0);
        expect(result.requiresUpgrade, true);
        expect(result.message, contains('daily limit'));
        expect(result.message, contains('Upgrade to Pro'));
      });
      
      test('should show approaching limit warning', () {
        final result = freeService.checkCanStartSession(testSessions.take(3).toList());
        
        expect(result.remainingToday, 2);
        expect(result.statusMessage, contains('Sessions today: 3/5'));
      });
      
      test('should only count today sessions', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final mixedSessions = [
          ...testSessions,
          Session(id: 'old1', dateTime: yesterday, durationMinutes: 25, tags: []),
          Session(id: 'old2', dateTime: yesterday, durationMinutes: 25, tags: []),
        ];
        
        final result = freeService.checkCanStartSession(mixedSessions);
        
        expect(result.currentDailyCount, 3); // Only today's sessions
        expect(result.remainingToday, 2);
      });
    });
    
    group('Pro User Unlimited Sessions', () {
      test('should allow unlimited sessions', () {
        final manySessions = List.generate(20, (i) => Session(
          id: 'session_$i',
          dateTime: DateTime.now(),
          durationMinutes: 25,
          tags: [],
        ));
        
        final result = proService.checkCanStartSession(manySessions);
        
        expect(result.canStart, true);
        expect(result.currentDailyCount, 20);
        expect(result.remainingToday, null);
        expect(result.requiresUpgrade, false);
        expect(result.isUnlimited, true);
      });
      
      test('should show Pro unlimited status', () {
        final result = proService.checkCanStartSession(testSessions);
        
        expect(result.statusMessage, contains('Pro Unlimited'));
        expect(result.message, contains('Pro Unlimited'));
      });
      
      test('should never require upgrade', () {
        final manySessions = List.generate(100, (i) => Session(
          id: 'session_$i',
          dateTime: DateTime.now(),
          durationMinutes: 25,
          tags: [],
        ));
        
        final result = proService.checkCanStartSession(manySessions);
        
        expect(result.requiresUpgrade, false);
        expect(result.canStart, true);
      });
    });
    
    group('Usage Summary', () {
      test('should provide correct free tier summary', () {
        final summary = freeService.getUsageSummary(testSessions);
        
        expect(summary.todaySessions, 3);
        expect(summary.dailyLimit, 5);
        expect(summary.tier, 'Free');
        expect(summary.upgradeAvailable, true);
        expect(summary.isUnlimited, false);
        expect(summary.dailyProgress, closeTo(0.6, 0.1)); // 3/5
        expect(summary.dailyUsageText, '3/5 sessions today');
      });
      
      test('should provide correct Pro tier summary', () {
        final summary = proService.getUsageSummary(testSessions);
        
        expect(summary.todaySessions, 3);
        expect(summary.dailyLimit, null);
        expect(summary.tier, 'Pro Unlimited');
        expect(summary.upgradeAvailable, false);
        expect(summary.isUnlimited, true);
        expect(summary.dailyProgress, null);
        expect(summary.dailyUsageText, '3 sessions today');
      });
      
      test('should calculate weekly averages', () {
        final now = DateTime.now();
        final weekSessions = [
          ...testSessions,
          Session(id: 'w1', dateTime: now.subtract(const Duration(days: 1)), durationMinutes: 25, tags: []),
          Session(id: 'w2', dateTime: now.subtract(const Duration(days: 2)), durationMinutes: 25, tags: []),
        ];
        
        final summary = freeService.getUsageSummary(weekSessions);
        
        expect(summary.weekSessions, 5);
        expect(summary.weeklyAverage, closeTo(5/7, 0.1));
        expect(summary.weeklyAverageText, contains('0.7 sessions/day'));
      });
    });
    
    group('Upgrade Hints', () {
      test('should show upgrade hints for active free users', () {
        // User with 3+ sessions today should see hints
        expect(freeService.shouldShowUpgradeHint(testSessions), true);
      });
      
      test('should not show upgrade hints for light users', () {
        final lightUsage = testSessions.take(1).toList();
        expect(freeService.shouldShowUpgradeHint(lightUsage), false);
      });
      
      test('should not show upgrade hints for Pro users', () {
        expect(proService.shouldShowUpgradeHint(testSessions), false);
      });
      
      test('should show hints if user hit limits recently', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        
        // User who had 5 sessions yesterday but only 1 today
        final recentLimitExperience = [
          Session(id: 'today1', dateTime: now, durationMinutes: 25, tags: []),
          ...List.generate(5, (i) => Session(
            id: 'yesterday_$i',
            dateTime: yesterday.add(Duration(hours: i + 8)),
            durationMinutes: 25,
            tags: [],
          )),
        ];
        
        expect(freeService.shouldShowUpgradeHint(recentLimitExperience), true);
      });
    });
    
    group('Pro Upgrade Benefits', () {
      test('should provide session-specific upgrade benefits', () {
        final benefits = freeService.getSessionUpgradeBenefits();
        
        expect(benefits.length, greaterThan(3));
        expect(benefits.any((b) => b.contains('Unlimited')), true);
        expect(benefits.any((b) => b.contains('interruptions')), true);
        expect(benefits.any((b) => b.contains('intensive')), true);
      });
    });
  });
  
  group('SessionStartResult', () {
    test('should create correct allowed result', () {
      const result = SessionStartResult.allowed(
        currentCount: 2,
        remaining: 3,
        message: 'Ready to focus',
      );
      
      expect(result.canStart, true);
      expect(result.requiresUpgrade, false);
      expect(result.currentDailyCount, 2);
      expect(result.remainingToday, 3);
      expect(result.message, 'Ready to focus');
    });
    
    test('should create correct warning result', () {
      const result = SessionStartResult.warning(
        currentCount: 4,
        remaining: 1,
        message: 'Last session warning',
      );
      
      expect(result.canStart, true);
      expect(result.requiresUpgrade, false);
      expect(result.currentDailyCount, 4);
      expect(result.remainingToday, 1);
    });
    
    test('should create correct limit reached result', () {
      const result = SessionStartResult.limitReached(
        currentCount: 5,
        upgradeMessage: 'Upgrade now!',
      );
      
      expect(result.canStart, false);
      expect(result.requiresUpgrade, true);
      expect(result.currentDailyCount, 5);
      expect(result.remainingToday, 0);
    });
    
    test('should format status messages correctly', () {
      const unlimited = SessionStartResult.allowed(currentCount: 10);
      const limited = SessionStartResult.allowed(currentCount: 2, remaining: 3);
      const lastSession = SessionStartResult.warning(
        currentCount: 4,
        remaining: 1,
        message: 'Last free session today',
      );
      
      expect(unlimited.statusMessage, contains('Pro Unlimited'));
      expect(limited.statusMessage, contains('2/5'));
      expect(limited.statusMessage, contains('3 remaining'));
      expect(lastSession.statusMessage, contains('Upgrade for unlimited'));
    });
  });
  
  group('SessionUsageSummary', () {
    test('should calculate daily progress correctly', () {
      const freeUsage = SessionUsageSummary(
        todaySessions: 3,
        weekSessions: 10,
        dailyLimit: 5,
        weeklyAverage: 1.4,
        tier: 'Free',
        upgradeAvailable: true,
      );
      
      const proUsage = SessionUsageSummary(
        todaySessions: 8,
        weekSessions: 20,
        weeklyAverage: 2.8,
        tier: 'Pro',
        upgradeAvailable: false,
      );
      
      expect(freeUsage.dailyProgress, closeTo(0.6, 0.01)); // 3/5
      expect(freeUsage.isUnlimited, false);
      expect(freeUsage.dailyUsageText, '3/5 sessions today');
      
      expect(proUsage.dailyProgress, null);
      expect(proUsage.isUnlimited, true);
      expect(proUsage.dailyUsageText, '8 sessions today');
    });
    
    test('should format weekly averages', () {
      const usage = SessionUsageSummary(
        todaySessions: 1,
        weekSessions: 12,
        weeklyAverage: 1.714,
        tier: 'Free',
        upgradeAvailable: true,
      );
      
      expect(usage.weeklyAverageText, '1.7 sessions/day this week');
    });
  });
}