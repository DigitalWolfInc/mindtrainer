import 'package:flutter/material.dart';
import '../domain/analytics_service.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/billing/billing_adapter.dart';
import '../../../core/analytics/conversion_analytics.dart';
import '../../../payments/pro_gate.dart';

class AnalyticsScreen extends StatefulWidget {
  final AdvancedAnalyticsService analyticsService;
  final MindTrainerProGates proGates;
  final BillingAdapter? billingAdapter;

  const AnalyticsScreen({
    super.key,
    required this.analyticsService,
    required this.proGates,
    this.billingAdapter,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late SessionAnalytics _basicAnalytics;
  late List<MoodFocusCorrelation> _moodCorrelations;
  late List<TagPerformanceInsight> _tagInsights;
  late List<KeywordUpliftAnalysis> _keywordAnalysis;
  bool _isLoading = true;
  
  final ConversionAnalytics _analytics = ConversionAnalytics();

  @override
  void initState() {
    super.initState();
    
    // Track analytics screen view
    _analytics.trackScreenNavigation('home_screen', 'analytics_screen', {
      'has_pro': widget.proGates.isProActive,
      'entry_method': 'analytics_button',
    });
    
    if (!widget.proGates.isProActive) {
      // Track conversion funnel entry for free users
      _analytics.trackFunnelEntry(ConversionEntryPoints.analyticsLockedFeature, {
        'screen': 'analytics',
        'user_type': 'free',
      });
    } else {
      // Track Pro feature usage
      _analytics.trackProFeatureUsage('advanced_analytics', 'screen_view', {
        'has_active_subscription': true,
      });
    }
    
    _loadAnalytics();
  }

  void _loadAnalytics() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _basicAnalytics = widget.analyticsService.getBasicAnalytics();
        _moodCorrelations = widget.analyticsService.getMoodFocusCorrelations();
        _tagInsights = widget.analyticsService.getTagPerformanceInsights();
        _keywordAnalysis = widget.analyticsService.getKeywordUpliftAnalysis();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          if (!widget.proGates.isProActive)
            IconButton(
              onPressed: () {
                _analytics.trackUpgradePromptInteraction('analytics_app_bar', 'star_tapped', {
                  'prompt_type': 'icon_button',
                });
                context.maybePromptPaywall();
              },
              icon: const Icon(Icons.star, color: Colors.amber),
              tooltip: 'Upgrade to Pro',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicAnalyticsCard(),
                  const SizedBox(height: 16),
                  _buildMoodFocusSection(),
                  const SizedBox(height: 16),
                  _buildTagPerformanceSection(),
                  const SizedBox(height: 16),
                  _buildKeywordAnalysisSection(),
                  const SizedBox(height: 16),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicAnalyticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Your Focus Journey',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Sessions',
                    '${_basicAnalytics.totalSessions}',
                    Icons.play_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Avg Focus',
                    '${_basicAnalytics.averageFocusScore.toStringAsFixed(1)}/10',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Total Time',
                    '${_basicAnalytics.totalFocusTime.inHours}h ${_basicAnalytics.totalFocusTime.inMinutes % 60}m',
                    Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_basicAnalytics.topTags.isNotEmpty) ...[
              Text(
                'Top Tags',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _basicAnalytics.topTags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodFocusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mood, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Mood-Focus Correlations',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                if (!widget.proGates.isProActive) _buildProBadge(),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.proGates.isProActive && _moodCorrelations.isNotEmpty) ...[
              ..._moodCorrelations.take(3).map((correlation) =>
                _buildMoodCorrelationTile(correlation)),
              if (_moodCorrelations.length > 3)
                TextButton(
                  onPressed: () => _showDetailDialog('Mood Correlations', 
                    _moodCorrelations.map((c) => 
                      '${c.mood}: ${c.averageFocusScore.toStringAsFixed(1)}/10 (${c.sessionCount} sessions, ${c.trend})'
                    ).toList()),
                  child: const Text('View All'),
                ),
            ] else ...[
              _buildLockedPreview(
                'Discover how your mood affects focus performance',
                'See which emotional states lead to your best sessions',
                Icons.mood,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Tag Performance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                if (!widget.proGates.isProActive) _buildProBadge(),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.proGates.isProActive && _tagInsights.isNotEmpty) ...[
              ..._tagInsights.take(3).map((insight) =>
                _buildTagInsightTile(insight)),
              if (_tagInsights.length > 3)
                TextButton(
                  onPressed: () => _showDetailDialog('Tag Performance',
                    _tagInsights.map((t) => 
                      '${t.tag}: ${t.averageFocusScore.toStringAsFixed(1)}/10 (${t.uplift >= 0 ? '+' : ''}${t.uplift.toStringAsFixed(1)} uplift)'
                    ).toList()),
                  child: const Text('View All'),
                ),
            ] else ...[
              _buildLockedPreview(
                'Analyze which tags boost your performance',
                'Optimize your sessions with data-driven tag selection',
                Icons.tag,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordAnalysisSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Keyword Uplift',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                if (!widget.proGates.isProActive) _buildProBadge(),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.proGates.isProActive && _keywordAnalysis.isNotEmpty) ...[
              ..._keywordAnalysis.take(3).map((analysis) =>
                _buildKeywordAnalysisTile(analysis)),
            ] else ...[
              _buildLockedPreview(
                'Discover power words that enhance focus',
                'Find keywords that correlate with better session outcomes',
                Icons.psychology,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final historyDays = widget.analyticsService.historyWindowDays;
    final hasExtended = widget.analyticsService.hasExtendedHistory;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'History Window',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                if (!hasExtended) _buildProBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              hasExtended 
                ? 'Access to unlimited historical data'
                : 'Currently showing last $historyDays days',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (!hasExtended) ...[
              const SizedBox(height: 8),
              Text(
                'Upgrade to Pro for complete session history and deeper insights',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCorrelationTile(MoodFocusCorrelation correlation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTrendColor(correlation.trend),
        child: Text(
          correlation.mood[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(correlation.mood),
      subtitle: Text('${correlation.sessionCount} sessions'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${correlation.averageFocusScore.toStringAsFixed(1)}/10',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            correlation.trend,
            style: TextStyle(
              color: _getTrendColor(correlation.trend),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagInsightTile(TagPerformanceInsight insight) {
    return ListTile(
      leading: Chip(
        label: Text(insight.tag),
        backgroundColor: insight.uplift >= 0 ? Colors.green[100] : Colors.red[100],
      ),
      title: Text('${insight.averageFocusScore.toStringAsFixed(1)}/10 avg'),
      subtitle: Text('${insight.usageCount} uses'),
      trailing: Text(
        '${insight.uplift >= 0 ? '+' : ''}${insight.uplift.toStringAsFixed(1)}',
        style: TextStyle(
          color: insight.uplift >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKeywordAnalysisTile(KeywordUpliftAnalysis analysis) {
    return ListTile(
      leading: const Icon(Icons.trending_up, color: Colors.green),
      title: Text(analysis.keyword),
      subtitle: Text('${analysis.sessionCount} sessions • ${analysis.context}'),
      trailing: Text(
        '+${analysis.upliftPercentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLockedPreview(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _analytics.trackUpgradePromptInteraction('locked_feature', 'unlock_tapped', {
                'feature_type': 'analytics_preview',
              });
              context.maybePromptPaywall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      case 'stable':
      default:
        return Colors.blue;
    }
  }

  void _showDetailDialog(String title, List<String> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: details.map((detail) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(detail),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    // Track upgrade dialog shown
    _analytics.trackUpgradePromptShown('analytics_screen', 'upgrade_dialog', {
      'trigger_source': 'analytics_feature_lock',
    });
    
    _analytics.trackFunnelStep(ConversionFunnelSteps.upgradeDialogView, 
        ConversionFunnelSteps.upgradePromptView, {
      'feature_context': 'analytics',
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade to Pro'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unlock advanced analytics features:'),
            SizedBox(height: 16),
            Text('• Mood-focus correlations'),
            Text('• Tag performance insights'),
            Text('• Keyword uplift analysis'),
            Text('• Unlimited historical data'),
            SizedBox(height: 16),
            Text('Get deeper insights to optimize your focus journey.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _analytics.trackFunnelDropOff(ConversionFunnelSteps.upgradeDialogView, 
                  DropOffReasons.userDismissed, {
                'action': 'not_now_tapped',
                'feature_context': 'analytics',
              });
              Navigator.pop(context);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              _analytics.trackFunnelStep(ConversionFunnelSteps.billingFlowStart, 
                  ConversionFunnelSteps.upgradeDialogView, {
                'user_action': 'upgrade_tapped',
                'feature_context': 'analytics',
              });
              Navigator.pop(context);
              _handleUpgrade();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _handleUpgrade() {
    if (widget.billingAdapter != null) {
      // Track billing attempt
      _analytics.trackBillingEvent('billing_flow_attempted', 'started', {
        'source': 'analytics_screen',
        'product_context': 'pro_analytics_features',
      });
      
      // TODO: Launch billing flow - currently shows placeholder
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upgrade flow will be implemented in Stage 2'),
        ),
      );
      
      // Track placeholder shown
      _analytics.trackBillingEvent('billing_flow_placeholder', 'shown', {
        'reason': 'stage_2_implementation_pending',
      });
    } else {
      // Track billing adapter unavailable
      _analytics.trackFunnelDropOff(ConversionFunnelSteps.billingFlowStart, 
          DropOffReasons.billingError, {
        'error': 'billing_adapter_null',
      });
    }
  }
}