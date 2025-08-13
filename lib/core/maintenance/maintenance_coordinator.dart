/// Maintenance Coordinator for MindTrainer
/// 
/// Central orchestrator for all maintenance activities including bug tracking,
/// performance monitoring, seasonal updates, Pro expansion planning, and compliance.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';
import '../analytics/engagement_analytics.dart';
import '../analytics/pro_feature_analysis.dart';
import '../experiments/ab_testing_framework.dart';
import '../performance/performance_profiler.dart';
import 'bug_tracking_service.dart';
import 'performance_dashboard.dart';
import 'seasonal_content_system.dart';
import 'pro_expansion_planner.dart';
import 'compliance_monitor.dart';

/// Maintenance task priority levels
enum MaintenancePriority {
  critical,  // Security, compliance violations, crashes
  high,      // Performance issues, feature problems
  medium,    // Improvements, optimizations
  low,       // Nice-to-have enhancements
}

/// Maintenance task types
enum MaintenanceTaskType {
  bugFix,
  performanceOptimization,
  complianceUpdate,
  seasonalUpdate,
  featureImprovement,
  securityPatch,
  dependencyUpdate,
  policyCompliance,
}

/// Maintenance task
class MaintenanceTask {
  final String id;
  final MaintenanceTaskType type;
  final MaintenancePriority priority;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final List<String> actionItems;
  final Map<String, dynamic> metadata;
  final String status; // pending, in_progress, completed, cancelled
  
  MaintenanceTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    this.actionItems = const [],
    this.metadata = const {},
    this.status = 'pending',
  });
  
  /// Whether this task is overdue
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!);
  
  /// Whether this task needs immediate attention
  bool get needsImmediateAttention => 
      priority == MaintenancePriority.critical || 
      (priority == MaintenancePriority.high && isOverdue);
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'priority': priority.name,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'actionItems': actionItems,
    'metadata': metadata,
    'status': status,
  };
}

/// Maintenance status report
class MaintenanceStatusReport {
  final DateTime generatedAt;
  final SystemHealthMetrics systemHealth;
  final Map<String, dynamic> performanceOverview;
  final Map<String, dynamic> complianceDashboard;
  final List<MaintenanceTask> urgentTasks;
  final List<MaintenanceTask> upcomingTasks;
  final Map<String, int> tasksByPriority;
  final Map<String, int> tasksByType;
  final double overallMaintenanceScore; // 0-100
  
  MaintenanceStatusReport({
    required this.generatedAt,
    required this.systemHealth,
    required this.performanceOverview,
    required this.complianceDashboard,
    required this.urgentTasks,
    required this.upcomingTasks,
    required this.tasksByPriority,
    required this.tasksByType,
    required this.overallMaintenanceScore,
  });
  
  /// Overall system status
  String get systemStatus {
    if (overallMaintenanceScore >= 90) return 'Excellent';
    if (overallMaintenanceScore >= 75) return 'Good';
    if (overallMaintenanceScore >= 60) return 'Fair';
    if (overallMaintenanceScore >= 40) return 'Poor';
    return 'Critical';
  }
  
  /// Number of critical issues
  int get criticalIssues => urgentTasks
      .where((t) => t.priority == MaintenancePriority.critical)
      .length;
}

/// Main maintenance coordinator
class MaintenanceCoordinator {
  final LocalStorage _storage;
  final EngagementAnalytics _analytics;
  final ABTestingFramework _abTesting;
  final PerformanceProfiler _profiler;
  final ProFeatureAnalyzer _featureAnalyzer;
  
  // Sub-systems
  late final BugTrackingService _bugTracker;
  late final PerformanceDashboard _performanceDashboard;
  late final SeasonalContentSystem _seasonalContent;
  late final ProExpansionPlanner _expansionPlanner;
  late final ComplianceMonitor _complianceMonitor;
  
  static const String _maintenanceTasksKey = 'maintenance_tasks';
  static const String _maintenanceConfigKey = 'maintenance_config';
  static const String _lastMaintenanceReviewKey = 'last_maintenance_review';
  
