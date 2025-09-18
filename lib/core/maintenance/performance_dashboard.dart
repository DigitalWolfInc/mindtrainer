/// Performance Monitoring Dashboard for MindTrainer
/// 
/// Provides comprehensive performance monitoring, alerting, and optimization
/// recommendations for ongoing maintenance.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';
import '../performance/performance_profiler.dart';

/// Performance alert severity levels
enum PerformanceAlertLevel {
  info,     // FYI - minor performance variations
  warning,  // Attention needed - performance degrading
  critical, // Immediate action - performance severely impacted
}

/// Performance alert data
class PerformanceAlert {
  final String id;
  final DateTime timestamp;
  final PerformanceAlertLevel level;
  final String metric;
  final double threshold;
  final double actualValue;
  final String message;
  final Map<String, dynamic> context;
  
  PerformanceAlert({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.metric,
    required this.threshold,
    required this.actualValue,
    required this.message,
    this.context = const {},
  });
  
  /// Performance degradation percentage
  double get degradationPercent => ((actualValue - threshold) / threshold) * 100;
  
  /// Whether this alert requires immediate attention
  bool get requiresImmediateAction => level == PerformanceAlertLevel.critical;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'metric': metric,
    'threshold': threshold,
    'actualValue': actualValue,
    'message': message,
    'context': context,
  };
}

/// Performance trend analysis
class PerformanceTrend {
  final String metric;
  final List<double> values;
  final List<DateTime> timestamps;
  final Duration period;
  
  PerformanceTrend({
    required this.metric,
    required this.values,
    required this.timestamps,
    required this.period,
  });
  
  /// Calculate trend direction: positive = improving, negative = degrading
  double get trendDirection {
    if (values.length < 2) return 0.0;
    
    // Simple linear regression slope
    final n = values.length;
    final meanX = (n - 1) / 2.0;
    final meanY = values.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = values[i];
      numerator += (x - meanX) * (y - meanY);
      denominator += (x - meanX) * (x - meanX);
    }
    
    return denominator == 0 ? 0.0 : numerator / denominator;
  }
  
  /// Trend status description
  String get trendStatus {
    final direction = trendDirection;
    if (direction.abs() < 0.1) return 'Stable';
    if (direction > 0.5) return 'Improving';
    if (direction > 0) return 'Slightly Improving';
    if (direction < -0.5) return 'Degrading';
    return 'Slightly Degrading';
  }
  
  /// Latest value in the trend
  double get latestValue => values.isNotEmpty ? values.last : 0.0;
  
  /// Average value over the trend period
  double get averageValue => values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
}

/// Performance recommendations
class PerformanceRecommendation {
  final String id;
  final String title;
  final String description;
  final List<String> actionItems;
  final int priorityScore; // 1-100
  final String category;
  final Map<String, dynamic> metadata;
  
  PerformanceRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.actionItems,
    required this.priorityScore,
    required this.category,
    this.metadata = const {},
  });
  
  /// Priority level based on score
  String get priorityLevel {
    if (priorityScore >= 80) return 'High';
    if (priorityScore >= 60) return 'Medium';
    return 'Low';
  }
}

/// Comprehensive performance dashboard
class PerformanceDashboard {
  final LocalStorage _storage;
  final PerformanceProfiler _profiler;
  
  static const String _alertsKey = 'performance_alerts';
  static const String _trendsKey = 'performance_trends';
  static const String _benchmarksKey = 'performance_benchmarks';
  static const String _settingsKey = 'performance_settings';
  
  final StreamController<PerformanceAlert> _alertController =
      StreamController<PerformanceAlert>.broadcast();
  
  // Performance thresholds
  static const Map<String, double> _defaultThresholds = {
    'app_startup_ms': 2000.0,
    'screen_render_ms': 100.0,
    'navigation_ms': 300.0,
    'db_query_ms': 50.0,
    'memory_usage_mb': 200.0,
    'frame_drop_percent': 5.0,
    'crash_rate_per_1000': 1.0,
    'pro_feature_response_ms': 100.0,
  };
  
  Map<String, double> _thresholds = Map.from(_defaultThresholds);
  bool _monitoringEnabled = true;
  
  PerformanceDashboard(this._storage, this._profiler);
  
  /// Stream of performance alerts
  Stream<PerformanceAlert> get alertStream => _alertController.stream;
  
  /// Initialize the dashboard
  Future<void> initialize() async {
    await _loadSettings();
    await _startPerformanceMonitoring();
    
    if (kDebugMode) {
      print('Performance dashboard initialized');
    }
  }
  
