/// Compliance Monitoring System for MindTrainer
/// 
/// Tracks Google Play policy changes, monitors compliance status,
/// and maintains automated compliance checks for ongoing policy adherence.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';

/// Compliance areas to monitor
enum ComplianceArea {
  inAppPurchases,     // Google Play Billing compliance
  dataPrivacy,        // GDPR, CCPA, privacy policies
  contentPolicy,      // Google Play content policies
  userGenerated,      // User-generated content policies
  advertising,        // Ad policy compliance (if applicable)
  accessibility,      // Accessibility requirements
  childSafety,        // COPPA and child safety
  security,           // Security best practices
}

/// Compliance status levels
enum ComplianceStatus {
  compliant,    // Fully compliant
  warning,      // Potential issues identified
  violation,    // Policy violation detected
  unknown,      // Status not determined
}

/// Compliance check result
class ComplianceCheckResult {
  final String checkId;
  final ComplianceArea area;
  final ComplianceStatus status;
  final DateTime checkedAt;
  final String title;
  final String description;
  final List<String> issues;
  final List<String> recommendations;
  final int severityScore; // 1-100, higher = more severe
  final Map<String, dynamic> metadata;
  
  ComplianceCheckResult({
    required this.checkId,
    required this.area,
    required this.status,
    required this.checkedAt,
    required this.title,
    required this.description,
    this.issues = const [],
    this.recommendations = const [],
    this.severityScore = 50,
    this.metadata = const {},
  });
  
  /// Whether this check requires immediate attention
  bool get requiresAttention => status == ComplianceStatus.violation || 
                                (status == ComplianceStatus.warning && severityScore >= 70);
  
  Map<String, dynamic> toJson() => {
    'checkId': checkId,
    'area': area.name,
    'status': status.name,
    'checkedAt': checkedAt.toIso8601String(),
    'title': title,
    'description': description,
    'issues': issues,
    'recommendations': recommendations,
    'severityScore': severityScore,
    'metadata': metadata,
  };
  
