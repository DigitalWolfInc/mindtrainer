/// Pattern Insights Screen for MindTrainer Pro
/// 
/// Displays personalized mindfulness patterns and recommendations.

import 'package:flutter/material.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../domain/pattern_analysis.dart';
import '../application/pattern_analyzer_service.dart';

class PatternInsightsScreen extends StatefulWidget {
  final MindTrainerProGates proGates;
  final PatternAnalyzerService patternService;
  
  const PatternInsightsScreen({
    super.key,
    required this.proGates,
    required this.patternService,
  });
  
  @override
  State<PatternInsightsScreen> createState() => _PatternInsightsScreenState();
}

class _PatternInsightsScreenState extends State<PatternInsightsScreen> {
  Map<String, dynamic>? _analysisSummary;
  List<String> _currentSuggestions = [];
  bool _loading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadPatternData();
  }
  
  Future<void> _loadPatternData() async {
    if (!widget.proGates.isProActive) {
      setState(() {
        _error = 'Pro subscription required';
        _loading = false;
      });
      return;
    }
    
    try {
      final summary = await widget.patternService.getAnalysisSummary();
      final suggestions = await widget.patternService.getPersonalizedSuggestions();
      
      if (mounted) {
        setState(() {
          _analysisSummary = summary;
          _currentSuggestions = suggestions;
          _loading = false;
          _error = summary['error'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load pattern data: $e';
          _loading = false;
        });
      }
    }
  }
  
  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadPatternData();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindfulness Patterns'),
        actions: [
          if (!_loading)
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }
  
  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing your mindfulness patterns...'),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return _buildErrorState(context);
    }
    
    if (_analysisSummary == null) {
      return _buildNoDataState(context);
    }
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataConfidenceCard(),
            const SizedBox(height: 16),
            _buildCurrentSuggestions(),
            const SizedBox(height: 16),
            _buildBestTimeInsight(),
            const SizedBox(height: 16),
            _buildKeyInsights(),
            const SizedBox(height: 16),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _error!.contains('Pro subscription') ? Icons.star : Icons.error,
              size: 64,
              color: _error!.contains('Pro subscription') ? Colors.amber : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            if (!widget.proGates.isProActive) ...[
              ElevatedButton(
                onPressed: () {
                  // Navigate to Pro upgrade
                },
                child: const Text('Upgrade to Pro'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoDataState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Not enough data yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete at least 5 sessions to see your mindfulness patterns.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Start a Session'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataConfidenceCard() {
    final confidence = (_analysisSummary!['data_confidence'] as double) * 100;
    final sessionsAnalyzed = _analysisSummary!['sessions_analyzed'] as int;
    final daysCovered = _analysisSummary!['days_covered'] as int;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  confidence >= 80 ? Icons.analytics : Icons.query_stats,
                  color: confidence >= 80 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pattern Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Sessions',
                    sessionsAnalyzed.toString(),
                    Icons.self_improvement,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Days',
                    daysCovered.toString(),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Confidence',
                    '${confidence.toInt()}%',
                    Icons.verified,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence >= 80 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCurrentSuggestions() {
    if (_currentSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Right Now',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_currentSuggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBestTimeInsight() {
    final bestTime = _analysisSummary!['best_time'] as String?;
    final bestTimeRange = _analysisSummary!['best_time_range'] as String?;
    final bestTimeRating = _analysisSummary!['best_time_rating'] as double?;
    
    if (bestTime == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Peak Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bestTime,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (bestTimeRange != null)
                        Text(
                          bestTimeRange,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            bestTimeRating?.toStringAsFixed(1) ?? 'N/A',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Avg Rating',
                        style: TextStyle(fontSize: 12),
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
  
  Widget _buildKeyInsights() {
    final insights = _analysisSummary!['key_insights'] as List<dynamic>? ?? [];
    
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights,
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                Text(
                  'Key Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      insight as String,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendations() {
    final recommendations = _analysisSummary!['top_recommendations'] as List<dynamic>? ?? [];
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.recommend,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => _buildRecommendationCard(rec)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final title = recommendation['title'] as String;
    final description = recommendation['description'] as String;
    final confidence = recommendation['confidence'] as String;
    final actions = recommendation['actions'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  confidence,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(height: 1.4),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      action as String,
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}