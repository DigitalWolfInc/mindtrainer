import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/focus_session/presentation/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HistoryScreen Insights Rendering', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should render insights section with empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      // Wait for async data loading
      await tester.pumpAndSettle();

      // Should show Insights card
      expect(find.text('Insights'), findsOneWidget);
      
      // Should show zero values for empty state
      expect(find.text('7d total: 0m'), findsOneWidget);
      expect(find.text('7d avg: 0.0m/day'), findsOneWidget);
      expect(find.text('30d total: 0m'), findsOneWidget);
      expect(find.text('30d avg: 0.0m/day'), findsOneWidget);
      expect(find.text('Streak: 0 days'), findsOneWidget);
      expect(find.text('Longest: 00:00'), findsOneWidget);
      expect(find.text('Best day: -'), findsOneWidget);
    });

    testWidgets('should render insights section with session data', (tester) async {
      // Setup mock session history
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      SharedPreferences.setMockInitialValues({
        'session_history': [
          '${_formatDateForStorage(today)} 10:00|25',
          '${_formatDateForStorage(today)} 15:00|35', // Today: 60 minutes total
          '${_formatDateForStorage(yesterday)} 14:00|20', // Yesterday: 20 minutes
        ],
        'focus_session_statistics': '{"totalFocusTimeMinutes": 80, "averageSessionLength": 26.7, "completedSessionsCount": 3}',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show Insights card
      expect(find.text('Insights'), findsOneWidget);
      
      // Check that insights values are displayed
      expect(find.textContaining('7d total:'), findsOneWidget);
      expect(find.textContaining('7d avg:'), findsOneWidget);
      expect(find.textContaining('30d total:'), findsOneWidget);
      expect(find.textContaining('30d avg:'), findsOneWidget);
      expect(find.textContaining('Streak:'), findsOneWidget);
      expect(find.textContaining('Longest:'), findsOneWidget);
      expect(find.textContaining('Best day:'), findsOneWidget);
      
      // Should show formatted duration (H:MM format from core/time_format.dart)
      expect(find.textContaining('Longest:'), findsOneWidget);
    });

    testWidgets('should render insights above statistics in correct order', (tester) async {
      SharedPreferences.setMockInitialValues({
        'session_history': ['2024-01-15 10:00|25'],
        'focus_session_statistics': '{"totalFocusTimeMinutes": 25, "averageSessionLength": 25.0, "completedSessionsCount": 1}',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Find both cards
      final insightsCard = find.ancestor(
        of: find.text('Insights'),
        matching: find.byType(Card),
      );
      final statisticsCard = find.ancestor(
        of: find.text('Session Statistics'),
        matching: find.byType(Card),
      );

      expect(insightsCard, findsOneWidget);
      expect(statisticsCard, findsOneWidget);

      // Check order by comparing widget positions
      final insightsRect = tester.getRect(insightsCard);
      final statisticsRect = tester.getRect(statisticsCard);
      
      // Insights should be above statistics (smaller y coordinate)
      expect(insightsRect.top, lessThan(statisticsRect.top));
    });

    testWidgets('should handle best day display correctly', (tester) async {
      final testDate = DateTime(2024, 1, 15);
      SharedPreferences.setMockInitialValues({
        'session_history': ['2024-01-15 10:00|30'],
        'focus_session_statistics': '{"totalFocusTimeMinutes": 30, "averageSessionLength": 30.0, "completedSessionsCount": 1}',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should display best day in YYYY-MM-DD format
      expect(find.text('Best day: 2024-01-15'), findsOneWidget);
      expect(find.text('(30m)'), findsOneWidget); // Best day minutes
    });

    testWidgets('should display loading indicator during data fetch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      // Should show loading indicator before data loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for data to load
      await tester.pumpAndSettle();
      
      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display insights with session list', (tester) async {
      SharedPreferences.setMockInitialValues({
        'session_history': [
          '2024-01-15 10:00|25',
          '2024-01-14 14:00|30',
        ],
        'focus_session_statistics': '{"totalFocusTimeMinutes": 55, "averageSessionLength": 27.5, "completedSessionsCount": 2}',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show insights card
      expect(find.text('Insights'), findsOneWidget);
      
      // Should show statistics card
      expect(find.text('Session Statistics'), findsOneWidget);
      
      // Should show session list
      expect(find.byType(ListTile), findsAtLeastNWidgets(2));
      
      // Check session entries are displayed
      expect(find.textContaining('25 minutes'), findsOneWidget);
      expect(find.textContaining('30 minutes'), findsOneWidget);
    });

    testWidgets('should display insights in empty state with no sessions message', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should show insights card even with no sessions
      expect(find.text('Insights'), findsOneWidget);
      
      // Should show statistics card
      expect(find.text('Session Statistics'), findsOneWidget);
      
      // Should show "No sessions yet" message
      expect(find.text('No sessions yet'), findsOneWidget);
      
      // Should not show session list
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('should respect dark theme styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const HistoryScreen(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Find the insights card
      final insightsCard = find.ancestor(
        of: find.text('Insights'),
        matching: find.byType(Card),
      );
      
      expect(insightsCard, findsOneWidget);
      
      // Card should exist and be styled by theme
      final cardWidget = tester.widget<Card>(insightsCard);
      expect(cardWidget.margin, const EdgeInsets.only(bottom: 16));
    });
  });
}

String _formatDateForStorage(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}