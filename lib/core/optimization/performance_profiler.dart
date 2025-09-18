/// Performance Profiler for MindTrainer
/// 
/// Monitors app performance, tracks slow operations, and
/// ensures optimal startup times and UI responsiveness.

import 'dart:async';
import 'dart:io';
import '../storage/local_storage.dart';

/// Performance metric types
enum PerformanceMetric {
  appStartup,
  screenTransition,
  widgetBuild,
  dataQuery,
  storageOperation,
  networkRequest,
  heavyComputation,
  memoryUsage,
}

/// Performance threshold levels
enum PerformanceLevel {
  excellent, // < threshold
  good,      // threshold to threshold * 1.5
  poor,      // threshold * 1.5 to threshold * 2
  critical,  // > threshold * 2
}

/// Performance measurement
class PerformanceMeasurement {
  final PerformanceMetric metric;
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final PerformanceLevel level;
  
  const PerformanceMeasurement({
    required this.metric,
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.metadata = const {},
    required this.level,
  });
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'metric': metric.toString(),
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'level': level.toString(),
    };
  }
  
  /// Create from JSON
  factory PerformanceMeasurement.fromJson(Map<String, dynamic> json) {
    return PerformanceMeasurement(
      metric: PerformanceMetric.values.firstWhere(
        (m) => m.toString() == json['metric'],
        orElse: () => PerformanceMetric.widgetBuild,
      ),
      operation: json['operation'] ?? '',
      duration: Duration(milliseconds: json['duration_ms'] ?? 0),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
      level: PerformanceLevel.values.firstWhere(
        (l) => l.toString() == json['level'],
        orElse: () => PerformanceLevel.excellent,
      ),
    );
  }
}

/// Performance thresholds for different operations
class PerformanceThresholds {
  static const Map<PerformanceMetric, Duration> _thresholds = {
    PerformanceMetric.appStartup: Duration(seconds: 3),
    PerformanceMetric.screenTransition: Duration(milliseconds: 300),
    PerformanceMetric.widgetBuild: Duration(milliseconds: 16), // 60 FPS
    PerformanceMetric.dataQuery: Duration(milliseconds: 100),
    PerformanceMetric.storageOperation: Duration(milliseconds: 50),
    PerformanceMetric.networkRequest: Duration(seconds: 5),
    PerformanceMetric.heavyComputation: Duration(milliseconds: 500),
    PerformanceMetric.memoryUsage: Duration(milliseconds: 1), // Not time-based
  };
  
  /// Get threshold for metric
  static Duration getThreshold(PerformanceMetric metric) {
    return _thresholds[metric] ?? const Duration(milliseconds: 100);
  }
  
  /// Determine performance level based on duration
  static PerformanceLevel getLevel(PerformanceMetric metric, Duration duration) {
    final threshold = getThreshold(metric);
    
    if (duration <= threshold) {
      return PerformanceLevel.excellent;
    } else if (duration <= threshold * 1.5) {
      return PerformanceLevel.good;
    } else if (duration <= threshold * 2) {
      return PerformanceLevel.poor;
    } else {
      return PerformanceLevel.critical;
    }
  }
}

/// Performance profiler system
class PerformanceProfiler {
  static const String _measurementsKey = 'performance_measurements';
  static const String _sessionStatsKey = 'session_performance_stats';
  static const int _maxStoredMeasurements = 500;
  
  final LocalStorage _storage;
  final Map<String, Stopwatch> _activeTimers = {};
  final List<PerformanceMeasurement> _sessionMeasurements = [];
  
  PerformanceProfiler(this._storage);
  
  /// Initialize performance profiler
  Future<void> initialize() async {
    // Clean up old measurements
    await _cleanupOldMeasurements();
  }
  
  /// Start measuring performance
  void startMeasurement(PerformanceMetric metric, String operation) {
    final key = '${metric}_$operation';
    final stopwatch = Stopwatch()..start();
    _activeTimers[key] = stopwatch;
  }
  