  final StreamController<MaintenanceTask> _taskController =
      StreamController<MaintenanceTask>.broadcast();
  
  final StreamController<MaintenanceStatusReport> _statusController =
      StreamController<MaintenanceStatusReport>.broadcast();
  
  bool _isInitialized = false;
  
  MaintenanceCoordinator(
    this._storage,
    this._analytics,
    this._abTesting,
    this._profiler,
    this._featureAnalyzer,
  );
  
  /// Stream of maintenance tasks
  Stream<MaintenanceTask> get taskStream => _taskController.stream;
  
  /// Stream of status reports
  Stream<MaintenanceStatusReport> get statusStream => _statusController.stream;
  
  /// Initialize all maintenance systems
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize sub-systems
    _bugTracker = BugTrackingService(_storage, _analytics);
    await _bugTracker.initialize();
    
    _performanceDashboard = PerformanceDashboard(_storage, _profiler);
    await _performanceDashboard.initialize();
    
    _seasonalContent = SeasonalContentSystem(_storage, _analytics, _abTesting);
    await _seasonalContent.initialize();
    
    _expansionPlanner = ProExpansionPlanner(_storage, _analytics, _featureAnalyzer);
    
    _complianceMonitor = ComplianceMonitor(_storage);
    await _complianceMonitor.initialize();
    
    // Set up event listeners
    _setupEventListeners();
    
    // Schedule periodic tasks
    await _scheduleMaintenanceTasks();
    
    _isInitialized = true;
    