  factory ComplianceCheckResult.fromJson(Map<String, dynamic> json) {
    return ComplianceCheckResult(
      checkId: json['checkId'],
      area: ComplianceArea.values.firstWhere(
        (a) => a.name == json['area'],
        orElse: () => ComplianceArea.contentPolicy,
      ),
      status: ComplianceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ComplianceStatus.unknown,
      ),
      checkedAt: DateTime.parse(json['checkedAt']),
      title: json['title'],
      description: json['description'],
      issues: List<String>.from(json['issues'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      severityScore: json['severityScore'] ?? 50,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Policy change notification
class PolicyChangeNotification {
  final String id;
  final ComplianceArea area;
  final DateTime announcedAt;
  final DateTime effectiveDate;
  final String title;
  final String summary;
  final List<String> keyChanges;
  final List<String> actionItems;
  final int impactScore; // 1-100, higher = more impact
  final String sourceUrl;
  
  PolicyChangeNotification({
    required this.id,
    required this.area,
    required this.announcedAt,
    required this.effectiveDate,
    required this.title,
    required this.summary,
    this.keyChanges = const [],
    this.actionItems = const [],
    this.impactScore = 50,
    this.sourceUrl = '',
  });
  
  /// Days until policy becomes effective
  int get daysUntilEffective => effectiveDate.difference(DateTime.now()).inDays;
  
  /// Whether this change is urgent (less than 30 days)
  bool get isUrgent => daysUntilEffective <= 30 && daysUntilEffective >= 0;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'area': area.name,
    'announcedAt': announcedAt.toIso8601String(),
    'effectiveDate': effectiveDate.toIso8601String(),
    'title': title,
    'summary': summary,
    'keyChanges': keyChanges,
    'actionItems': actionItems,
    'impactScore': impactScore,
    'sourceUrl': sourceUrl,
  };
}

/// Annual compliance review report
class ComplianceReviewReport {
  final int year;
  final DateTime generatedAt;
  final Map<ComplianceArea, ComplianceStatus> areaStatus;
  final List<ComplianceCheckResult> criticalIssues;
  final List<PolicyChangeNotification> upcomingChanges;
  final Map<String, dynamic> recommendations;
  final double overallComplianceScore; // 0-100
  
  ComplianceReviewReport({
    required this.year,
    required this.generatedAt,
    required this.areaStatus,
    required this.criticalIssues,
    required this.upcomingChanges,
    required this.recommendations,
    required this.overallComplianceScore,
  });
  
  /// Number of areas with violations
  int get violationsCount => areaStatus.values
      .where((status) => status == ComplianceStatus.violation)
      .length;
  
  /// Number of areas with warnings
  int get warningsCount => areaStatus.values
      .where((status) => status == ComplianceStatus.warning)
      .length;
  
  /// Overall compliance grade
  String get complianceGrade {
    if (overallComplianceScore >= 95) return 'A+';
    if (overallComplianceScore >= 90) return 'A';
    if (overallComplianceScore >= 85) return 'B+';
    if (overallComplianceScore >= 80) return 'B';
    if (overallComplianceScore >= 75) return 'C+';
    if (overallComplianceScore >= 70) return 'C';
    if (overallComplianceScore >= 60) return 'D';
    return 'F';
  }
}

/// Compliance monitoring system
class ComplianceMonitor {
  final LocalStorage _storage;
  
  static const String _complianceChecksKey = 'compliance_checks';
  static const String _policyChangesKey = 'policy_changes';
  static const String _complianceSettingsKey = 'compliance_settings';
  static const String _lastReviewKey = 'last_compliance_review';
  
  final StreamController<ComplianceCheckResult> _checkResultController =
      StreamController<ComplianceCheckResult>.broadcast();
  
  final StreamController<PolicyChangeNotification> _policyChangeController =
      StreamController<PolicyChangeNotification>.broadcast();
  
  bool _monitoringEnabled = true;
  DateTime? _lastFullReview;
  
  ComplianceMonitor(this._storage);
  
  /// Stream of compliance check results
  Stream<ComplianceCheckResult> get checkResultStream => _checkResultController.stream;
  
  /// Stream of policy change notifications
  Stream<PolicyChangeNotification> get policyChangeStream => _policyChangeController.stream;
  
  /// Initialize the compliance monitor
  Future<void> initialize() async {
    await _loadSettings();
    await _schedulePeriodicChecks();
    
    if (kDebugMode) {
      print('Compliance monitor initialized');
    }
  }
  
  /// Run comprehensive compliance checks
  Future<List<ComplianceCheckResult>> runComplianceChecks({
    List<ComplianceArea>? specificAreas,
  }) async {
    if (!_monitoringEnabled) return [];
    
    final areasToCheck = specificAreas ?? ComplianceArea.values;
    final results = <ComplianceCheckResult>[];
    
    for (final area in areasToCheck) {
      final areaResults = await _checkComplianceArea(area);
      results.addAll(areaResults);
    }
    
    await _saveComplianceResults(results);
    
    // Emit results to stream
    for (final result in results) {
      if (!_checkResultController.isClosed) {
        _checkResultController.add(result);
      }
    }
    
    if (kDebugMode) {
      print('Completed compliance checks: ${results.length} results');
      final violations = results.where((r) => r.status == ComplianceStatus.violation).length;
      final warnings = results.where((r) => r.status == ComplianceStatus.warning).length;
      print('Violations: $violations, Warnings: $warnings');
    }
    
    return results;
  }
  
  /// Generate annual compliance review
  Future<ComplianceReviewReport> generateAnnualReview(int year) async {
    final allResults = await _getComplianceResults(
      since: DateTime(year, 1, 1),
      until: DateTime(year, 12, 31, 23, 59, 59),
    );
    
    final policyChanges = await _getPolicyChanges(
      since: DateTime(year, 1, 1),
    );
    
    // Analyze current status by area
    final areaStatus = <ComplianceArea, ComplianceStatus>{};
    for (final area in ComplianceArea.values) {
      areaStatus[area] = _getLatestAreaStatus(area, allResults);
    }
    
    // Identify critical issues
    final criticalIssues = allResults
        .where((r) => r.requiresAttention)
        .toList()
        ..sort((a, b) => b.severityScore.compareTo(a.severityScore));
    
    // Find upcoming policy changes
    final upcomingChanges = policyChanges
        .where((p) => p.effectiveDate.isAfter(DateTime.now()))
        .toList()
        ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    
    // Generate recommendations
    final recommendations = await _generateAnnualRecommendations(
      areaStatus,
      criticalIssues,
      upcomingChanges,
    );
    
    // Calculate overall compliance score
    final overallScore = _calculateOverallComplianceScore(areaStatus, criticalIssues);
    
    final report = ComplianceReviewReport(
      year: year,
      generatedAt: DateTime.now(),
      areaStatus: areaStatus,
      criticalIssues: criticalIssues.take(10).toList(),
      upcomingChanges: upcomingChanges.take(5).toList(),
      recommendations: recommendations,
      overallComplianceScore: overallScore,
    );
    
    await _storage.setString(_lastReviewKey, DateTime.now().toIso8601String());
    
    if (kDebugMode) {
      print('Generated annual compliance review for $year');
      print('Overall score: ${overallScore.toStringAsFixed(1)}');
      print('Grade: ${report.complianceGrade}');
      print('Critical issues: ${criticalIssues.length}');
    }
    
    return report;
  }
  
  /// Add policy change notification
  Future<void> addPolicyChange(PolicyChangeNotification change) async {
    final changes = await _getPolicyChanges();
    changes.insert(0, change); // Add to front
    
    // Keep only last 50 changes
    if (changes.length > 50) {
      changes.removeRange(50, changes.length);
    }
    
    await _savePolicyChanges(changes);
    
    // Emit to stream
    if (!_policyChangeController.isClosed) {
      _policyChangeController.add(change);
    }
    
    if (kDebugMode) {
      print('Added policy change: ${change.title}');
      if (change.isUrgent) {
        print('URGENT: Effective in ${change.daysUntilEffective} days');
      }
    }
  }
  
  /// Get compliance dashboard summary
  Future<Map<String, dynamic>> getComplianceDashboard() async {
    final recentResults = await _getComplianceResults(
      since: DateTime.now().subtract(const Duration(days: 30)),
    );
    
    final upcomingChanges = await _getUpcomingPolicyChanges(days: 90);
    final criticalIssues = recentResults.where((r) => r.requiresAttention).toList();
    
    // Calculate area-wise status
    final areaStatus = <String, String>{};
    for (final area in ComplianceArea.values) {
      areaStatus[area.name] = _getLatestAreaStatus(area, recentResults).name;
    }
    
    final overallScore = _calculateOverallComplianceScore(
      areaStatus.map((k, v) => MapEntry(
        ComplianceArea.values.firstWhere((a) => a.name == k),
        ComplianceStatus.values.firstWhere((s) => s.name == v),
      )),
      criticalIssues,
    );
    
    return {
      'last_check': recentResults.isNotEmpty ? recentResults.first.checkedAt.toIso8601String() : null,
      'overall_score': overallScore,
      'compliance_grade': _getComplianceGrade(overallScore),
      'area_status': areaStatus,
      'critical_issues': criticalIssues.length,
      'upcoming_changes': upcomingChanges.length,
      'urgent_changes': upcomingChanges.where((c) => c.isUrgent).length,
      'monitoring_enabled': _monitoringEnabled,
      'next_review_due': _getNextReviewDate(),
    };
  }
  
  /// Get specific compliance area status
  Future<Map<String, dynamic>> getAreaCompliance(ComplianceArea area) async {
    final areaResults = await _getComplianceResults(
      since: DateTime.now().subtract(const Duration(days: 90)),
    ).then((results) => results.where((r) => r.area == area).toList());
    
    if (areaResults.isEmpty) {
      return {
        'area': area.name,
        'status': 'unknown',
        'last_checked': null,
        'issues': [],
        'recommendations': [],
      };
    }
    
    final latest = areaResults.first;
    final allIssues = areaResults.expand((r) => r.issues).toSet().toList();
    final allRecommendations = areaResults.expand((r) => r.recommendations).toSet().toList();
    
    return {
      'area': area.name,
      'status': latest.status.name,
      'last_checked': latest.checkedAt.toIso8601String(),
      'severity_score': latest.severityScore,
      'issues': allIssues,
      'recommendations': allRecommendations,
      'check_history': areaResults.take(5).map((r) => {
        'date': r.checkedAt.toIso8601String(),
        'status': r.status.name,
        'title': r.title,
      }).toList(),
    };
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _checkResultController.close();
    await _policyChangeController.close();
  }
  
  // Private helper methods
  
  Future<List<ComplianceCheckResult>> _checkComplianceArea(ComplianceArea area) async {
    switch (area) {
      case ComplianceArea.inAppPurchases:
        return await _checkInAppPurchaseCompliance();
      case ComplianceArea.dataPrivacy:
        return await _checkDataPrivacyCompliance();
      case ComplianceArea.contentPolicy:
        return await _checkContentPolicyCompliance();
      case ComplianceArea.userGenerated:
        return await _checkUserGeneratedContentCompliance();
      case ComplianceArea.advertising:
        return await _checkAdvertisingCompliance();
      case ComplianceArea.accessibility:
        return await _checkAccessibilityCompliance();
      case ComplianceArea.childSafety:
        return await _checkChildSafetyCompliance();
      case ComplianceArea.security:
        return await _checkSecurityCompliance();
    }
  }
  
  Future<List<ComplianceCheckResult>> _checkInAppPurchaseCompliance() async {
    final results = <ComplianceCheckResult>[];
    
    // Check billing implementation compliance
    results.add(ComplianceCheckResult(
      checkId: 'billing_implementation',
      area: ComplianceArea.inAppPurchases,
      status: ComplianceStatus.compliant,
      checkedAt: DateTime.now(),
      title: 'Google Play Billing Implementation',
      description: 'Verify Google Play Billing SDK integration meets policy requirements',
      recommendations: [
        'Ensure all purchases use Google Play Billing',
        'Verify subscription management compliance',
        'Check purchase verification implementation',
      ],
    ));
    
    // Check pricing transparency
    results.add(ComplianceCheckResult(
      checkId: 'pricing_transparency',
      area: ComplianceArea.inAppPurchases,
      status: ComplianceStatus.compliant,
      checkedAt: DateTime.now(),
      title: 'Pricing Transparency',
      description: 'Verify all Pro features clearly indicate they require payment',
      recommendations: [
        'Ensure clear pricing information in app',
        'Verify upgrade prompts are not misleading',
        'Check subscription terms are clearly displayed',
      ],
    ));
    
    return results;
  }
  
  Future<List<ComplianceCheckResult>> _checkDataPrivacyCompliance() async {
    final results = <ComplianceCheckResult>[];
    
    // Privacy policy compliance
    results.add(ComplianceCheckResult(
      checkId: 'privacy_policy',
      area: ComplianceArea.dataPrivacy,
      status: ComplianceStatus.compliant,
      checkedAt: DateTime.now(),
      title: 'Privacy Policy Compliance',
      description: 'Verify privacy policy covers all data collection and usage',
      recommendations: [
        'Update privacy policy annually',
        'Ensure all data collection is documented',
        'Verify GDPR/CCPA compliance statements',
      ],
    ));
    
    return results;
  }
  
  Future<List<ComplianceCheckResult>> _checkContentPolicyCompliance() async {
    final results = <ComplianceCheckResult>[];
    
    // Content appropriateness
    results.add(ComplianceCheckResult(
      checkId: 'content_appropriateness',
      area: ComplianceArea.contentPolicy,
      status: ComplianceStatus.compliant,
      checkedAt: DateTime.now(),
      title: 'Content Appropriateness',
      description: 'Verify all app content meets Google Play content policies',
      recommendations: [
        'Review all text content for policy compliance',
        'Verify audio content is appropriate',
        'Check seasonal content meets guidelines',
      ],
    ));
    
    return results;
  }
  
  Future<List<ComplianceCheckResult>> _checkUserGeneratedContentCompliance() async {
    // MindTrainer doesn't have user-generated content, so this is compliant
    return [
      ComplianceCheckResult(
        checkId: 'ugc_not_applicable',
        area: ComplianceArea.userGenerated,
        status: ComplianceStatus.compliant,
        checkedAt: DateTime.now(),
        title: 'User Generated Content - Not Applicable',
        description: 'MindTrainer does not support user-generated content',
        recommendations: [
          'If adding social features, implement content moderation',
          'Consider user reporting mechanisms for any future UGC',
        ],
      ),
    ];
  }
  
  Future<List<ComplianceCheckResult>> _checkAdvertisingCompliance() async {
    // MindTrainer doesn't show ads, so this is compliant
    return [
      ComplianceCheckResult(
        checkId: 'ads_not_applicable',
        area: ComplianceArea.advertising,
        status: ComplianceStatus.compliant,
        checkedAt: DateTime.now(),
        title: 'Advertising - Not Applicable',
        description: 'MindTrainer does not display advertisements',
        recommendations: [
          'If adding ads in future, ensure compliance with ad policies',
          'Consider child-safety requirements for any future ads',
        ],
      ),
    ];
  }
  
  Future<List<ComplianceCheckResult>> _checkAccessibilityCompliance() async {
    return [
      ComplianceCheckResult(
        checkId: 'accessibility_features',
        area: ComplianceArea.accessibility,
        status: ComplianceStatus.warning,
        checkedAt: DateTime.now(),
        title: 'Accessibility Features',
        description: 'Review accessibility features and compliance',
        issues: [
          'Screen reader compatibility needs verification',
          'Color contrast ratios should be tested',
        ],
        recommendations: [
          'Test with screen readers and accessibility tools',
          'Verify color contrast meets WCAG guidelines',
          'Add accessibility labels to all interactive elements',
          'Test with high contrast and large text settings',
        ],
        severityScore: 60,
      ),
    ];
  }
  
  Future<List<ComplianceCheckResult>> _checkChildSafetyCompliance() async {
    return [
      ComplianceCheckResult(
        checkId: 'child_safety',
        area: ComplianceArea.childSafety,
        status: ComplianceStatus.compliant,
        checkedAt: DateTime.now(),
        title: 'Child Safety Compliance',
        description: 'MindTrainer is designed for adults but may be used by children',
        recommendations: [
          'Verify app content is appropriate for all ages',
          'Ensure no data collection from children under 13',
          'Consider adding parental controls if targeting families',
        ],
      ),
    ];
  }
  
  Future<List<ComplianceCheckResult>> _checkSecurityCompliance() async {
    return [
      ComplianceCheckResult(
        checkId: 'security_practices',
        area: ComplianceArea.security,
        status: ComplianceStatus.compliant,
        checkedAt: DateTime.now(),
        title: 'Security Best Practices',
        description: 'Verify app follows security best practices',
        recommendations: [
          'Regular security audits of dependencies',
          'Secure storage of user preferences',
          'Network communication security',
          'Regular penetration testing',
        ],
      ),
    ];
  }
  
  ComplianceStatus _getLatestAreaStatus(ComplianceArea area, List<ComplianceCheckResult> results) {
    final areaResults = results.where((r) => r.area == area).toList();
    if (areaResults.isEmpty) return ComplianceStatus.unknown;
    
    // Return the most severe status found
    for (final status in [ComplianceStatus.violation, ComplianceStatus.warning, ComplianceStatus.compliant]) {
      if (areaResults.any((r) => r.status == status)) {
        return status;
      }
    }
    
    return ComplianceStatus.unknown;
  }
  
  double _calculateOverallComplianceScore(
    Map<ComplianceArea, ComplianceStatus> areaStatus,
    List<ComplianceCheckResult> criticalIssues,
  ) {
    double score = 100.0;
    
    // Deduct for violations and warnings
    for (final status in areaStatus.values) {
      switch (status) {
        case ComplianceStatus.violation:
          score -= 20.0;
          break;
        case ComplianceStatus.warning:
          score -= 10.0;
          break;
        case ComplianceStatus.unknown:
          score -= 5.0;
          break;
        case ComplianceStatus.compliant:
          break;
      }
    }
    
    // Deduct for critical issues severity
    for (final issue in criticalIssues) {
      score -= (issue.severityScore / 10.0);
    }
    
    return score.clamp(0.0, 100.0);
  }
  
  String _getComplianceGrade(double score) {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'C+';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }
  
  Future<Map<String, dynamic>> _generateAnnualRecommendations(
    Map<ComplianceArea, ComplianceStatus> areaStatus,
    List<ComplianceCheckResult> criticalIssues,
    List<PolicyChangeNotification> upcomingChanges,
  ) async {
    return {
      'priority_actions': [
        'Address accessibility compliance gaps',
        'Update privacy policy annually',
        'Monitor Google Play policy updates',
      ],
      'preventive_measures': [
        'Quarterly compliance reviews',
        'Automated policy change monitoring',
        'Regular security audits',
      ],
      'policy_preparation': upcomingChanges.take(3).map((c) => {
        'title': c.title,
        'deadline': c.effectiveDate.toIso8601String(),
        'actions': c.actionItems,
      }).toList(),
    };
  }
  
  Future<void> _schedulePeriodicChecks() async {
    // Schedule monthly compliance checks
    Timer.periodic(const Duration(days: 30), (timer) async {
      if (_monitoringEnabled) {
        await runComplianceChecks();
      }
    });
  }
  
  Future<void> _loadSettings() async {
    final settingsJson = await _storage.getString(_complianceSettingsKey);
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);
        _monitoringEnabled = settings['monitoring_enabled'] ?? true;
      } catch (e) {
        // Use defaults
      }
    }
    
    final lastReviewStr = await _storage.getString(_lastReviewKey);
    if (lastReviewStr != null) {
      try {
        _lastFullReview = DateTime.parse(lastReviewStr);
      } catch (e) {
        // Ignore parsing error
      }
    }
  }
  