  /// End measurement and record result
  Future<PerformanceMeasurement?> endMeasurement(
    PerformanceMetric metric, 
    String operation, {
    Map<String, dynamic> metadata = const {},
  }) async {
    final key = '${metric}_$operation';
    final stopwatch = _activeTimers.remove(key);
    
    if (stopwatch == null) return null;
    
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    final level = PerformanceThresholds.getLevel(metric, duration);
    
    final measurement = PerformanceMeasurement(
      metric: metric,
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
      level: level,
    );
    
    _sessionMeasurements.add(measurement);
    await _persistMeasurement(measurement);
    
    // Log slow operations
    if (level == PerformanceLevel.poor || level == PerformanceLevel.critical) {
      _logSlowOperation(measurement);
    }
    
    return measurement;
  }
  
  /// Measure operation with automatic timing
  Future<T> measureOperation<T>(
    PerformanceMetric metric,
    String operation,
    Future<T> Function() task, {
    Map<String, dynamic> metadata = const {},
  }) async {
    startMeasurement(metric, operation);
    
    try {
      final result = await task();
      await endMeasurement(metric, operation, metadata: metadata);
      return result;
    } catch (e) {
      await endMeasurement(metric, operation, metadata: {
        ...metadata,
        'error': e.toString(),
      });
      rethrow;
    }
  }
  
  /// Measure synchronous operation
  T measureSync<T>(
    PerformanceMetric metric,
    String operation,
    T Function() task, {
    Map<String, dynamic> metadata = const {},
  }) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = task();
      stopwatch.stop();
      
      final level = PerformanceThresholds.getLevel(metric, stopwatch.elapsed);
      final measurement = PerformanceMeasurement(
        metric: metric,
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: metadata,
        level: level,
      );
      
      _sessionMeasurements.add(measurement);
      _persistMeasurement(measurement);
      
