/// Bug Tracking & Error Monitoring Service for MindTrainer
/// 
/// Provides centralized error logging, crash reporting, and issue tracking
/// for ongoing maintenance and quality assurance.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';
import '../analytics/engagement_analytics.dart';

/// Severity levels for bugs and issues
enum BugSeverity {
  critical,  // Crashes, data loss, security issues
  high,      // Major functionality broken, Pro features failing
  medium,    // Minor functionality issues, UI problems  
  low,       // Cosmetic issues, minor inconveniences
}

/// Bug categories for classification
enum BugCategory {
  crash,
  performance,
  ui,
  billing,
  proFeature,
  analytics,
  storage,
  network,
  other,
}

/// Bug report data structure
class BugReport {
  final String id;
  final DateTime timestamp;
  final BugSeverity severity;
  final BugCategory category;
  final String title;
  final String description;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appState;
  final String? stackTrace;
  final List<String> reproductionSteps;
  final bool isProUser;
  final String appVersion;
  
  BugReport({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.category,
    required this.title,
    required this.description,
    required this.deviceInfo,
    required this.appState,
    this.stackTrace,
    this.reproductionSteps = const [],
    required this.isProUser,
    required this.appVersion,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity.name,
    'category': category.name,
    'title': title,
    'description': description,
    'deviceInfo': deviceInfo,
    'appState': appState,
    'stackTrace': stackTrace,
    'reproductionSteps': reproductionSteps,
    'isProUser': isProUser,
    'appVersion': appVersion,
  };
  
  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      severity: BugSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => BugSeverity.medium,
      ),
      category: BugCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => BugCategory.other,
      ),
      title: json['title'],
      description: json['description'],
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo'] ?? {}),
      appState: Map<String, dynamic>.from(json['appState'] ?? {}),
      stackTrace: json['stackTrace'],
      reproductionSteps: List<String>.from(json['reproductionSteps'] ?? []),
      isProUser: json['isProUser'] ?? false,
      appVersion: json['appVersion'] ?? 'unknown',
    );
  }
  
  /// Check if this is a critical issue requiring immediate attention
  bool get isCritical => severity == BugSeverity.critical;
  
  /// Check if this affects Pro features
  bool get affectsProFeatures => 
      category == BugCategory.proFeature || 
      category == BugCategory.billing;
}

/// System health metrics
class SystemHealthMetrics {
  final DateTime timestamp;
  final double crashRate;        // Crashes per 1000 sessions
  final double errorRate;        // Errors per 1000 user actions
  final int activeBugCount;      // Unresolved bugs
  final int criticalBugCount;    // Critical severity bugs
  final double proUserErrorRate; // Error rate for Pro users
  final Map<BugCategory, int> errorsByCategory;
  
  SystemHealthMetrics({
    required this.timestamp,
    required this.crashRate,
    required this.errorRate,
    required this.activeBugCount,
    required this.criticalBugCount,
    required this.proUserErrorRate,
    required this.errorsByCategory,
  });
  
  /// Overall system health score (0-100)
  int get healthScore {
    int score = 100;
    
    // Deduct for crashes
    score -= (crashRate * 10).round().clamp(0, 30);
    
    // Deduct for errors
    score -= (errorRate * 5).round().clamp(0, 20);
    
    // Deduct for critical bugs
    score -= (criticalBugCount * 15).clamp(0, 30);
    
    // Deduct for active bug count
    score -= (activeBugCount * 2).clamp(0, 20);
    
    return score.clamp(0, 100);
  }
  
  /// System health status
  String get healthStatus {
    final score = healthScore;
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Poor';
    return 'Critical';
  }
}

/// Bug tracking and error monitoring service
class BugTrackingService {
  final LocalStorage _storage;
  final EngagementAnalytics _analytics;
  
  static const String _bugReportsKey = 'bug_reports';
  static const String _errorCountersKey = 'error_counters';
  static const String _healthMetricsKey = 'health_metrics';
  static const String _appVersionKey = 'app_version';
  
  final StreamController<BugReport> _bugReportController =
      StreamController<BugReport>.broadcast();
      
  String _appVersion = '1.0.0';
  
  BugTrackingService(this._storage, this._analytics);
  
  /// Stream of new bug reports
  Stream<BugReport> get bugReportStream => _bugReportController.stream;
  
  /// Initialize the service
  Future<void> initialize() async {
    await _loadAppVersion();
    await _setupErrorHandling();
    
    if (kDebugMode) {
      print('Bug tracking service initialized - Version: $_appVersion');
    }
  }
  
