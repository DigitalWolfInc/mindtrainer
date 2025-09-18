/// Performance Profiler for MindTrainer
/// 
/// Monitors UI performance, logic speed, and startup times to ensure
/// optimal user experience across all devices.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../storage/local_storage.dart';
import '../analytics/engagement_analytics.dart';

/// Performance metric types
enum PerformanceMetricType {
  appStartup,
  screenRender,
  navigationTransition,
  databaseQuery,
  networkRequest,
  imageLoad,
  listScroll,
  proGateCheck,
  billingOperation,
  analyticsEvent,
}

/// Performance measurement
class PerformanceMeasurement {
  final String name;
  final PerformanceMetricType type;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  PerformanceMeasurement({
    required this.name,
    required this.type,
    required this.duration,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();
  
  double get durationMs => duration.inMicroseconds / 1000.0;
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'durationMs': durationMs,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
  
  factory PerformanceMeasurement.fromJson(Map<String, dynamic> json) {
    return PerformanceMeasurement(
      name: json['name'],
      type: PerformanceMetricType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PerformanceMetricType.screenRender,
      ),
      duration: Duration(microseconds: (json['durationMs'] * 1000).round()),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Performance benchmark thresholds
class PerformanceBenchmarks {
  static const Map<PerformanceMetricType, double> thresholds = {
    PerformanceMetricType.appStartup: 2000.0,        // 2s max startup
    PerformanceMetricType.screenRender: 100.0,      // 100ms max render
    PerformanceMetricType.navigationTransition: 300.0, // 300ms max navigation
    PerformanceMetricType.databaseQuery: 50.0,      // 50ms max query
    PerformanceMetricType.networkRequest: 5000.0,   // 5s max network
    PerformanceMetricType.imageLoad: 1000.0,        // 1s max image load
    PerformanceMetricType.listScroll: 16.0,         // 16ms for 60fps
    PerformanceMetricType.proGateCheck: 1.0,        // 1ms max gate check
    PerformanceMetricType.billingOperation: 10000.0, // 10s max billing
    PerformanceMetricType.analyticsEvent: 10.0,     // 10ms max analytics
  };
  
  static bool isWithinThreshold(PerformanceMetricType type, double durationMs) {
    final threshold = thresholds[type];
    return threshold == null || durationMs <= threshold;
  }
  
  static double getThreshold(PerformanceMetricType type) {
    return thresholds[type] ?? 1000.0;
  }
}

/// Frame timing monitor
class FrameTimingMonitor {
  final StreamController<double> _frameTimeController = 
      StreamController<double>.broadcast();
  
  bool _isMonitoring = false;
  final List<double> _frameTimes = [];
  Timer? _reportTimer;
  
  Stream<double> get frameTimeStream => _frameTimeController.stream;
  
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
    
    // Report frame stats every 5 seconds
    _reportTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _reportFrameStats();
    });
  }
  
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    _reportTimer?.cancel();
  }
  
  void _onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // Convert to ms
      _frameTimes.add(frameTime);
      
      if (!_frameTimeController.isClosed) {
        _frameTimeController.add(frameTime);
      }
    }
    
    // Keep only last 300 frames (5 seconds at 60fps)
    if (_frameTimes.length > 300) {
      _frameTimes.removeRange(0, _frameTimes.length - 300);
    }
  }
  
  void _reportFrameStats() {
    if (_frameTimes.isEmpty) return;
    
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final fps = 1000.0 / avgFrameTime;
    
    // Count janky frames (>16ms for 60fps)
    final jankyFrames = _frameTimes.where((t) => t > 16.0).length;
    final jankyPercentage = (jankyFrames / _frameTimes.length) * 100;
    
    // This would integrate with analytics system
    if (kDebugMode) {
      print('Frame Stats: ${fps.toStringAsFixed(1)}fps, '
            '${avgFrameTime.toStringAsFixed(1)}ms avg, '
            '${jankyPercentage.toStringAsFixed(1)}% janky');
    }
  }
  
  void dispose() {
    stopMonitoring();
    _frameTimeController.close();
  }
}