  /// Get current performance overview
  Future<Map<String, dynamic>> getPerformanceOverview() async {
    final summary = await _profiler.getPerformanceSummary(
      period: const Duration(hours: 24),
    );
    
    final alerts = await getActiveAlerts();
    final trends = await _getPerformanceTrends(days: 7);
    final recommendations = await _generateRecommendations();
    
    // Calculate overall performance score
    final performanceScore = _calculateOverallScore(summary);
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'performance_score': performanceScore,
      'status': _getPerformanceStatus(performanceScore),
      'active_alerts': alerts.length,
      'critical_alerts': alerts.where((a) => a.level == PerformanceAlertLevel.critical).length,
      'trending_metrics': trends.map((t) => {
        'metric': t.metric,
        'status': t.trendStatus,
        'latest_value': t.latestValue,
      }).toList(),
      'top_recommendations': recommendations.take(3).map((r) => {
        'title': r.title,
        'priority': r.priorityLevel,
        'category': r.category,
      }).toList(),
      'key_metrics': summary,
    };
  }
  
  /// Get active performance alerts
  Future<List<PerformanceAlert>> getActiveAlerts({
    PerformanceAlertLevel? filterLevel,
    int? limitHours,
  }) async {
    final alertsJson = await _storage.getString(_alertsKey);
    if (alertsJson == null) return [];
    
    try {
      final List<dynamic> alertsList = jsonDecode(alertsJson);
      List<PerformanceAlert> alerts = alertsList
          .map((json) => _alertFromJson(json))
          .toList();
      
      // Apply filters
      if (filterLevel != null) {
        alerts = alerts.where((a) => a.level == filterLevel).toList();
      }
      
      if (limitHours != null) {
        final cutoff = DateTime.now().subtract(Duration(hours: limitHours));
        alerts = alerts.where((a) => a.timestamp.isAfter(cutoff)).toList();
      }
      
      // Sort by severity, then timestamp
      alerts.sort((a, b) {
        final severityCompare = b.level.index.compareTo(a.level.index);
        if (severityCompare != 0) return severityCompare;
        return b.timestamp.compareTo(a.timestamp);
      });
      
      return alerts;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading performance alerts: $e');
      }
      return [];
    }
  }
  
  /// Check performance metrics and generate alerts
  Future<void> checkPerformanceMetrics() async {
    if (!_monitoringEnabled) return;
    
    final summary = await _profiler.getPerformanceSummary(
      period: const Duration(hours: 1),
    );
    
    if (summary['error'] != null) return;
    
    final summaryData = summary['summary'] as Map<String, dynamic>? ?? {};
    
    // Check each metric against thresholds
    for (final entry in summaryData.entries) {
      final metricType = entry.key;
      final metricData = entry.value as Map<String, dynamic>;
      final avgValue = metricData['avg_ms'] as double? ?? 0.0;
      
      final threshold = _thresholds[metricType];
      if (threshold != null && avgValue > threshold) {
        await _createPerformanceAlert(
          metric: metricType,
          actualValue: avgValue,
          threshold: threshold,
          context: metricData,
        );
      }
    }
    
    // Check system-wide metrics
    await _checkSystemMetrics();
  }
  
  /// Generate performance optimization recommendations
  Future<List<PerformanceRecommendation>> _generateRecommendations() async {
    final recommendations = <PerformanceRecommendation>[];
    final summary = await _profiler.getPerformanceSummary();
    
    if (summary['error'] != null) return recommendations;
    
    final summaryData = summary['summary'] as Map<String, dynamic>? ?? {};
    final slowOperations = await _profiler.getSlowOperations(limit: 10);
    
    // Startup optimization recommendation
    final startupData = summaryData['appStartup'] as Map<String, dynamic>?;
    if (startupData != null && (startupData['avg_ms'] as double? ?? 0) > 1500) {
      recommendations.add(PerformanceRecommendation(
        id: 'startup_optimization',
        title: 'Optimize App Startup Time',
        description: 'App startup time is slower than optimal. Consider lazy loading non-critical components.',
        actionItems: [
          'Profile app initialization sequence',
          'Defer non-essential service initialization',
          'Optimize asset loading during startup',
          'Consider splash screen optimizations',
        ],
        priorityScore: 85,
        category: 'Startup',
        metadata: startupData,
      ));
    }
    
    // Memory optimization recommendation
    if (slowOperations.any((op) => op.name.contains('memory'))) {
      recommendations.add(PerformanceRecommendation(
        id: 'memory_optimization',
        title: 'Optimize Memory Usage',
        description: 'Memory-related operations are taking longer than expected.',
        actionItems: [
          'Review object lifecycle management',
          'Check for memory leaks in controllers',
          'Optimize image and asset caching',
          'Profile memory usage patterns',
        ],
        priorityScore: 75,
        category: 'Memory',
      ));
    }
    
    // UI responsiveness recommendation
    final renderData = summaryData['screenRender'] as Map<String, dynamic>?;
    if (renderData != null && (renderData['avg_ms'] as double? ?? 0) > 80) {
      recommendations.add(PerformanceRecommendation(
        id: 'ui_optimization',
        title: 'Improve UI Responsiveness',
        description: 'Screen rendering is taking longer than optimal for smooth 60fps experience.',
        actionItems: [
          'Profile widget build times',
          'Optimize complex widget trees',
          'Consider using const constructors',
          'Review expensive computations in build methods',
        ],
        priorityScore: 70,
        category: 'UI',
        metadata: renderData,
      ));
    }
    
    // Database optimization recommendation
    final dbData = summaryData['databaseQuery'] as Map<String, dynamic>?;
    if (dbData != null && (dbData['avg_ms'] as double? ?? 0) > 30) {
      recommendations.add(PerformanceRecommendation(
        id: 'database_optimization',
        title: 'Optimize Database Operations',
        description: 'Database queries are slower than optimal. Consider query optimization.',
        actionItems: [
          'Review slow database queries',
          'Add appropriate database indexes',
          'Consider query batching for bulk operations',
          'Profile database connection management',
        ],
        priorityScore: 65,
        category: 'Database',
        metadata: dbData,
      ));
    }
    
    // Pro feature performance recommendation
    final proGateData = summaryData['proGateCheck'] as Map<String, dynamic>?;
    if (proGateData != null && (proGateData['avg_ms'] as double? ?? 0) > 0.5) {
      recommendations.add(PerformanceRecommendation(
        id: 'pro_gate_optimization',
        title: 'Optimize Pro Feature Gates',
        description: 'Pro feature checks are taking longer than expected.',
        actionItems: [
          'Cache Pro status to avoid repeated checks',
          'Optimize Pro gate validation logic',
          'Consider async Pro status updates',
          'Profile Pro feature access patterns',
        ],
        priorityScore: 60,
        category: 'Pro Features',
        metadata: proGateData,
      ));
    }
    
    // Sort by priority score
    recommendations.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    
    return recommendations;
  }
  
  /// Update performance monitoring settings
  Future<void> updateSettings({
    Map<String, double>? newThresholds,
    bool? enableMonitoring,
  }) async {
    if (newThresholds != null) {
      _thresholds.addAll(newThresholds);
    }
    
    if (enableMonitoring != null) {
      _monitoringEnabled = enableMonitoring;
    }
    
    await _saveSettings();
  }
  
  /// Get performance trends for specified metrics
  Future<List<PerformanceTrend>> getPerformanceTrends({
    List<String>? metrics,
    int days = 30,
  }) async {
    return await _getPerformanceTrends(days: days, filterMetrics: metrics);
  }
  
  /// Generate performance report for maintenance review
  Future<Map<String, dynamic>> generateMaintenanceReport() async {
    final overview = await getPerformanceOverview();
    final alerts = await getActiveAlerts(limitHours: 168); // Last week
    final recommendations = await _generateRecommendations();
    final trends = await _getPerformanceTrends(days: 30);
    
    final criticalIssues = alerts
        .where((a) => a.level == PerformanceAlertLevel.critical)
        .length;
    
    final degradingTrends = trends
        .where((t) => t.trendDirection < -0.3)
        .map((t) => t.metric)
        .toList();
    
    return {
      'report_generated': DateTime.now().toIso8601String(),
      'performance_score': overview['performance_score'],
      'overall_status': overview['status'],
      'critical_issues': criticalIssues,
      'total_alerts_week': alerts.length,
      'degrading_metrics': degradingTrends,
      'top_recommendations': recommendations.take(5).map((r) => {
        'title': r.title,
        'priority': r.priorityLevel,
        'category': r.category,
        'action_items_count': r.actionItems.length,
      }).toList(),
      'performance_trends': trends.map((t) => {
        'metric': t.metric,
        'trend': t.trendStatus,
        'direction': t.trendDirection,
        'latest_value': t.latestValue,
        'average_value': t.averageValue,
      }).toList(),
      'maintenance_priority': _getMaintenancePriority(criticalIssues, degradingTrends.length),
    };
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _alertController.close();
  }
  
  // Private helper methods
  
  Future<void> _loadSettings() async {
    final settingsJson = await _storage.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        
        final thresholds = settings['thresholds'] as Map<String, dynamic>?;
        if (thresholds != null) {
          _thresholds = thresholds.map((k, v) => MapEntry(k, v as double));
        }
        
        _monitoringEnabled = settings['monitoring_enabled'] ?? true;
      } catch (e) {
        if (kDebugMode) {
          print('Error loading performance settings: $e');
        }
      }
    }
  }
  
  Future<void> _saveSettings() async {
    final settings = {
      'thresholds': _thresholds,
      'monitoring_enabled': _monitoringEnabled,
    };
    
    await _storage.setString(_settingsKey, jsonEncode(settings));
  }
  
  Future<void> _startPerformanceMonitoring() async {
    // Start periodic performance checks
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_monitoringEnabled) {
        await checkPerformanceMetrics();
      }
    });
  }
  
  Future<void> _createPerformanceAlert({
    required String metric,
    required double actualValue,
    required double threshold,
    Map<String, dynamic>? context,
  }) async {
    final severity = _calculateAlertSeverity(actualValue, threshold);
    final degradation = ((actualValue - threshold) / threshold) * 100;
    
    final alert = PerformanceAlert(
      id: _generateAlertId(),
      timestamp: DateTime.now(),
      level: severity,
      metric: metric,
      threshold: threshold,
      actualValue: actualValue,
      message: 'Performance degraded by ${degradation.toStringAsFixed(1)}% for $metric',
      context: context ?? {},
    );
    
    await _saveAlert(alert);
    
    if (!_alertController.isClosed) {
      _alertController.add(alert);
    }
    
    if (kDebugMode) {
      print('Performance alert: ${alert.message}');
    }
  }
  
  PerformanceAlertLevel _calculateAlertSeverity(double actualValue, double threshold) {
    final degradationPercent = ((actualValue - threshold) / threshold) * 100;
    
    if (degradationPercent >= 100) return PerformanceAlertLevel.critical;
    if (degradationPercent >= 50) return PerformanceAlertLevel.warning;
    return PerformanceAlertLevel.info;
  }
  
  int _calculateOverallScore(Map<String, dynamic> summary) {
    if (summary['error'] != null) return 50;
    
    final summaryData = summary['summary'] as Map<String, dynamic>? ?? {};
    if (summaryData.isEmpty) return 100;
    
    int score = 100;
    int metricCount = 0;
    
    for (final entry in summaryData.entries) {
      final metricType = entry.key;
      final metricData = entry.value as Map<String, dynamic>;
      final thresholdPercent = metricData['within_threshold_percent'] as double? ?? 100.0;
      
      // Deduct points based on how far below threshold percentage we are
      final deduction = ((100 - thresholdPercent) / 10).round();
      score -= deduction;
      metricCount++;
    }
    
    return score.clamp(0, 100);
  }
  
  String _getPerformanceStatus(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Poor';
    return 'Critical';
  }
  
  Future<void> _checkSystemMetrics() async {
    // Check frame timing
    // Check memory usage
    // Check crash rates
    // This would integrate with system-level monitoring
  }
  
  Future<List<PerformanceTrend>> _getPerformanceTrends({
    int days = 30,
    List<String>? filterMetrics,
  }) async {
    // For now, return mock trends
    // In real implementation, this would analyze historical data
    
    final metrics = filterMetrics ?? ['app_startup', 'screen_render', 'db_query'];
    final trends = <PerformanceTrend>[];
    
    for (final metric in metrics) {
      // Generate mock trend data
      final values = List.generate(days, (i) {
        final base = _thresholds[metric] ?? 100.0;
        final noise = (Random().nextDouble() - 0.5) * base * 0.2;
        return base + noise;
      });
      
      final timestamps = List.generate(days, (i) {
        return DateTime.now().subtract(Duration(days: days - i));
      });
      
      trends.add(PerformanceTrend(
        metric: metric,
        values: values,
        timestamps: timestamps,
        period: Duration(days: days),
      ));
    }
    
    return trends;
  }
  
  String _getMaintenancePriority(int criticalIssues, int degradingMetrics) {
    if (criticalIssues > 0) return 'Immediate';
    if (degradingMetrics > 3) return 'High';
    if (degradingMetrics > 1) return 'Medium';
    return 'Low';
  }
  
  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  PerformanceAlert _alertFromJson(Map<String, dynamic> json) {
    return PerformanceAlert(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      level: PerformanceAlertLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => PerformanceAlertLevel.info,
      ),
      metric: json['metric'],
      threshold: json['threshold'],
      actualValue: json['actualValue'],
      message: json['message'],
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
  
  Future<void> _saveAlert(PerformanceAlert alert) async {
    final alerts = await getActiveAlerts();
    alerts.insert(0, alert); // Add to front
    
    // Keep only last 200 alerts
    if (alerts.length > 200) {
      alerts.removeRange(200, alerts.length);
    }
    
    final alertsJson = jsonEncode(
      alerts.map((a) => a.toJson()).toList()
    );
    await _storage.setString(_alertsKey, alertsJson);
  }
}