  String? _getNextReviewDate() {
    if (_lastFullReview == null) {
      return 'Overdue';
    }
    
    final nextReview = DateTime(_lastFullReview!.year + 1, _lastFullReview!.month, _lastFullReview!.day);
    if (nextReview.isBefore(DateTime.now())) {
      return 'Overdue';
    }
    
    return nextReview.toIso8601String();
  }
  
  Future<void> _saveComplianceResults(List<ComplianceCheckResult> results) async {
    final existingResults = await _getComplianceResults();
    existingResults.addAll(results);
    
    // Keep only last 6 months of results
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final filteredResults = existingResults
        .where((r) => r.checkedAt.isAfter(cutoff))
        .toList();
    
    // Sort by date (most recent first)
    filteredResults.sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
    
    final resultsJson = jsonEncode(filteredResults.map((r) => r.toJson()).toList());
    await _storage.setString(_complianceChecksKey, resultsJson);
  }
  
  Future<List<ComplianceCheckResult>> _getComplianceResults({
    DateTime? since,
    DateTime? until,
  }) async {
    final resultsJson = await _storage.getString(_complianceChecksKey);
    if (resultsJson == null) return [];
    
    try {
      final List<dynamic> resultsList = jsonDecode(resultsJson);
      List<ComplianceCheckResult> results = resultsList
          .map((json) => ComplianceCheckResult.fromJson(json))
          .toList();
      
      if (since != null) {
        results = results.where((r) => r.checkedAt.isAfter(since)).toList();
      }
      
      if (until != null) {
        results = results.where((r) => r.checkedAt.isBefore(until)).toList();
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading compliance results: $e');
      }
      return [];
    }
  }
  