/// Memory usage monitor
class MemoryMonitor {
  static Future<Map<String, dynamic>> getCurrentMemoryUsage() async {
    try {
      final info = ProcessInfo.currentRss;
      return {
        'rss_bytes': info,
        'rss_mb': (info / (1024 * 1024)).toStringAsFixed(1),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Memory info unavailable',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  static Future<void> logMemoryUsage(String context, EngagementAnalytics analytics) async {
    final memoryInfo = await getCurrentMemoryUsage();
    
    await analytics.trackPerformanceMetric(
      'memory_usage',
      double.tryParse(memoryInfo['rss_mb'].toString().replaceAll(' MB', '')) ?? 0.0,
      unit: 'MB',
      properties: {
        'context': context,
        'rss_bytes': memoryInfo['rss_bytes'],
      },
    );
  }
}

/// Main performance profiler
class PerformanceProfiler {
  final LocalStorage _storage;
  final EngagementAnalytics? _analytics;
  final FrameTimingMonitor _frameMonitor = FrameTimingMonitor();
  
  static const String _measurementsKey = 'performance_measurements';
  static const String _startupTimeKey = 'app_startup_time';
  
  final Map<String, Stopwatch> _activeTimers = {};
  final StreamController<PerformanceMeasurement> _measurementController =
      StreamController<PerformanceMeasurement>.broadcast();
  
  bool _isEnabled = true;
  DateTime? _appStartTime;
  
  PerformanceProfiler(this._storage, this._analytics) {
    _appStartTime = DateTime.now();
  }
  
  /// Stream of performance measurements
  Stream<PerformanceMeasurement> get measurementStream => 
      _measurementController.stream;
  
  /// Enable/disable profiling
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    
    if (enabled) {
      _frameMonitor.startMonitoring();
    } else {
      _frameMonitor.stopMonitoring();
    }
  }
  
  /// Start timing a measurement
  void startMeasurement(String name, PerformanceMetricType type, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;
    
    final timerKey = '${name}_${type.name}';
    _activeTimers[timerKey] = Stopwatch()..start();
  }
  
  /// End timing and record measurement
  Future<PerformanceMeasurement?> endMeasurement(
    String name, 
    PerformanceMetricType type, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isEnabled) return null;
    
    final timerKey = '${name}_${type.name}';
    final stopwatch = _activeTimers.remove(timerKey);
    if (stopwatch == null) return null;
    
    stopwatch.stop();
    
    final measurement = PerformanceMeasurement(
      name: name,
      type: type,
      duration: stopwatch.elapsed,
      metadata: metadata ?? {},
    );
    
    await _recordMeasurement(measurement);
    return measurement;
  }
  
  /// Measure execution time of a function
  Future<T> measureExecution<T>(
    String name,
    PerformanceMetricType type,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isEnabled) return await operation();
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final measurement = PerformanceMeasurement(
        name: name,
        type: type,
        duration: stopwatch.elapsed,
        metadata: {
          'success': true,
          ...metadata ?? {},
        },
      );
      
