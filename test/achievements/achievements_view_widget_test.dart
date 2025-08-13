import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_resolver.dart';
import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/achievements_view.dart';
import '../../lib/achievements/badge.dart';
import '../../lib/achievements/badge_ids.dart';
import '../../lib/achievements/snapshot.dart';

void main() {
  group('AchievementsView Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    tearDown(() {
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    testWidgets('should display app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('should show empty state when no badges are unlocked', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should show grid with locked badges only
      expect(find.byType(GridView), findsOneWidget);
      
      // All badges should be in locked state (grayed out)
      final iconWidgets = tester.widgetList<Icon>(find.byType(Icon));
      expect(iconWidgets.length, greaterThan(0));
      
      // Check that some icons are grayed out (locked state)
      final grayedIcons = iconWidgets.where((icon) => icon.color == Colors.grey[400]);
      expect(grayedIcons.length, greaterThan(0));
    });

    testWidgets('should display unlocked badges with correct styling', (WidgetTester tester) async {
      // Setup some unlocked badges
      final store = AchievementsStore.instance;
      await store.init();

      final unlockedBadges = {
        BadgeIds.firstSession: Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
          meta: {'sessionCount': 1},
        ),
        BadgeIds.fiveSessions: Badge.create(
          id: BadgeIds.fiveSessions,
          title: 'Getting Started',
          description: 'Completed 5 focus sessions.',
          tier: 1,
          meta: {'sessionCount': 5},
        ),
      };

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: unlockedBadges,
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      // Wait for initialization and state updates
      await tester.pumpAndSettle();

      // Should find unlocked badge cards
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('Getting Started'), findsOneWidget);

      // Check that unlocked badges are not grayed out
      final cards = tester.widgetList<Card>(find.byType(Card));
      expect(cards.length, greaterThan(0));
    });

    testWidgets('should show locked badges as grayed out placeholders', (WidgetTester tester) async {
      // Setup one unlocked badge, leaving others locked
      final store = AchievementsStore.instance;
      await store.init();

      final unlockedBadges = {
        BadgeIds.firstSession: Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
        ),
      };

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: unlockedBadges,
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the unlocked badge
      expect(find.text('First Step'), findsOneWidget);
      
      // Should have locked badges (total badges = 16, unlocked = 1, so 15 locked)
      final lockIcons = find.byIcon(Icons.lock);
      expect(lockIcons, findsWidgets);
    });

    testWidgets('should display badge grid with correct layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have a GridView with 2 columns
      expect(find.byType(GridView), findsOneWidget);
      
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.childAspectRatio, 1.1);
    });

    testWidgets('should handle tap on unlocked badge and show dialog', (WidgetTester tester) async {
      // Setup an unlocked badge
      final store = AchievementsStore.instance;
      await store.init();

      final badge = Badge.create(
        id: BadgeIds.firstSession,
        title: 'First Step',
        description: 'Completed your first focus session.',
        tier: 1,
        meta: {'sessionCount': 1},
        unlockedAt: DateTime(2023, 1, 15, 10, 30),
      );

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: {badge.id: badge},
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the unlocked badge
      await tester.tap(find.text('First Step'));
      await tester.pumpAndSettle();

      // Should show badge detail dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('First Step'), findsNWidgets(2)); // One in list, one in dialog
      expect(find.text('Completed your first focus session.'), findsOneWidget);
      expect(find.text('January 15, 2023'), findsOneWidget); // Date format
      
      // Should show metadata
      expect(find.textContaining('sessionCount: 1'), findsOneWidget);
    });

    testWidgets('should handle tap on locked badge and show dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Find a locked badge card and tap it
      final lockIcon = find.byIcon(Icons.lock).first;
      await tester.tap(lockIcon);
      await tester.pumpAndSettle();

      // Should show locked badge dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Badge Locked'), findsOneWidget);
      expect(find.textContaining('Complete more sessions'), findsOneWidget);
    });

    testWidgets('should close badge dialog when OK is tapped', (WidgetTester tester) async {
      // Setup an unlocked badge
      final store = AchievementsStore.instance;
      await store.init();

      final badge = Badge.create(
        id: BadgeIds.firstSession,
        title: 'First Step',
        description: 'Completed your first focus session.',
        tier: 1,
      );

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: {badge.id: badge},
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap badge to open dialog
      await tester.tap(find.text('First Step'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap OK button to close dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should display badge count correctly', (WidgetTester tester) async {
      // Setup multiple unlocked badges
      final store = AchievementsStore.instance;
      await store.init();

      final unlockedBadges = {
        BadgeIds.firstSession: Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
        ),
        BadgeIds.fiveSessions: Badge.create(
          id: BadgeIds.fiveSessions,
          title: 'Getting Started',
          description: 'Completed 5 focus sessions.',
          tier: 1,
        ),
        BadgeIds.firstHourTotal: Badge.create(
          id: BadgeIds.firstHourTotal,
          title: 'First Hour',
          description: 'Accumulated 1 hour of total focus time.',
          tier: 1,
        ),
      };

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: unlockedBadges,
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the badge count somewhere (3 out of total)
      expect(find.textContaining('3'), findsOneWidget); // Badge count
      expect(find.textContaining('16'), findsOneWidget); // Total badges
    });

    testWidgets('should handle empty metadata gracefully', (WidgetTester tester) async {
      final store = AchievementsStore.instance;
      await store.init();

      final badge = Badge.create(
        id: BadgeIds.firstSession,
        title: 'First Step',
        description: 'Completed your first focus session.',
        tier: 1,
        meta: null, // No metadata
      );

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: {badge.id: badge},
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap badge to open dialog
      await tester.tap(find.text('First Step'));
      await tester.pumpAndSettle();

      // Should show dialog without crashing
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('First Step'), findsNWidgets(2));
      expect(find.text('Completed your first focus session.'), findsOneWidget);
    });

    testWidgets('should update when new badges are unlocked', (WidgetTester tester) async {
      final store = AchievementsStore.instance;
      await store.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no unlocked badges
      expect(find.text('First Step'), findsNothing);

      // Add a badge
      final badge = Badge.create(
        id: BadgeIds.firstSession,
        title: 'First Step',
        description: 'Completed your first focus session.',
        tier: 1,
      );

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: {badge.id: badge},
        updatedAt: DateTime.now(),
      ));

      await tester.pumpAndSettle();

      // Should now show the unlocked badge
      expect(find.text('First Step'), findsOneWidget);
    });

    testWidgets('should handle very long badge titles and descriptions', (WidgetTester tester) async {
      final store = AchievementsStore.instance;
      await store.init();

      final badge = Badge.create(
        id: BadgeIds.firstSession,
        title: 'This Is A Very Long Badge Title That Should Handle Text Wrapping Gracefully',
        description: 'This is an extremely long description that contains many words and should test the text wrapping and layout capabilities of the badge dialog and card display system.',
        tier: 1,
      );

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: {badge.id: badge},
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Should display without overflow errors
      expect(find.textContaining('This Is A Very Long Badge Title'), findsOneWidget);
      
      // Tap to open dialog
      await tester.tap(find.textContaining('This Is A Very Long Badge Title'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('extremely long description'), findsOneWidget);
    });

    testWidgets('should handle badge with complex metadata', (WidgetTester tester) async {
      final store = AchievementsStore.instance;
      await store.init();

      final badge = Badge.create(
        id: BadgeIds.focusMaster,
        title: 'Focus Master',
        description: 'Completed 10+ sessions tagged with "focus".',
        tier: 2,
        meta: {
          'tagName': 'focus',
          'tagCount': 15,
          'averageDuration': 32.5,
          'longestSession': 90,
          'tags': ['focus', 'work', 'productivity'],
          'nested': {
            'level1': {
              'level2': 'deep value'
            }
          }
        },
      );

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: {badge.id: badge},
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap badge to open dialog
      await tester.tap(find.text('Focus Master'));
      await tester.pumpAndSettle();

      // Should display metadata in dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('tagName: focus'), findsOneWidget);
      expect(find.textContaining('tagCount: 15'), findsOneWidget);
      expect(find.textContaining('averageDuration: 32.5'), findsOneWidget);
    });

    testWidgets('should support accessibility features', (WidgetTester tester) async {
      final store = AchievementsStore.instance;
      await store.init();

      final badge = Badge.create(
        id: BadgeIds.firstSession,
        title: 'First Step',
        description: 'Completed your first focus session.',
        tier: 1,
      );

      await store.replaceAll(AchievementsSnapshot.create(
        unlocked: {badge.id: badge},
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: AchievementsView(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for semantic labels
      final semantics = tester.getSemantics(find.text('First Step'));
      expect(semantics.label, contains('First Step'));
    });
  });
}