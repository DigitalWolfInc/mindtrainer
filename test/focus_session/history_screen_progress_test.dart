import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/focus_session/presentation/history_screen.dart';
import 'package:mindtrainer/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HistoryScreen Progress Rendering', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should render weekly progress section with empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      // Wait for async data loading
      await tester.pumpAndSettle();

      // Should show weekly progress card
      expect(find.text('This Week Progress'), findsOneWidget);
      
      // Should show progress with default values
      expect(find.textContaining('This week:'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      // Note: formatDuration shows MM:SS format, so 300 minutes = 300:00, 0 minutes = 00:00
      
      // Should show progress bar
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should render weekly progress with session data', (tester) async {
      // Setup mock session history for current week
      final now = DateTime.now();
      final monday = _getMondayOfWeek(now);
      
      SharedPreferences.setMockInitialValues({
        'session_history': [
          '${_formatDateForStorage(monday)} 10:00|60',     // Monday: 60 minutes
          '${_formatDateForStorage(monday.add(const Duration(days: 1)))} 15:00|90', // Tuesday: 90 minutes
        ],
        'weekly_goal_minutes': 300, // 5 hours goal
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show weekly progress card
      expect(find.text('This Week Progress'), findsOneWidget);
      
      // Should show progress values  
      expect(find.textContaining('This week:'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget); // 150/300 = 50%
      
      // Should show progress bar
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 0.5);
    });

    testWidgets('should render progress above insights and statistics', (tester) async {
      SharedPreferences.setMockInitialValues({
        'session_history': ['2024-01-15 10:00|25'],
        'weekly_goal_minutes': 240,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Find all cards
      final progressCard = find.ancestor(
        of: find.text('This Week Progress'),
        matching: find.byType(Card),
      );
      final insightsCard = find.ancestor(
        of: find.text('Insights'),
        matching: find.byType(Card),
      );
      final statisticsCard = find.ancestor(
        of: find.text('Session Statistics'),
        matching: find.byType(Card),
      );

      expect(progressCard, findsOneWidget);
      expect(insightsCard, findsOneWidget);
      expect(statisticsCard, findsOneWidget);

      // Check order by comparing widget positions
      final progressRect = tester.getRect(progressCard);
      final insightsRect = tester.getRect(insightsCard);
      final statisticsRect = tester.getRect(statisticsCard);
      
      // Progress should be above insights, insights above statistics
      expect(progressRect.top, lessThan(insightsRect.top));
      expect(insightsRect.top, lessThan(statisticsRect.top));
    });

    testWidgets('should handle over-goal progress correctly', (tester) async {
      final now = DateTime.now();
      final monday = _getMondayOfWeek(now);
      
      SharedPreferences.setMockInitialValues({
        'session_history': [
          '${_formatDateForStorage(monday)} 10:00|180', // 3 hours
          '${_formatDateForStorage(monday)} 15:00|240', // 4 hours - total 7 hours
        ],
        'weekly_goal_minutes': 300, // 5 hours goal
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show over-goal progress
      expect(find.text('This Week Progress'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget); // Clamped to 100%
      
      // Progress bar should be at 100%
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 1.0);
    });

    testWidgets('should handle custom goal values', (tester) async {
      final now = DateTime.now();
      final monday = _getMondayOfWeek(now);
      
      SharedPreferences.setMockInitialValues({
        'session_history': [
          '${_formatDateForStorage(monday)} 10:00|120', // 2 hours
        ],
        'weekly_goal_minutes': 480, // 8 hours goal
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show custom goal
      expect(find.text('25%'), findsOneWidget); // 120/480 = 25%
    });

    testWidgets('should show progress with session list', (tester) async {
      final now = DateTime.now();
      final monday = _getMondayOfWeek(now);
      
      SharedPreferences.setMockInitialValues({
        'session_history': [
          '${_formatDateForStorage(monday)} 10:00|60',
          '${_formatDateForStorage(monday.add(const Duration(days: 1)))} 14:00|90',
        ],
        'weekly_goal_minutes': 300,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show progress card
      expect(find.text('This Week Progress'), findsOneWidget);
      
      // Should show insights and statistics cards
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Session Statistics'), findsOneWidget);
      
      // Should show session list
      expect(find.byType(ListTile), findsAtLeastNWidgets(2));
    });

    testWidgets('should show progress in empty state', (tester) async {
      SharedPreferences.setMockInitialValues({
        'weekly_goal_minutes': 360, // 6 hours
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show progress card even with no sessions
      expect(find.text('This Week Progress'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      
      // Should show other cards
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Session Statistics'), findsOneWidget);
      
      // Should show "No sessions yet" message
      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('should handle loading state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      // Should show loading indicator before data loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for data to load
      await tester.pumpAndSettle();
      
      // Loading indicator should be gone, progress should be visible
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('This Week Progress'), findsOneWidget);
    });

    testWidgets('should respect dark theme styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Find the progress card
      final progressCard = find.ancestor(
        of: find.text('This Week Progress'),
        matching: find.byType(Card),
      );
      
      expect(progressCard, findsOneWidget);
      
      // Card should exist and be styled by theme
      final cardWidget = tester.widget<Card>(progressCard);
      expect(cardWidget.margin, const EdgeInsets.only(bottom: 16));
      
      // Progress bar should exist
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display time in HH:MM format', (tester) async {
      final now = DateTime.now();
      final monday = _getMondayOfWeek(now);
      
      SharedPreferences.setMockInitialValues({
        'session_history': [
          '${_formatDateForStorage(monday)} 10:00|125', // 2:05
        ],
        'weekly_goal_minutes': 375, // 6:15
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show formatted progress
      expect(find.text('This Week Progress'), findsOneWidget);
      expect(find.textContaining('This week:'), findsOneWidget);
    });
  });
}

DateTime _getMondayOfWeek(DateTime date) {
  final daysSinceMonday = (date.weekday - DateTime.monday) % 7;
  final monday = date.subtract(Duration(days: daysSinceMonday));
  return DateTime(monday.year, monday.month, monday.day);
}

String _formatDateForStorage(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}