      await _recordMeasurement(measurement);
      return result;
    } catch (e) {
      stopwatch.stop();
      
      final measurement = PerformanceMeasurement(
        name: name,
        type: type,
        duration: stopwatch.elapsed,
        metadata: {
          'success': false,
          'error': e.toString(),
          ...metadata ?? {},
        },
      );
      
      await _recordMeasurement(measurement);
      rethrow;
    }
  }
  
  /// Record app startup completion
  Future<void> recordStartupComplete() async {
    if (!_isEnabled || _appStartTime == null) return;
    
    final startupDuration = DateTime.now().difference(_appStartTime!);
    
    final measurement = PerformanceMeasurement(
      name: 'app_startup',
      type: PerformanceMetricType.appStartup,
      duration: startupDuration,
      metadata: {
        'cold_start': true,
      },
    );
    
    await _recordMeasurement(measurement);
    
    // Store for next app launch comparison
    await _storage.setString(_startupTimeKey, startupDuration.inMilliseconds.toString());
  }
  
  /// Get performance summary
  Future<Map<String, dynamic>> getPerformanceSummary({
    Duration? period,
  }) async {
    final measurements = await _getMeasurements(
      since: period != null ? DateTime.now().subtract(period) : null,
    );
    
    if (measurements.isEmpty) {
      return {'error': 'No measurements available'};
    }
    
    final byType = <PerformanceMetricType, List<PerformanceMeasurement>>{};
    for (final measurement in measurements) {
      byType[measurement.type] = byType[measurement.type] ?? [];
      byType[measurement.type]!.add(measurement);
    }
    
    final summary = <String, Map<String, dynamic>>{};
    
    for (final entry in byType.entries) {
      final typeMeasurements = entry.value;
      final durations = typeMeasurements.map((m) => m.durationMs).toList()..sort();
      
      final avg = durations.reduce((a, b) => a + b) / durations.length;
      final median = durations[durations.length ~/ 2];
      final p95 = durations[(durations.length * 0.95).round() - 1];
      final threshold = PerformanceBenchmarks.getThreshold(entry.key);
      final withinThreshold = durations.where((d) => d <= threshold).length;
      final thresholdPercentage = (withinThreshold / durations.length) * 100;
      
      summary[entry.key.name] = {
        'count': durations.length,
        'avg_ms': avg,
        'median_ms': median,
        'min_ms': durations.first,
        'max_ms': durations.last,
        'p95_ms': p95,
        'threshold_ms': threshold,
        'within_threshold_percent': thresholdPercentage,
        'performance_grade': _getPerformanceGrade(thresholdPercentage),
      };
    }
    
    return {
      'summary': summary,
      'total_measurements': measurements.length,
      'period_analyzed': period?.inDays,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get slow operations (above threshold)
  Future<List<PerformanceMeasurement>> getSlowOperations({
    Duration? period,
    int limit = 50,
  }) async {
    final measurements = await _getMeasurements(
      since: period != null ? DateTime.now().subtract(period) : null,
    );
    
    final slowOps = measurements
        .where((m) => !PerformanceBenchmarks.isWithinThreshold(m.type, m.durationMs))
        .toList();
    
    slowOps.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    
    return slowOps.take(limit).toList();
  }
  
  /// Get startup time history
  Future<List<double>> getStartupTimeHistory({int limit = 10}) async {
    final measurements = await _getMeasurements();
    
    final startupTimes = measurements
        .where((m) => m.type == PerformanceMetricType.appStartup)
        .map((m) => m.durationMs)
        .toList();
    
    startupTimes.sort();
    return startupTimes.take(limit).toList();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _frameMonitor.dispose();
    await _measurementController.close();
  }
  
  // Private methods
  
  Future<void> _recordMeasurement(PerformanceMeasurement measurement) async {
    // Save to storage
    final measurements = await _getMeasurements();
    measurements.add(measurement);
    
    // Keep only last 1000 measurements
    if (measurements.length > 1000) {
      measurements.removeRange(0, measurements.length - 1000);
    }
    
    await _saveMeasurements(measurements);
    
    // Send to analytics if available
    if (_analytics != null) {
      await _analytics!.trackPerformanceMetric(
        measurement.name,
        measurement.durationMs,
        unit: 'ms',
        properties: {
          'type': measurement.type.name,
          'within_threshold': PerformanceBenchmarks.isWithinThreshold(
            measurement.type, 
            measurement.durationMs
          ),
          ...measurement.metadata,
        },
      );
    }
    
    // Emit to stream
    if (!_measurementController.isClosed) {
      _measurementController.add(measurement);
    }
    
    // Log slow operations in debug mode
    if (kDebugMode && !PerformanceBenchmarks.isWithinThreshold(
        measurement.type, measurement.durationMs)) {
      print('SLOW OPERATION: ${measurement.name} took ${measurement.durationMs.toStringAsFixed(1)}ms '
            '(threshold: ${PerformanceBenchmarks.getThreshold(measurement.type)}ms)');
    }
  }
  
  Future<List<PerformanceMeasurement>> _getMeasurements({DateTime? since}) async {
    final measurementsJson = await _storage.getString(_measurementsKey);
    if (measurementsJson == null) return [];
    
    try {
      final List<dynamic> measurementsList = json.decode(measurementsJson);
      List<PerformanceMeasurement> measurements = measurementsList
          .map((json) => PerformanceMeasurement.fromJson(json))
          .toList();
      
      if (since != null) {
        measurements = measurements
            .where((m) => m.timestamp.isAfter(since))
            .toList();
      }
      
      return measurements;
    } catch (e) {
      return [];
    }
  }
  
  Future<void> _saveMeasurements(List<PerformanceMeasurement> measurements) async {
    final measurementsJson = json.encode(
      measurements.map((m) => m.toJson()).toList()
    );
    await _storage.setString(_measurementsKey, measurementsJson);
  }
  
  String _getPerformanceGrade(double thresholdPercentage) {
    if (thresholdPercentage >= 95) return 'A+';
    if (thresholdPercentage >= 90) return 'A';
    if (thresholdPercentage >= 85) return 'B+';
    if (thresholdPercentage >= 80) return 'B';
    if (thresholdPercentage >= 75) return 'C+';
    if (thresholdPercentage >= 70) return 'C';
    if (thresholdPercentage >= 60) return 'D';
    return 'F';
  }
}

/// Performance monitoring utilities
class PerformanceUtils {
  /// Measure widget build time
  static Future<void> measureWidgetBuild(
    String widgetName,
    PerformanceProfiler profiler,
    VoidCallback buildFunction,
  ) async {
    await profiler.measureExecution(
      'build_$widgetName',
      PerformanceMetricType.screenRender,
      () async => buildFunction(),
      metadata: {'widget': widgetName},
    );
  }
  
  /// Measure navigation transition
  static void measureNavigation(
    String routeName,
    PerformanceProfiler profiler,
  ) {
    profiler.startMeasurement(
      'navigate_to_$routeName',
      PerformanceMetricType.navigationTransition,
      metadata: {'route': routeName},
    );
    
    // End measurement should be called when navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await profiler.endMeasurement(
        'navigate_to_$routeName',
        PerformanceMetricType.navigationTransition,
        metadata: {'route': routeName},
      );
    });
  }
  
  /// Measure database operation
  static Future<T> measureDatabaseOp<T>(
    String operation,
    PerformanceProfiler profiler,
    Future<T> Function() dbOperation,
  ) async {
    return await profiler.measureExecution(
      'db_$operation',
      PerformanceMetricType.databaseQuery,
      dbOperation,
      metadata: {'operation': operation},
    );
  }
  
  /// Measure Pro gate check (should be very fast)
  static Future<T> measureProGateCheck<T>(
    String gateName,
    PerformanceProfiler profiler,
    T Function() gateCheck,
  ) async {
    return await profiler.measureExecution(
      'progate_$gateName',
      PerformanceMetricType.proGateCheck,
      () async => gateCheck(),
      metadata: {'gate': gateName},
    );
  }
}