      if (level == PerformanceLevel.poor || level == PerformanceLevel.critical) {
        _logSlowOperation(measurement);
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      final measurement = PerformanceMeasurement(
        metric: metric,
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: DateTime.now(),
        metadata: {
          ...metadata,
          'error': e.toString(),
        },
        level: PerformanceThresholds.getLevel(metric, stopwatch.elapsed),
      );
      
      _sessionMeasurements.add(measurement);
      _persistMeasurement(measurement);
      
      rethrow;
    }
  }
  
  /// Get performance summary for period
  Future<Map<String, dynamic>> getPerformanceSummary({
    Duration? period,
  }) async {
    final measurements = await _getRecentMeasurements(
      period ?? const Duration(days: 7),
    );
    
    final metricStats = <PerformanceMetric, Map<String, dynamic>>{};
    
    for (final metric in PerformanceMetric.values) {
      final metricMeasurements = measurements
          .where((m) => m.metric == metric)
          .toList();
      
      if (metricMeasurements.isEmpty) continue;
      
      final durations = metricMeasurements
          .map((m) => m.duration.inMilliseconds)
          .toList()
        ..sort();
      
      final levelCounts = <PerformanceLevel, int>{};
      for (final measurement in metricMeasurements) {
        levelCounts[measurement.level] = 
            (levelCounts[measurement.level] ?? 0) + 1;
      }
      
      metricStats[metric] = {
        'count': metricMeasurements.length,
        'avg_ms': durations.isEmpty ? 0 : 
            durations.reduce((a, b) => a + b) ~/ durations.length,
        'p50_ms': durations.isEmpty ? 0 : 
            durations[durations.length ~/ 2],
        'p95_ms': durations.isEmpty ? 0 : 
            durations[(durations.length * 0.95).floor()],
        'max_ms': durations.isEmpty ? 0 : durations.last,
        'level_counts': levelCounts.map((k, v) => MapEntry(k.toString(), v)),
        'threshold_ms': PerformanceThresholds.getThreshold(metric).inMilliseconds,
      };
    }
    
    return {
      'period_days': period?.inDays ?? 7,
      'total_measurements': measurements.length,
      'metrics': metricStats.map((k, v) => MapEntry(k.toString(), v)),
      'slow_operations': _getSlowOperations(measurements),
      'recommendations': _generateRecommendations(metricStats),
    };
  }
  
  /// Get startup performance analysis
  Future<Map<String, dynamic>> getStartupAnalysis() async {
    final measurements = await _getRecentMeasurements(const Duration(days: 30));
    
    final startupMeasurements = measurements
        .where((m) => m.metric == PerformanceMetric.appStartup)
        .toList();
    
    if (startupMeasurements.isEmpty) {
      return {'error': 'No startup measurements available'};
    }
    
    final durations = startupMeasurements
        .map((m) => m.duration.inMilliseconds)
        .toList()
      ..sort();
    
    final slowStartups = startupMeasurements
        .where((m) => m.level == PerformanceLevel.poor || 
                     m.level == PerformanceLevel.critical)
        .toList();
    
    return {
      'total_startups': startupMeasurements.length,
      'avg_startup_ms': durations.reduce((a, b) => a + b) ~/ durations.length,
      'p95_startup_ms': durations[(durations.length * 0.95).floor()],
      'slow_startup_rate': slowStartups.length / startupMeasurements.length,
      'threshold_ms': PerformanceThresholds.getThreshold(
          PerformanceMetric.appStartup).inMilliseconds,
      'recommendations': _generateStartupRecommendations(startupMeasurements),
    };
  }
  
  /// Monitor memory usage
  Future<void> monitorMemoryUsage(String operation) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    try {
      // Trigger garbage collection to get accurate reading
      // Note: This is approximation since ProcessInfo.currentRss 
      // is not available in Flutter
      
      final measurement = PerformanceMeasurement(
        metric: PerformanceMetric.memoryUsage,
        operation: operation,
        duration: const Duration(milliseconds: 1),
        timestamp: DateTime.now(),
        metadata: {
          'platform': Platform.operatingSystem,
        },
        level: PerformanceLevel.excellent, // Default since we can't measure easily
      );
      
      _sessionMeasurements.add(measurement);
      await _persistMeasurement(measurement);
    } catch (e) {
      // Ignore memory monitoring errors
    }
  }
  
  /// Export performance data
  Future<Map<String, dynamic>> exportPerformanceData() async {
    final allMeasurements = await _getAllStoredMeasurements();
    
    return {
      'total_measurements': allMeasurements.length,
      'export_timestamp': DateTime.now().toIso8601String(),
      'measurements': allMeasurements.map((m) => m.toJson()).toList(),
      'summary': await getPerformanceSummary(),
      'startup_analysis': await getStartupAnalysis(),
    };
  }
  
  /// Log slow operation
  void _logSlowOperation(PerformanceMeasurement measurement) {
    print('SLOW OPERATION: ${measurement.operation} '
        '(${measurement.duration.inMilliseconds}ms) '
        '- Level: ${measurement.level}');
  }
  
  /// Persist measurement to storage
  Future<void> _persistMeasurement(PerformanceMeasurement measurement) async {
    try {
      final measurements = await _getAllStoredMeasurements();
      
      measurements.insert(0, measurement);
      
      // Keep only recent measurements
      if (measurements.length > _maxStoredMeasurements) {
        measurements.removeRange(_maxStoredMeasurements, measurements.length);
      }
      
      final jsonMeasurements = measurements.map((m) => m.toJson()).toList();
      await _storage.setString(_measurementsKey, 
          LocalStorage.encodeJson(jsonMeasurements));
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Get recent measurements within time window
  Future<List<PerformanceMeasurement>> _getRecentMeasurements(
      Duration timeWindow) async {
    final allMeasurements = await _getAllStoredMeasurements();
    final cutoff = DateTime.now().subtract(timeWindow);
    
    return allMeasurements
        .where((m) => m.timestamp.isAfter(cutoff))
        .toList();
  }
  
  /// Get all stored measurements
  Future<List<PerformanceMeasurement>> _getAllStoredMeasurements() async {
    try {
      final stored = await _storage.getString(_measurementsKey);
      if (stored != null) {
        final List<dynamic> jsonMeasurements = 
            LocalStorage.parseJson(stored) ?? [];
        
        return jsonMeasurements
            .map((json) => PerformanceMeasurement.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Ignore errors
    }
    
    return [];
  }
  
  /// Clean up old measurements
  Future<void> _cleanupOldMeasurements() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final measurements = await _getAllStoredMeasurements();
    
    final recentMeasurements = measurements
        .where((m) => m.timestamp.isAfter(cutoff))
        .toList();
    
    if (recentMeasurements.length != measurements.length) {
      final jsonMeasurements = recentMeasurements.map((m) => m.toJson()).toList();
      await _storage.setString(_measurementsKey, 
          LocalStorage.encodeJson(jsonMeasurements));
    }
  }
  
  /// Get slow operations for reporting
  List<Map<String, dynamic>> _getSlowOperations(
      List<PerformanceMeasurement> measurements) {
    return measurements
        .where((m) => m.level == PerformanceLevel.poor || 
                     m.level == PerformanceLevel.critical)
        .map((m) => {
          'operation': m.operation,
          'metric': m.metric.toString(),
          'duration_ms': m.duration.inMilliseconds,
          'level': m.level.toString(),
          'timestamp': m.timestamp.toIso8601String(),
        })
        .toList()
      ..sort((a, b) => (b['duration_ms'] as int).compareTo(a['duration_ms'] as int));
  }
  
  /// Generate performance recommendations
  List<String> _generateRecommendations(
      Map<PerformanceMetric, Map<String, dynamic>> stats) {
    final recommendations = <String>[];
    
    stats.forEach((metric, data) {
      final avgMs = data['avg_ms'] as int;
      final thresholdMs = data['threshold_ms'] as int;
      final levelCounts = data['level_counts'] as Map<String, int>;
      final poorCount = levelCounts['PerformanceLevel.poor'] ?? 0;
      final criticalCount = levelCounts['PerformanceLevel.critical'] ?? 0;
      
      if (avgMs > thresholdMs * 1.5) {
        switch (metric) {
          case PerformanceMetric.appStartup:
            recommendations.add('Consider lazy loading non-critical startup components');
            break;
          case PerformanceMetric.screenTransition:
            recommendations.add('Optimize screen transition animations and data loading');
            break;
          case PerformanceMetric.widgetBuild:
            recommendations.add('Review widget build performance - consider const widgets');
            break;
          case PerformanceMetric.dataQuery:
            recommendations.add('Optimize database queries and add indexes');
            break;
          case PerformanceMetric.storageOperation:
            recommendations.add('Consider batching storage operations');
            break;
          default:
            break;
        }
      }
      
      if (poorCount + criticalCount > (data['count'] as int) * 0.2) {
        recommendations.add('${metric.toString()} has high failure rate - investigate bottlenecks');
      }
    });
    
    return recommendations;
  }
  
  /// Generate startup-specific recommendations
  List<String> _generateStartupRecommendations(
      List<PerformanceMeasurement> startupMeasurements) {
    final recommendations = <String>[];
    
    final avgDuration = startupMeasurements
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b) ~/ startupMeasurements.length;
    
    final threshold = PerformanceThresholds
        .getThreshold(PerformanceMetric.appStartup)
        .inMilliseconds;
    
    if (avgDuration > threshold) {
      recommendations.add('Average startup time exceeds target - optimize initialization');
    }
    
    if (avgDuration > threshold * 2) {
      recommendations.add('Critical startup performance issue - review splash screen duration');
    }
    
    final slowStartups = startupMeasurements
        .where((m) => m.level == PerformanceLevel.poor || 
                     m.level == PerformanceLevel.critical)
        .length;
    
    if (slowStartups > startupMeasurements.length * 0.3) {
      recommendations.add('High rate of slow startups - consider async initialization');
    }
    
    return recommendations;
  }
}