    if (kDebugMode) {
      print('Maintenance coordinator initialized');
    }
  }
  
  /// Generate comprehensive maintenance status report
  Future<MaintenanceStatusReport> generateStatusReport() async {
    if (!_isInitialized) await initialize();
    
    // Gather data from all sub-systems
    final systemHealth = await _bugTracker.getSystemHealthMetrics();
    final performanceOverview = await _performanceDashboard.getPerformanceOverview();
    final complianceDashboard = await _complianceMonitor.getComplianceDashboard();
    
    // Get maintenance tasks
    final allTasks = await _getMaintenanceTasks();
    final urgentTasks = allTasks.where((t) => t.needsImmediateAttention).toList();
    final upcomingTasks = allTasks
        .where((t) => t.dueDate != null && 
                     t.dueDate!.isAfter(DateTime.now()) &&
                     t.dueDate!.isBefore(DateTime.now().add(const Duration(days: 7))))
        .toList();
    
    // Calculate task breakdowns
    final tasksByPriority = <String, int>{};
    final tasksByType = <String, int>{};
    
    for (final task in allTasks.where((t) => t.status != 'completed')) {
      tasksByPriority[task.priority.name] = (tasksByPriority[task.priority.name] ?? 0) + 1;
      tasksByType[task.type.name] = (tasksByType[task.type.name] ?? 0) + 1;
    }
    
    // Calculate overall maintenance score
    final overallScore = _calculateMaintenanceScore(
      systemHealth,
      performanceOverview,
      complianceDashboard,
      urgentTasks,
    );
    
    final report = MaintenanceStatusReport(
      generatedAt: DateTime.now(),
      systemHealth: systemHealth,
      performanceOverview: performanceOverview,
      complianceDashboard: complianceDashboard,
      urgentTasks: urgentTasks,
      upcomingTasks: upcomingTasks,
      tasksByPriority: tasksByPriority,
      tasksByType: tasksByType,
      overallMaintenanceScore: overallScore,
    );
    
    // Emit status report
    if (!_statusController.isClosed) {
      _statusController.add(report);
    }
    
    return report;
  }
  
  /// Run daily maintenance checks
  Future<void> runDailyMaintenance() async {
    if (!_isInitialized) await initialize();
    
    if (kDebugMode) {
      print('Running daily maintenance checks...');
    }
    
    // Performance monitoring
    await _performanceDashboard.checkPerformanceMetrics();
    
    // Generate maintenance tasks from findings
    await _generateMaintenanceTasksFromFindings();
    
    // Update seasonal content if needed
    await _checkSeasonalContentUpdates();
    
    // Generate status report
    await generateStatusReport();
    
    if (kDebugMode) {
      print('Daily maintenance completed');
    }
  }
  
  /// Run weekly maintenance tasks
  Future<void> runWeeklyMaintenance() async {
    if (!_isInitialized) await initialize();
    
    if (kDebugMode) {
      print('Running weekly maintenance tasks...');
    }
    
    // Comprehensive compliance checks
    await _complianceMonitor.runComplianceChecks();
    
    // Performance trend analysis
    // Bug report summary
    final bugSummary = await _bugTracker.generateBugSummary(days: 7);
    
    // Create maintenance tasks for issues found
    await _createMaintenanceTasksFromSummary(bugSummary);
    
    if (kDebugMode) {
      print('Weekly maintenance completed');
    }
  }
  
  /// Run quarterly maintenance tasks
  Future<void> runQuarterlyMaintenance() async {
    if (!_isInitialized) await initialize();
    
    if (kDebugMode) {
      print('Running quarterly maintenance tasks...');
    }
    
    // Generate feature performance reports
    await _expansionPlanner.generateQuarterlyReports();
    
    // Seasonal content update
    await _seasonalContent.performQuarterlyUpdate();
    
    // Create improvement recommendations
    final improvements = await _expansionPlanner.getImprovementRecommendations();
    await _createMaintenanceTasksFromRecommendations(improvements);
    
    if (kDebugMode) {
      print('Quarterly maintenance completed');
    }
  }
  
  /// Run annual maintenance tasks
  Future<void> runAnnualMaintenance() async {
    if (!_isInitialized) await initialize();
    
    if (kDebugMode) {
      print('Running annual maintenance tasks...');
    }
    
    final currentYear = DateTime.now().year;
    
    // Annual compliance review
    await _complianceMonitor.generateAnnualReview(currentYear);
    
    // Pro expansion planning
    await _expansionPlanner.createAnnualExpansionPlan(currentYear + 1);
    
    // Comprehensive system health audit
    await _performComprehensiveAudit();
    
    if (kDebugMode) {
      print('Annual maintenance completed');
    }
  }
  
  /// Add a maintenance task manually
  Future<void> addMaintenanceTask(MaintenanceTask task) async {
    final tasks = await _getMaintenanceTasks();
    tasks.insert(0, task);
    
    await _saveMaintenanceTasks(tasks);
    
    // Emit task
    if (!_taskController.isClosed) {
      _taskController.add(task);
    }
    
    if (kDebugMode) {
      print('Added maintenance task: ${task.title}');
    }
  }
  
  /// Mark a maintenance task as completed
  Future<void> completeMaintenanceTask(String taskId, {String? notes}) async {
    final tasks = await _getMaintenanceTasks();
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    
    if (taskIndex != -1) {
      final task = tasks[taskIndex];
      final completedTask = MaintenanceTask(
        id: task.id,
        type: task.type,
        priority: task.priority,
        title: task.title,
        description: task.description,
        createdAt: task.createdAt,
        dueDate: task.dueDate,
        actionItems: task.actionItems,
        metadata: {
          ...task.metadata,
          'completed_at': DateTime.now().toIso8601String(),
          'notes': notes,
        },
        status: 'completed',
      );
      
      tasks[taskIndex] = completedTask;
      await _saveMaintenanceTasks(tasks);
      
      if (kDebugMode) {
        print('Completed maintenance task: ${task.title}');
      }
    }
  }
  
  /// Get maintenance dashboard summary
  Future<Map<String, dynamic>> getMaintenanceDashboard() async {
    if (!_isInitialized) await initialize();
    
    final report = await generateStatusReport();
    
    return {
      'last_updated': report.generatedAt.toIso8601String(),
      'system_status': report.systemStatus,
      'overall_score': report.overallMaintenanceScore,
      'system_health': {
        'score': report.systemHealth.healthScore,
        'status': report.systemHealth.healthStatus,
        'crash_rate': report.systemHealth.crashRate,
        'active_bugs': report.systemHealth.activeBugCount,
        'critical_bugs': report.systemHealth.criticalBugCount,
      },
      'performance': {
        'score': report.performanceOverview['performance_score'],
        'status': report.performanceOverview['status'],
        'active_alerts': report.performanceOverview['active_alerts'],
        'critical_alerts': report.performanceOverview['critical_alerts'],
      },
      'compliance': {
        'score': report.complianceDashboard['overall_score'],
        'grade': report.complianceDashboard['compliance_grade'],
        'critical_issues': report.complianceDashboard['critical_issues'],
        'upcoming_changes': report.complianceDashboard['upcoming_changes'],
      },
      'maintenance_tasks': {
        'urgent': report.urgentTasks.length,
        'upcoming': report.upcomingTasks.length,
        'critical_issues': report.criticalIssues,
        'overdue': report.urgentTasks.where((t) => t.isOverdue).length,
      },
      'next_scheduled': {
        'daily': _getNextScheduledTime('daily'),
        'weekly': _getNextScheduledTime('weekly'),
        'quarterly': _getNextScheduledTime('quarterly'),
        'annual': _getNextScheduledTime('annual'),
      },
    };
  }
  
  /// Dispose all resources
  Future<void> dispose() async {
    await _bugTracker.dispose();
    await _performanceDashboard.dispose();
    await _seasonalContent.dispose();
    await _complianceMonitor.dispose();
    await _taskController.close();
    await _statusController.close();
  }
  
  // Private helper methods
  
  void _setupEventListeners() {
    // Listen for bug reports
    _bugTracker.bugReportStream.listen((bug) async {
      if (bug.isCritical || bug.affectsProFeatures) {
        await _createMaintenanceTaskFromBug(bug);
      }
    });
    
    // Listen for performance alerts
    _performanceDashboard.alertStream.listen((alert) async {
      if (alert.requiresImmediateAction) {
        await _createMaintenanceTaskFromPerformanceAlert(alert);
      }
    });
    
    // Listen for compliance issues
    _complianceMonitor.checkResultStream.listen((result) async {
      if (result.requiresAttention) {
        await _createMaintenanceTaskFromComplianceResult(result);
      }
    });
  }
  
  Future<void> _scheduleMaintenanceTasks() async {
    // Daily maintenance at 3 AM
    Timer.periodic(const Duration(hours: 24), (timer) async {
      final now = DateTime.now();
      if (now.hour == 3) {
        await runDailyMaintenance();
      }
    });
    
    // Weekly maintenance on Sundays
    Timer.periodic(const Duration(days: 7), (timer) async {
      final now = DateTime.now();
      if (now.weekday == DateTime.sunday) {
        await runWeeklyMaintenance();
      }
    });
    
    // Quarterly maintenance on first day of quarter
    Timer.periodic(const Duration(days: 1), (timer) async {
      final now = DateTime.now();
      if (now.day == 1 && [1, 4, 7, 10].contains(now.month)) {
        await runQuarterlyMaintenance();
      }
    });
    
    // Annual maintenance on January 1st
    Timer.periodic(const Duration(days: 365), (timer) async {
      final now = DateTime.now();
      if (now.month == 1 && now.day == 1) {
        await runAnnualMaintenance();
      }
    });
  }
  
  Future<void> _generateMaintenanceTasksFromFindings() async {
    // Get performance issues
    final performanceReport = await _performanceDashboard.generateMaintenanceReport();
    final degradingMetrics = performanceReport['degrading_metrics'] as List<String>;
    
    for (final metric in degradingMetrics) {
      await addMaintenanceTask(MaintenanceTask(
        id: 'perf_${metric}_${DateTime.now().millisecondsSinceEpoch}',
        type: MaintenanceTaskType.performanceOptimization,
        priority: MaintenancePriority.medium,
        title: 'Optimize $metric Performance',
        description: 'Performance metric $metric is degrading and needs optimization',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        actionItems: [
          'Profile $metric performance',
          'Identify performance bottlenecks',
          'Implement optimizations',
          'Verify performance improvement',
        ],
      ));
    }
  }
  
  Future<void> _createMaintenanceTaskFromBug(BugReport bug) async {
    final priority = bug.severity == BugSeverity.critical 
        ? MaintenancePriority.critical
        : MaintenancePriority.high;
    
    await addMaintenanceTask(MaintenanceTask(
      id: 'bug_${bug.id}',
      type: MaintenanceTaskType.bugFix,
      priority: priority,
      title: 'Fix Bug: ${bug.title}',
      description: bug.description,
      createdAt: DateTime.now(),
      dueDate: bug.isCritical 
          ? DateTime.now().add(const Duration(hours: 24))
          : DateTime.now().add(const Duration(days: 7)),
      actionItems: [
        'Reproduce the bug',
        'Identify root cause',
        'Implement fix',
        'Test fix thoroughly',
        'Deploy fix',
      ],
      metadata: {
        'bug_id': bug.id,
        'severity': bug.severity.name,
        'category': bug.category.name,
        'affects_pro': bug.affectsProFeatures,
      },
    ));
  }
  
  Future<void> _createMaintenanceTaskFromPerformanceAlert(PerformanceAlert alert) async {
    await addMaintenanceTask(MaintenanceTask(
      id: 'perf_alert_${alert.id}',
      type: MaintenanceTaskType.performanceOptimization,
      priority: alert.level == PerformanceAlertLevel.critical 
          ? MaintenancePriority.critical
          : MaintenancePriority.high,
      title: 'Address Performance Alert: ${alert.metric}',
      description: alert.message,
      createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      actionItems: [
        'Analyze performance degradation',
        'Identify optimization opportunities',
        'Implement performance improvements',
        'Verify performance restoration',
      ],
      metadata: {
        'alert_id': alert.id,
        'metric': alert.metric,
        'threshold': alert.threshold,
        'actual_value': alert.actualValue,
        'degradation_percent': alert.degradationPercent,
      },
    ));
  }
  
  Future<void> _createMaintenanceTaskFromComplianceResult(ComplianceCheckResult result) async {
    await addMaintenanceTask(MaintenanceTask(
      id: 'compliance_${result.checkId}',
      type: MaintenanceTaskType.complianceUpdate,
      priority: result.status == ComplianceStatus.violation
          ? MaintenancePriority.critical
          : MaintenancePriority.high,
      title: 'Address Compliance Issue: ${result.title}',
      description: result.description,
      createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      actionItems: result.recommendations,
      metadata: {
        'compliance_area': result.area.name,
        'severity_score': result.severityScore,
        'issues': result.issues,
      },
    ));
  }
  
  Future<void> _createMaintenanceTasksFromSummary(Map<String, dynamic> summary) async {
    final criticalBugs = summary['critical_bugs'] as int? ?? 0;
    
    if (criticalBugs > 5) {
      await addMaintenanceTask(MaintenanceTask(
        id: 'bug_audit_${DateTime.now().millisecondsSinceEpoch}',
        type: MaintenanceTaskType.bugFix,
        priority: MaintenancePriority.high,
        title: 'Critical Bug Audit',
        description: 'High number of critical bugs detected ($criticalBugs). Comprehensive audit needed.',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 3)),
        actionItems: [
          'Review all critical bugs',
          'Prioritize fixes by impact',
          'Assign bugs to development team',
          'Implement fixes',
          'Verify bug resolution',
        ],
      ));
    }
  }
  
  Future<void> _createMaintenanceTasksFromRecommendations(
    List<Map<String, dynamic>> recommendations,
  ) async {
    for (final rec in recommendations.take(5)) { // Top 5 recommendations
      await addMaintenanceTask(MaintenanceTask(
        id: 'improvement_${rec['feature_id']}_${DateTime.now().millisecondsSinceEpoch}',
        type: MaintenanceTaskType.featureImprovement,
        priority: _mapPriorityFromString(rec['priority'] as String),
        title: 'Improve Feature: ${rec['feature_name']}',
        description: 'Feature improvement based on performance analysis',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: (rec['estimated_effort'] as int) * 7)),
        actionItems: List<String>.from(rec['recommended_actions']),
        metadata: {
          'feature_id': rec['feature_id'],
          'performance_score': rec['performance_score'],
          'primary_issue': rec['primary_issue'],
        },
      ));
    }
  }
  
  MaintenancePriority _mapPriorityFromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return MaintenancePriority.high;
      case 'medium': return MaintenancePriority.medium;
      case 'low': return MaintenancePriority.low;
      default: return MaintenancePriority.medium;
    }
  }
  
  Future<void> _checkSeasonalContentUpdates() async {
    // Check if seasonal update is needed
    final currentSeason = _seasonalContent.getCurrentSeason();
    // This would check if content is outdated and trigger updates
  }
  
  Future<void> _performComprehensiveAudit() async {
    // Comprehensive system audit for annual maintenance
    // This would include security audit, dependency audit, etc.
  }
  
  double _calculateMaintenanceScore(
    SystemHealthMetrics systemHealth,
    Map<String, dynamic> performanceOverview,
    Map<String, dynamic> complianceDashboard,
    List<MaintenanceTask> urgentTasks,
  ) {
    double score = 100.0;
    
    // Factor in system health (40% weight)
    score = score * 0.6 + (systemHealth.healthScore * 0.4);
    
    // Factor in performance score (30% weight)
    final perfScore = performanceOverview['performance_score'] as int? ?? 50;
    score = score * 0.7 + (perfScore * 0.3);
    
    // Factor in compliance score (20% weight)
    final complianceScore = complianceDashboard['overall_score'] as double? ?? 50.0;
    score = score * 0.8 + (complianceScore * 0.2);
    
    // Deduct for urgent tasks (10% weight)
    final urgentDeduction = (urgentTasks.length * 5.0).clamp(0.0, 20.0);
    score -= urgentDeduction;
    
    return score.clamp(0.0, 100.0);
  }
  
  String _getNextScheduledTime(String interval) {
    final now = DateTime.now();
    
    switch (interval) {
      case 'daily':
        final next = DateTime(now.year, now.month, now.day + 1, 3);
        return next.toIso8601String();
      case 'weekly':
        final daysUntilSunday = (7 - now.weekday) % 7;
        final next = now.add(Duration(days: daysUntilSunday));
        return DateTime(next.year, next.month, next.day, 3).toIso8601String();
      case 'quarterly':
        final nextQuarter = [1, 4, 7, 10].firstWhere(
          (month) => month > now.month,
          orElse: () => 1, // Next year
        );
        final nextYear = nextQuarter == 1 ? now.year + 1 : now.year;
        return DateTime(nextYear, nextQuarter, 1, 3).toIso8601String();
      case 'annual':
        return DateTime(now.year + 1, 1, 1, 3).toIso8601String();
      default:
        return now.toIso8601String();
    }
  }
  
  Future<List<MaintenanceTask>> _getMaintenanceTasks() async {
    final tasksJson = await _storage.getString(_maintenanceTasksKey);
    if (tasksJson == null) return [];
    
    try {
      final List<dynamic> tasksList = jsonDecode(tasksJson);
      return tasksList.map((json) => _taskFromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading maintenance tasks: $e');
      }
      return [];
    }
  }
  
  Future<void> _saveMaintenanceTasks(List<MaintenanceTask> tasks) async {
    // Keep only last 200 tasks
    final tasksToSave = tasks.length > 200 ? tasks.take(200).toList() : tasks;
    
    final tasksJson = jsonEncode(tasksToSave.map((t) => t.toJson()).toList());
    await _storage.setString(_maintenanceTasksKey, tasksJson);
  }
  
  MaintenanceTask _taskFromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'],
      type: MaintenanceTaskType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MaintenanceTaskType.bugFix,
      ),
      priority: MaintenancePriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => MaintenancePriority.medium,
      ),
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      actionItems: List<String>.from(json['actionItems'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      status: json['status'] ?? 'pending',
    );
  }
}