  /// Report a new bug or error
  Future<String> reportBug({
    required BugSeverity severity,
    required BugCategory category,
    required String title,
    required String description,
    String? stackTrace,
    List<String> reproductionSteps = const [],
    Map<String, dynamic>? additionalContext,
  }) async {
    final bugId = _generateBugId();
    final deviceInfo = await _collectDeviceInfo();
    final appState = await _collectAppState();
    
    final bug = BugReport(
      id: bugId,
      timestamp: DateTime.now(),
      severity: severity,
      category: category,
      title: title,
      description: description,
      deviceInfo: deviceInfo,
      appState: {
        ...appState,
        ...additionalContext ?? {},
      },
      stackTrace: stackTrace,
      reproductionSteps: reproductionSteps,
      isProUser: appState['isProUser'] ?? false,
      appVersion: _appVersion,
    );
    
    await _saveBugReport(bug);
    await _updateErrorCounters(category, severity);
    
    // Track critical issues with analytics
    if (bug.isCritical || bug.affectsProFeatures) {
      await _analytics.trackEvent('critical_bug_reported', {
        'bug_id': bugId,
        'severity': severity.name,
        'category': category.name,
        'affects_pro': bug.affectsProFeatures,
        'is_pro_user': bug.isProUser,
      });
    }
    
    // Emit to stream
    if (!_bugReportController.isClosed) {
      _bugReportController.add(bug);
    }
    
    if (kDebugMode) {
      print('Bug reported: $bugId - ${severity.name} ${category.name}');
      print('Title: $title');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
    
    return bugId;
  }
  
  /// Report a caught exception
  Future<String> reportException(
    dynamic exception,
    StackTrace? stackTrace, {
    BugSeverity severity = BugSeverity.medium,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    final category = _categorizeException(exception);
    final title = 'Exception: ${exception.runtimeType}';
    final description = context != null 
        ? '$context\n\nException: $exception'
        : 'Exception: $exception';
    
    return await reportBug(
      severity: severity,
      category: category,
      title: title,
      description: description,
      stackTrace: stackTrace?.toString(),
      additionalContext: additionalInfo,
    );
  }
  
  /// Get all bug reports
  Future<List<BugReport>> getBugReports({
    BugSeverity? filterSeverity,
    BugCategory? filterCategory,
    int? limitDays,
  }) async {
    final reportsJson = await _storage.getString(_bugReportsKey);
    if (reportsJson == null) return [];
    
    try {
      final List<dynamic> reportsList = jsonDecode(reportsJson);
      List<BugReport> reports = reportsList
          .map((json) => BugReport.fromJson(json))
          .toList();
      
      // Apply filters
      if (filterSeverity != null) {
        reports = reports.where((r) => r.severity == filterSeverity).toList();
      }
      
      if (filterCategory != null) {
        reports = reports.where((r) => r.category == filterCategory).toList();
      }
      
      if (limitDays != null) {
        final cutoff = DateTime.now().subtract(Duration(days: limitDays));
        reports = reports.where((r) => r.timestamp.isAfter(cutoff)).toList();
      }
      
      // Sort by timestamp (most recent first)
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return reports;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bug reports: $e');
      }
      return [];
    }
  }
  
  /// Get system health metrics
  Future<SystemHealthMetrics> getSystemHealthMetrics() async {
    final reports = await getBugReports(limitDays: 30);
    final counters = await _getErrorCounters();
    
    final totalSessions = counters['total_sessions'] ?? 1;
    final totalActions = counters['total_user_actions'] ?? 1;
    final crashes = reports.where((r) => r.category == BugCategory.crash).length;
    final errors = reports.length;
    
    final crashRate = (crashes / totalSessions) * 1000;
    final errorRate = (errors / totalActions) * 1000;
    final activeBugs = reports.length; // In real system, would filter by status
    final criticalBugs = reports.where((r) => r.isCritical).length;
    
    // Calculate Pro user error rate
    final proErrors = reports.where((r) => r.isProUser).length;
    final proSessions = counters['pro_user_sessions'] ?? 1;
    final proErrorRate = (proErrors / proSessions) * 1000;
    
    // Group errors by category
    final errorsByCategory = <BugCategory, int>{};
    for (final category in BugCategory.values) {
      errorsByCategory[category] = reports
          .where((r) => r.category == category)
          .length;
    }
    
    return SystemHealthMetrics(
      timestamp: DateTime.now(),
      crashRate: crashRate,
      errorRate: errorRate,
      activeBugCount: activeBugs,
      criticalBugCount: criticalBugs,
      proUserErrorRate: proErrorRate,
      errorsByCategory: errorsByCategory,
    );
  }
  
  /// Generate bug report summary for review
  Future<Map<String, dynamic>> generateBugSummary({int days = 30}) async {
    final reports = await getBugReports(limitDays: days);
    final metrics = await getSystemHealthMetrics();
    
    final severityBreakdown = <BugSeverity, int>{};
    final categoryBreakdown = <BugCategory, int>{};
    final proVsFreeBreakdown = {'pro': 0, 'free': 0};
    
    for (final report in reports) {
      severityBreakdown[report.severity] = 
          (severityBreakdown[report.severity] ?? 0) + 1;
      categoryBreakdown[report.category] = 
          (categoryBreakdown[report.category] ?? 0) + 1;
      proVsFreeBreakdown[report.isProUser ? 'pro' : 'free'] = 
          proVsFreeBreakdown[report.isProUser ? 'pro' : 'free']! + 1;
    }
    
    return {
      'period_days': days,
      'total_reports': reports.length,
      'health_score': metrics.healthScore,
      'health_status': metrics.healthStatus,
      'crash_rate': metrics.crashRate,
      'error_rate': metrics.errorRate,
      'critical_bugs': metrics.criticalBugCount,
      'severity_breakdown': severityBreakdown.map((k, v) => MapEntry(k.name, v)),
      'category_breakdown': categoryBreakdown.map((k, v) => MapEntry(k.name, v)),
      'user_tier_breakdown': proVsFreeBreakdown,
      'top_issues': _getTopIssues(reports),
    };
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _bugReportController.close();
  }
  
  // Private helper methods
  
  Future<void> _loadAppVersion() async {
    _appVersion = await _storage.getString(_appVersionKey) ?? '1.0.0';
  }
  
  Future<void> _setupErrorHandling() async {
    // Set up global error handler for uncaught exceptions
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // Platform dispatcher error handler for async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
  }
  
  Future<void> _handleFlutterError(FlutterErrorDetails details) async {
    // Determine severity based on error context
    final severity = details.silent ? BugSeverity.low : BugSeverity.high;
    
    await reportException(
      details.exception,
      details.stack,
      severity: severity,
      context: 'Flutter Error: ${details.context}',
      additionalInfo: {
        'library': details.library,
        'silent': details.silent,
      },
    );
  }
  
  Future<void> _handlePlatformError(Object error, StackTrace stack) async {
    await reportException(
      error,
      stack,
      severity: BugSeverity.high,
      context: 'Platform Error',
    );
  }
  
  String _generateBugId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'bug_${timestamp}_$random';
  }
  
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    try {
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'locale': Platform.localeName,
        'hostname': Platform.localHostname,
        'processors': Platform.numberOfProcessors,
      };
    } catch (e) {
      return {'error': 'Could not collect device info'};
    }
  }
  
  Future<Map<String, dynamic>> _collectAppState() async {
    // This would integrate with your app's state management
    // For now, return basic state information
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'isProUser': false, // Would be actual Pro status
      'app_version': _appVersion,
    };
  }
  
  BugCategory _categorizeException(dynamic exception) {
    final exceptionString = exception.toString().toLowerCase();
    
    if (exceptionString.contains('socket') || exceptionString.contains('network')) {
      return BugCategory.network;
    } else if (exceptionString.contains('storage') || exceptionString.contains('database')) {
      return BugCategory.storage;
    } else if (exceptionString.contains('billing') || exceptionString.contains('purchase')) {
      return BugCategory.billing;
    } else if (exceptionString.contains('performance') || exceptionString.contains('memory')) {
      return BugCategory.performance;
    } else {
      return BugCategory.other;
    }
  }
  
  Future<void> _saveBugReport(BugReport report) async {
    final reports = await getBugReports();
    reports.insert(0, report); // Add to front
    
    // Keep only last 500 reports to manage storage
    if (reports.length > 500) {
      reports.removeRange(500, reports.length);
    }
    
    final reportsJson = jsonEncode(
      reports.map((r) => r.toJson()).toList()
    );
    await _storage.setString(_bugReportsKey, reportsJson);
  }
  
  Future<void> _updateErrorCounters(BugCategory category, BugSeverity severity) async {
    final counters = await _getErrorCounters();
    
    counters['total_errors'] = (counters['total_errors'] ?? 0) + 1;
    counters['${category.name}_errors'] = (counters['${category.name}_errors'] ?? 0) + 1;
    counters['${severity.name}_errors'] = (counters['${severity.name}_errors'] ?? 0) + 1;
    
    await _storage.setString(_errorCountersKey, jsonEncode(counters));
  }
  
  Future<Map<String, int>> _getErrorCounters() async {
    final countersJson = await _storage.getString(_errorCountersKey);
    if (countersJson == null) return {};
    
    try {
      final Map<String, dynamic> data = jsonDecode(countersJson);
      return data.map((k, v) => MapEntry(k, v as int));
    } catch (e) {
      return {};
    }
  }
  
  List<Map<String, dynamic>> _getTopIssues(List<BugReport> reports) {
    // Group by title to find recurring issues
    final issueGroups = <String, List<BugReport>>{};
    for (final report in reports) {
      issueGroups[report.title] = (issueGroups[report.title] ?? [])..add(report);
    }
    
    // Sort by frequency and return top 5
    final topIssues = issueGroups.entries
        .map((entry) => {
          'title': entry.key,
          'count': entry.value.length,
          'severity': entry.value.first.severity.name,
          'category': entry.value.first.category.name,
        })
        .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    return topIssues.take(5).toList();
  }
}