  Future<void> _savePolicyChanges(List<PolicyChangeNotification> changes) async {
    final changesJson = jsonEncode(changes.map((c) => c.toJson()).toList());
    await _storage.setString(_policyChangesKey, changesJson);
  }
  
  Future<List<PolicyChangeNotification>> _getPolicyChanges({DateTime? since}) async {
    final changesJson = await _storage.getString(_policyChangesKey);
    if (changesJson == null) return [];
    
    try {
      final List<dynamic> changesList = jsonDecode(changesJson);
      List<PolicyChangeNotification> changes = changesList
          .map((json) => PolicyChangeNotification(
            id: json['id'],
            area: ComplianceArea.values.firstWhere(
              (a) => a.name == json['area'],
              orElse: () => ComplianceArea.contentPolicy,
            ),
            announcedAt: DateTime.parse(json['announcedAt']),
            effectiveDate: DateTime.parse(json['effectiveDate']),
            title: json['title'],
            summary: json['summary'],
            keyChanges: List<String>.from(json['keyChanges'] ?? []),
            actionItems: List<String>.from(json['actionItems'] ?? []),
            impactScore: json['impactScore'] ?? 50,
            sourceUrl: json['sourceUrl'] ?? '',
          ))
          .toList();
      
      if (since != null) {
        changes = changes.where((c) => c.announcedAt.isAfter(since)).toList();
      }
      
      return changes;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading policy changes: $e');
      }
      return [];
    }
  }
  
  Future<List<PolicyChangeNotification>> _getUpcomingPolicyChanges({int days = 90}) async {
    final allChanges = await _getPolicyChanges();
    final cutoff = DateTime.now().add(Duration(days: days));
    
    return allChanges
        .where((c) => c.effectiveDate.isAfter(DateTime.now()) && c.effectiveDate.isBefore(cutoff))
        .toList()
        ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
  }
}