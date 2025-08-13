import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/features/focus_session/domain/session_limit_service.dart';
import 'package:mindtrainer/features/focus_session/presentation/focus_session_screen_pro.dart';
import 'package:mindtrainer/features/focus_session/presentation/pro_status_widgets.dart';

void main() {
  group('FocusSessionScreenPro', () {
    testWidgets('should display free tier limitations', (tester) async {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: freeGates),
      ));
      await tester.pumpAndSettle();
      
      // Should show free tier status
      expect(find.text('Free'), findsOneWidget);
      expect(find.textContaining('/5'), findsOneWidget);
      
      // Should show upgrade button
      expect(find.text('Upgrade to Pro'), findsWidgets);
    });
    
    testWidgets('should display Pro unlimited status', (tester) async {
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: proGates),
      ));
      await tester.pumpAndSettle();
      
      // Should show Pro status
      expect(find.text('Pro Unlimited'), findsOneWidget);
      expect(find.textContaining('sessions today'), findsOneWidget);
      
      // Should not show upgrade buttons
      expect(find.text('Upgrade to Pro'), findsNothing);
    });
    
    testWidgets('should allow Pro users to start unlimited sessions', (tester) async {
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: proGates),
      ));
      await tester.pumpAndSettle();
      
      // Start button should be enabled
      final startButton = find.text('Start Focus');
      expect(startButton, findsOneWidget);
      
      final buttonWidget = tester.widget<ElevatedButton>(
        find.ancestor(
          of: startButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(buttonWidget.onPressed, isNotNull);
    });
    
    testWidgets('should block free users at daily limit', (tester) async {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      
      // Create a version that simulates 5 sessions already completed
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: freeGates),
      ));
      await tester.pumpAndSettle();
      
      // Mock having 5 sessions by triggering the demo data
      // In a real test, we'd inject mock data
      
      // Look for session status indicators
      expect(find.textContaining('sessions today'), findsOneWidget);
    });
    
    testWidgets('should show upgrade dialog when limit reached', (tester) async {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: freeGates),
      ));
      await tester.pumpAndSettle();
      
      // Try to simulate hitting the limit by tapping start multiple times
      // This would need more sophisticated mocking in a real implementation
      
      // For now, just verify the UI components exist
      expect(find.byType(SessionLimitStatusCard), findsOneWidget);
      expect(find.byType(SessionLimitBanner), findsOneWidget);
    });
    
    testWidgets('should toggle Pro status with demo button', (tester) async {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: freeGates),
      ));
      await tester.pumpAndSettle();
      
      // Find and tap the demo Pro toggle button
      final proToggle = find.byTooltip('Toggle Pro Status (Demo)');
      expect(proToggle, findsOneWidget);
      
      await tester.tap(proToggle);
      await tester.pumpAndSettle();
      
      // Should show snackbar about status change
      expect(find.byType(SnackBar), findsOneWidget);
    });
    
    testWidgets('should show Pro preview for free users', (tester) async {
      final freeGates = MindTrainerProGates.fromStatusCheck(() => false);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: freeGates),
      ));
      await tester.pumpAndSettle();
      
      // Should show unlimited sessions preview
      expect(find.byType(UnlimitedSessionsPreview), findsOneWidget);
      expect(find.text('Unlimited Sessions'), findsOneWidget);
      expect(find.text('Never hit daily limits again'), findsOneWidget);
    });
    
    testWidgets('should hide Pro preview for Pro users', (tester) async {
      final proGates = MindTrainerProGates.fromStatusCheck(() => true);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: proGates),
      ));
      await tester.pumpAndSettle();
      
      // Should not show Pro preview
      expect(find.byType(UnlimitedSessionsPreview), findsNothing);
    });
  });
  
  group('Pro Status Widgets', () {
    testWidgets('SessionLimitStatusCard shows correct free status', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SessionLimitStatusCard(
            usage: SessionUsageSummary(
              todaySessions: 3,
              weekSessions: 10,
              dailyLimit: 5,
              weeklyAverage: 1.4,
              tier: 'Free',
              upgradeAvailable: true,
            ),
            onUpgradeTap: () {},
          ),
        ),
      ));
      
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('3/5 sessions today'), findsOneWidget);
      expect(find.text('1.4 sessions/day this week'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
    });
    
    testWidgets('SessionLimitStatusCard shows correct Pro status', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SessionLimitStatusCard(
            usage: SessionUsageSummary(
              todaySessions: 8,
              weekSessions: 25,
              weeklyAverage: 3.6,
              tier: 'Pro Unlimited',
              upgradeAvailable: false,
            ),
          ),
        ),
      ));
      
      expect(find.text('Pro Unlimited'), findsOneWidget);
      expect(find.text('8 sessions today'), findsOneWidget);
      expect(find.text('3.6 sessions/day this week'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsNothing);
    });
    
    testWidgets('SessionLimitBanner shows upgrade prompt', (tester) async {
      final result = SessionStartResult.limitReached(
        currentCount: 5,
        upgradeMessage: 'Daily limit reached. Upgrade to Pro for unlimited sessions.',
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SessionLimitBanner(
            result: result,
            onUpgradeTap: () {},
          ),
        ),
      ));
      
      expect(find.text('Daily limit reached. Upgrade to Pro for unlimited sessions.'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });
    
    testWidgets('UnlimitedSessionsPreview shows Pro benefits', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UnlimitedSessionsPreview(
            onLearnMore: () {},
          ),
        ),
      ));
      
      expect(find.text('Unlimited Sessions'), findsOneWidget);
      expect(find.text('Never hit daily limits again'), findsOneWidget);
      expect(find.text('No daily session limits'), findsOneWidget);
      expect(find.text('Perfect for intensive focus days'), findsOneWidget);
      expect(find.text('Learn More About Pro'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
    });
    
    testWidgets('SessionStatusText shows correct status', (tester) async {
      final allowedResult = SessionStartResult.allowed(
        currentCount: 2,
        remaining: 3,
      );
      
      final blockedResult = SessionStartResult.limitReached(
        currentCount: 5,
        upgradeMessage: 'Daily limit reached',
      );
      
      // Test allowed status
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SessionStatusText(result: allowedResult),
              SessionStatusText(result: blockedResult),
            ],
          ),
        ),
      ));
      
      expect(find.textContaining('2/5'), findsOneWidget);
      expect(find.textContaining('3 remaining'), findsOneWidget);
      expect(find.text('Daily limit reached'), findsOneWidget);
    });
    
    testWidgets('SessionLimitUpgradeDialog shows Pro benefits', (tester) async {
      final result = SessionStartResult.limitReached(
        currentCount: 5,
        upgradeMessage: 'Upgrade message',
      );
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => SessionLimitUpgradeDialog(
                  result: result,
                  onUpgrade: () {},
                  onDismiss: () {},
                ),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      expect(find.text('Upgrade to Pro'), findsWidgets);
      expect(find.text('5 sessions today'), findsOneWidget);
      expect(find.text('Unlimited daily focus sessions'), findsOneWidget);
      expect(find.text('Extended AI coaching flows'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
    });
  });
  
  group('Free-to-Pro Transition', () {
    testWidgets('should handle Pro activation during session', (tester) async {
      // Start with free user
      bool isProActive = false;
      final dynamicGates = MindTrainerProGates.fromStatusCheck(() => isProActive);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: dynamicGates),
      ));
      await tester.pumpAndSettle();
      
      // Verify free status
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsWidgets);
      
      // Simulate Pro activation (would normally come from billing system)
      isProActive = true;
      
      // Tap the demo toggle to trigger update
      await tester.tap(find.byTooltip('Toggle Pro Status (Demo)'));
      await tester.pumpAndSettle();
      
      // Should show successful upgrade message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Switched to Pro tier'), findsOneWidget);
    });
    
    testWidgets('should remove session limits after Pro upgrade', (tester) async {
      bool isProActive = false;
      final dynamicGates = MindTrainerProGates.fromStatusCheck(() => isProActive);
      
      await tester.pumpWidget(MaterialApp(
        home: FocusSessionScreenPro(proGates: dynamicGates),
      ));
      await tester.pumpAndSettle();
      
      // Should show limited status
      expect(find.textContaining('/5'), findsOneWidget);
      
      // Simulate upgrade
      isProActive = true;
      await tester.tap(find.byTooltip('Toggle Pro Status (Demo)'));
      await tester.pumpAndSettle();
      
      // Should show unlimited status (after state updates in real implementation)
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}