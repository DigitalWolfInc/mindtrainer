import 'package:flutter/material.dart';
import '../domain/mood_focus_insights.dart';

class MoodFocusDetailsScreen extends StatelessWidget {
  final MoodFocusInsightsResult insights;

  const MoodFocusDetailsScreen({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood ↔ Focus Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            const Text(
              'Daily Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: insights.dailyPairs.isEmpty
                  ? const Center(
                      child: Text(
                        'No data available.\nComplete some focus sessions and mood check-ins to see insights.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : _buildDataTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final correlationText = insights.weeklyCorrelation != null
        ? insights.weeklyCorrelation!.toStringAsFixed(2)
        : 'Need 5+ days';
    
    final topMoodsText = insights.topFocusMoods.isNotEmpty
        ? insights.topFocusMoods.join(', ')
        : 'No data yet';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Correlation',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('r = $correlationText'),
                      const SizedBox(height: 8),
                      const Text(
                        'Data Points',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('${insights.dailyPairs.length} days'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Focus Moods',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        topMoodsText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Mood Score'), numeric: true),
          DataColumn(label: Text('Focus (min)'), numeric: true),
        ],
        rows: insights.dailyPairs.map((pair) {
          return DataRow(
            cells: [
              DataCell(Text(_formatDate(pair.date))),
              DataCell(Text(pair.moodScore.toStringAsFixed(1))),
              DataCell(Text('${pair.focusMinutes}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }
}