import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../../core/time_format.dart';
import '../../settings/domain/app_settings.dart';
import '../data/focus_session_statistics_storage.dart';
import '../domain/focus_session_statistics.dart';
import '../domain/focus_session_insights.dart';
import '../domain/insights_service.dart';
import '../domain/weekly_progress.dart';
import '../domain/weekly_progress_service.dart';
import '../domain/io_service.dart';
import '../../insights/domain/mood_focus_insights.dart';
import '../../insights/presentation/mood_focus_details_screen.dart';
import '../../mood_checkin/data/checkin_storage.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedTags = {};
  Set<String> _availableTags = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('session_history') ?? [];
    
    return historyJson.map((jsonString) {
      final parts = jsonString.split('|');
      
      // Handle backward compatibility: old format has 2 parts, new format has 4
      final tags = parts.length > 2 ? parts[2].split(',').where((tag) => tag.trim().isNotEmpty).toList() : <String>[];
      final note = parts.length > 3 ? parts[3] : '';
      
      return {
        'dateTime': DateTime.parse(parts[0]),
        'durationMinutes': int.parse(parts[1]),
        'tags': tags,
        'note': note,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> _loadDataAndStatistics() async {
    final sessions = await _loadSessionHistory();
    final statistics = await FocusSessionStatisticsStorage.loadStatistics();
    final insights = FocusSessionInsightsService.calculateInsights(sessions);
    
    final prefs = await SharedPreferences.getInstance();
    final weeklyGoalMinutes = prefs.getInt(AppSettings.keyWeeklyGoalMinutes) ?? AppSettings.defaultWeeklyGoalMinutes;
    final weeklyProgress = WeeklyProgressService.calculateWeeklyProgress(sessions, weeklyGoalMinutes);
    
    final checkinStorage = CheckinStorage();
    final checkins = await checkinStorage.getRecentCheckins();
    final moodFocusInsights = MoodFocusInsightsService.computeInsights(
      checkins: checkins,
      focusSessions: sessions,
    );
    
    _updateAvailableTags(sessions);
    
    return {
      'sessions': sessions,
      'statistics': statistics,
      'insights': insights,
      'weeklyProgress': weeklyProgress,
      'moodFocusInsights': moodFocusInsights,
    };
  }

  void _updateAvailableTags(List<Map<String, dynamic>> sessions) {
    final allTags = <String>{};
    for (final session in sessions) {
      final tags = session['tags'] as List<String>? ?? [];
      allTags.addAll(tags);
    }
    
    if (mounted) {
      setState(() {
        _availableTags = allTags;
        _selectedTags = _selectedTags.intersection(allTags);
      });
    }
  }

  List<Map<String, dynamic>> _filterSessions(List<Map<String, dynamic>> sessions) {
    return sessions.where((session) {
      final tags = session['tags'] as List<String>? ?? [];
      final note = session['note'] as String? ?? '';
      
      // Filter by selected tags (session must have all selected tags)
      if (_selectedTags.isNotEmpty) {
        if (!_selectedTags.every((tag) => tags.contains(tag))) {
          return false;
        }
      }
      
      // Filter by search query in note
      if (_searchQuery.isNotEmpty) {
        if (!note.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_csv':
        _exportCsv();
        break;
      case 'export_json':
        _exportJson();
        break;
      case 'import_json':
        _importJson();
        break;
      case 'clear':
        _clearHistory();
        break;
    }
  }

  Future<void> _exportCsv() async {
    try {
      final documentsPath = await _getDocumentsPath();
      final filename = 'focus_sessions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final path = '$documentsPath/$filename';
      
      final result = await FocusSessionIOService.exportCsv(path);
      
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exported to: $path')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${result.errorMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportJson() async {
    try {
      final documentsPath = await _getDocumentsPath();
      final filename = 'focus_sessions_${DateTime.now().millisecondsSinceEpoch}.json';
      final path = '$documentsPath/$filename';
      
      final result = await FocusSessionIOService.exportJson(path);
      
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON exported to: $path')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${result.errorMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importJson() async {
    try {
      final documentsPath = await _getDocumentsPath();
      final filename = 'focus_sessions_import.json';
      final path = '$documentsPath/$filename';
      
      final result = await FocusSessionIOService.importJson(path);
      
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import completed: ${result.data}')),
        );
        setState(() {});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${result.errorMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<String> _getDocumentsPath() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      return '$userProfile/Documents/MindTrainer';
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return '$home/Documents/MindTrainer';
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      return '$home/Documents/MindTrainer';
    } else {
      return '/tmp/MindTrainer';
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Clear all session history and statistics?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_history');
      await FocusSessionStatisticsStorage.clearStatistics();
      setState(() {});
    }
  }

  Widget _buildStatisticsCard(FocusSessionStatistics stats) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${stats.totalFocusTimeMinutes}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Total Minutes'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${stats.averageSessionLength.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Avg Length'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${stats.completedSessionsCount}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Sessions'),
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

  Widget _buildInsightsCard(FocusSessionInsights insights, MoodFocusInsightsResult moodFocusInsights) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('7d total: ${insights.rolling7DayTotalMinutes}m'),
                      Text('7d avg: ${insights.rolling7DayAvgMinutes.toStringAsFixed(1)}m/day'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('30d total: ${insights.rolling30DayTotalMinutes}m'),
                      Text('30d avg: ${insights.rolling30DayAvgMinutes.toStringAsFixed(1)}m/day'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Streak: ${insights.currentStreak} days'),
                      Text('Longest: ${_formatDuration(insights.longestSessionMinutes)}'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (insights.bestDay != null)
                        Text('Best day: ${_formatDate(insights.bestDay!)}')
                      else
                        const Text('Best day: -'),
                      if (insights.bestDay != null)
                        Text('(${insights.bestDayMinutes}m)')
                      else
                        const Text(''),
                    ],
                  ),
                ),
              ],
            ),
            if (moodFocusInsights.dailyPairs.isNotEmpty) ...[
              const Divider(height: 24),
              _buildMoodFocusSection(moodFocusInsights),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodFocusSection(MoodFocusInsightsResult insights) {
    final correlationText = insights.weeklyCorrelation != null
        ? 'r = ${insights.weeklyCorrelation!.toStringAsFixed(2)}'
        : '—';
    
    final topMoodsText = insights.topFocusMoods.isNotEmpty
        ? insights.topFocusMoods.join(', ')
        : 'No data yet';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MoodFocusDetailsScreen(insights: insights),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mood ↔ Focus (weekly): $correlationText',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text('Top focus moods: $topMoodsText'),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final duration = Duration(minutes: minutes);
    return formatDuration(duration);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildWeeklyProgressCard(WeeklyProgress progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This week: ${_formatDuration(progress.currentWeekTotal)} / ${_formatDuration(progress.goalMinutes)}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${(progress.percent * 100).toInt()}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.percent,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    if (_availableTags.isEmpty && _searchController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search notes',
                hintText: 'Search in session notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            if (_availableTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Filter by tags:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            if (_selectedTags.isNotEmpty || _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags.clear();
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  child: const Text('Clear filters'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionListTile(Map<String, dynamic> session) {
    final tags = session['tags'] as List<String>? ?? [];
    final note = session['note'] as String? ?? '';
    final hasMetadata = tags.isNotEmpty || note.isNotEmpty;

    return ListTile(
      title: Text(_formatDateTime(session['dateTime'])),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${session['durationMinutes']} minutes'),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: tags.map((tag) => Chip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      isThreeLine: hasMetadata,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_csv',
                child: Text('Export CSV'),
              ),
              const PopupMenuItem(
                value: 'export_json',
                child: Text('Export JSON'),
              ),
              const PopupMenuItem(
                value: 'import_json',
                child: Text('Import JSON...'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear History'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadDataAndStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final allSessions = data['sessions'] as List<Map<String, dynamic>>? ?? [];
            final filteredSessions = _filterSessions(allSessions);
            final statistics = data['statistics'] as FocusSessionStatistics? ?? FocusSessionStatistics.empty();
            final insights = data['insights'] as FocusSessionInsights? ?? FocusSessionInsights.empty();
            final weeklyProgress = data['weeklyProgress'] as WeeklyProgress? ?? WeeklyProgress.empty();
            final moodFocusInsights = data['moodFocusInsights'] as MoodFocusInsightsResult? ?? const MoodFocusInsightsResult(dailyPairs: [], weeklyCorrelation: null, topFocusMoods: []);
            
            if (allSessions.isEmpty) {
              return Column(
                children: [
                  _buildWeeklyProgressCard(weeklyProgress),
                  _buildInsightsCard(insights, moodFocusInsights),
                  _buildStatisticsCard(statistics),
                  const Expanded(
                    child: Center(
                      child: Text('No sessions yet'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildWeeklyProgressCard(weeklyProgress),
                _buildFilterSection(),
                _buildInsightsCard(insights, moodFocusInsights),
                _buildStatisticsCard(statistics),
                if (filteredSessions.isEmpty && (allSessions.isNotEmpty))
                  const Expanded(
                    child: Center(
                      child: Text('No sessions match the current filters'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        return _buildSessionListTile(session);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}