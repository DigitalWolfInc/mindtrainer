/// A/B Testing Framework for MindTrainer
/// 
/// Pure Dart implementation for controlled UI/wording experiments without external packages.
/// Supports feature toggles, variant assignment, and metrics collection.

import 'dart:convert';
import 'dart:math';
import '../storage/local_storage.dart';

/// Experiment status
enum ExperimentStatus {
  draft,
  running, 
  paused,
  completed,
}

/// Experiment variant
class ExperimentVariant {
  final String name;
  final double trafficAllocation; // 0.0 - 1.0
  final Map<String, dynamic> parameters;
  
  const ExperimentVariant({
    required this.name,
    required this.trafficAllocation,
    this.parameters = const {},
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'trafficAllocation': trafficAllocation,
    'parameters': parameters,
  };
  
  factory ExperimentVariant.fromJson(Map<String, dynamic> json) {
    return ExperimentVariant(
      name: json['name'],
      trafficAllocation: json['trafficAllocation'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }
}

/// Experiment configuration
class Experiment {
  final String id;
  final String name;
  final String description;
  final ExperimentStatus status;
  final List<ExperimentVariant> variants;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> targetingCriteria;
  final Map<String, dynamic> metadata;
  
  const Experiment({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.variants,
    this.startDate,
    this.endDate,
    this.targetingCriteria = const [],
    this.metadata = const {},
  });
  
  bool get isActive => 
      status == ExperimentStatus.running &&
      (startDate == null || DateTime.now().isAfter(startDate!)) &&
      (endDate == null || DateTime.now().isBefore(endDate!));
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'status': status.name,
    'variants': variants.map((v) => v.toJson()).toList(),
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'targetingCriteria': targetingCriteria,
    'metadata': metadata,
  };
  
  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: ExperimentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ExperimentStatus.draft,
      ),
      variants: (json['variants'] as List)
          .map((v) => ExperimentVariant.fromJson(v))
          .toList(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      targetingCriteria: List<String>.from(json['targetingCriteria'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// User assignment to experiment variant
class ExperimentAssignment {
  final String experimentId;
  final String variantName;
  final DateTime assignedAt;
  final Map<String, dynamic> userContext;
  
  ExperimentAssignment({
    required this.experimentId,
    required this.variantName,
    required this.assignedAt,
    this.userContext = const {},
  });
  
  Map<String, dynamic> toJson() => {
    'experimentId': experimentId,
    'variantName': variantName,
    'assignedAt': assignedAt.toIso8601String(),
    'userContext': userContext,
  };
  
  factory ExperimentAssignment.fromJson(Map<String, dynamic> json) {
    return ExperimentAssignment(
      experimentId: json['experimentId'],
      variantName: json['variantName'],
      assignedAt: DateTime.parse(json['assignedAt']),
      userContext: Map<String, dynamic>.from(json['userContext'] ?? {}),
    );
  }
}

/// Experiment event for analytics
class ExperimentEvent {
  final String experimentId;
  final String variantName;
  final String eventName;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  
  ExperimentEvent({
    required this.experimentId,
    required this.variantName,
    required this.eventName,
    this.properties = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'experimentId': experimentId,
    'variantName': variantName,
    'eventName': eventName,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Main A/B testing framework
class ABTestingFramework {
  final LocalStorage _storage;
  final Random _random = Random();
  
  static const String _experimentsKey = 'ab_experiments';
  static const String _assignmentsKey = 'ab_assignments';
  static const String _eventsKey = 'ab_events';
  static const String _userIdKey = 'ab_user_id';
  
  final Map<String, Experiment> _experiments = {};
  final Map<String, ExperimentAssignment> _assignments = {};
  String? _userId;
  
  ABTestingFramework(this._storage);
  
  /// Initialize the framework
  Future<void> initialize() async {
    await _loadUserId();
    await _loadExperiments();
    await _loadAssignments();
  }
  
  /// Add or update an experiment
  Future<void> addExperiment(Experiment experiment) async {
    _experiments[experiment.id] = experiment;
    await _saveExperiments();
  }
  
  /// Get variant for an experiment
  Future<String?> getVariant(String experimentId, {
    Map<String, dynamic>? userContext,
  }) async {
    final experiment = _experiments[experimentId];
    if (experiment == null || !experiment.isActive) return null;
    
    // Check existing assignment
    final existing = _assignments[experimentId];
    if (existing != null) {
      return existing.variantName;
    }
    
    // Check targeting criteria
    if (!_matchesTargeting(experiment, userContext ?? {})) {
      return null;
    }
    
    // Assign variant
    final variant = _assignVariant(experiment);
    if (variant != null) {
      final assignment = ExperimentAssignment(
        experimentId: experimentId,
        variantName: variant.name,
        assignedAt: DateTime.now(),
        userContext: userContext ?? {},
      );
      
      _assignments[experimentId] = assignment;
      await _saveAssignments();
      
      // Track assignment event
      await trackEvent(experimentId, variant.name, 'experiment_assigned');
    }
    
    return variant?.name;
  }
  
  /// Get variant parameters
  Future<Map<String, dynamic>> getVariantParameters(String experimentId) async {
    final variantName = await getVariant(experimentId);
    if (variantName == null) return {};
    
    final experiment = _experiments[experimentId];
    if (experiment == null) return {};
    
    final variant = experiment.variants.firstWhere(
      (v) => v.name == variantName,
      orElse: () => const ExperimentVariant(name: '', trafficAllocation: 0),
    );
    
    return variant.parameters;
  }
  
  /// Check if user is in experiment
  Future<bool> isInExperiment(String experimentId) async {
    final variant = await getVariant(experimentId);
    return variant != null;
  }
  
  /// Check if user is in specific variant
  Future<bool> isInVariant(String experimentId, String variantName) async {
    final userVariant = await getVariant(experimentId);
    return userVariant == variantName;
  }
  
  /// Track experiment event
  Future<void> trackEvent(String experimentId, String variantName, String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    final event = ExperimentEvent(
      experimentId: experimentId,
      variantName: variantName,
      eventName: eventName,
      properties: properties ?? {},
    );
    
    await _saveEvent(event);
  }
  
  /// Track event for current user's variant
  Future<void> trackEventForUser(String experimentId, String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    final assignment = _assignments[experimentId];
    if (assignment == null) return;
    
    await trackEvent(
      experimentId, 
      assignment.variantName, 
      eventName,
      properties: properties,
    );
  }
  
  /// Get all experiments
  Map<String, Experiment> get experiments => Map.unmodifiable(_experiments);
  
  /// Get user assignments
  Map<String, ExperimentAssignment> get assignments => Map.unmodifiable(_assignments);
  
  /// Get experiment events for analytics
  Future<List<ExperimentEvent>> getEvents({
    String? experimentId,
    DateTime? since,
  }) async {
    final eventsJson = await _storage.getString(_eventsKey);
    if (eventsJson == null) return [];
    
    try {
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      List<ExperimentEvent> events = eventsList
          .map((json) => ExperimentEvent(
                experimentId: json['experimentId'],
                variantName: json['variantName'],
                eventName: json['eventName'],
                properties: Map<String, dynamic>.from(json['properties'] ?? {}),
                timestamp: DateTime.parse(json['timestamp']),
              ))
          .toList();
      
      // Filter by experiment ID
      if (experimentId != null) {
        events = events.where((e) => e.experimentId == experimentId).toList();
      }
      
      // Filter by date
      if (since != null) {
        events = events.where((e) => e.timestamp.isAfter(since)).toList();
      }
      
      return events;
    } catch (e) {
      return [];
    }
  }
  
  // Private methods
  
  Future<void> _loadUserId() async {
    _userId = await _storage.getString(_userIdKey);
    if (_userId == null) {
      _userId = _generateUserId();
      await _storage.setString(_userIdKey, _userId!);
    }
  }
  
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
  }
  
  Future<void> _loadExperiments() async {
    final experimentsJson = await _storage.getString(_experimentsKey);
    if (experimentsJson != null) {
      try {
        final Map<String, dynamic> experimentsMap = jsonDecode(experimentsJson);
        for (final entry in experimentsMap.entries) {
          _experiments[entry.key] = Experiment.fromJson(entry.value);
        }
      } catch (e) {
        // Continue with empty experiments map
      }
    }
  }
  
  Future<void> _saveExperiments() async {
    final experimentsMap = <String, dynamic>{};
    for (final entry in _experiments.entries) {
      experimentsMap[entry.key] = entry.value.toJson();
    }
    final experimentsJson = jsonEncode(experimentsMap);
    await _storage.setString(_experimentsKey, experimentsJson);
  }
  
  Future<void> _loadAssignments() async {
    final assignmentsJson = await _storage.getString(_assignmentsKey);
    if (assignmentsJson != null) {
      try {
        final Map<String, dynamic> assignmentsMap = jsonDecode(assignmentsJson);
        for (final entry in assignmentsMap.entries) {
          _assignments[entry.key] = ExperimentAssignment.fromJson(entry.value);
        }
      } catch (e) {
        // Continue with empty assignments map
      }
    }
  }
  
  Future<void> _saveAssignments() async {
    final assignmentsMap = <String, dynamic>{};
    for (final entry in _assignments.entries) {
      assignmentsMap[entry.key] = entry.value.toJson();
    }
    final assignmentsJson = jsonEncode(assignmentsMap);
    await _storage.setString(_assignmentsKey, assignmentsJson);
  }
  
  Future<void> _saveEvent(ExperimentEvent event) async {
    final events = await getEvents();
    events.add(event);
    
    // Keep only last 1000 events to manage storage
    if (events.length > 1000) {
      events.removeRange(0, events.length - 1000);
    }
    
    final eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
    await _storage.setString(_eventsKey, eventsJson);
  }
  
  bool _matchesTargeting(Experiment experiment, Map<String, dynamic> context) {
    // Simple targeting - can be extended
    for (final criteria in experiment.targetingCriteria) {
      if (criteria == 'free_users_only' && context['isPro'] == true) {
        return false;
      }
      if (criteria == 'pro_users_only' && context['isPro'] != true) {
        return false;
      }
      if (criteria == 'new_users_only') {
        final daysActive = context['days_active'] as int? ?? 0;
        if (daysActive > 7) return false;
      }
    }
    return true;
  }
  
  ExperimentVariant? _assignVariant(Experiment experiment) {
    if (experiment.variants.isEmpty) return null;
    
    // Use consistent hash for user ID to ensure same user gets same variant
    final hash = _userId.hashCode;
    final random = Random(hash);
    final randomValue = random.nextDouble();
    
    double cumulativeAllocation = 0.0;
    for (final variant in experiment.variants) {
      cumulativeAllocation += variant.trafficAllocation;
      if (randomValue <= cumulativeAllocation) {
        return variant;
      }
    }
    
    // Fallback to first variant
    return experiment.variants.first;
  }
}

/// Convenience class for common experiments
class CommonExperiments {
  /// Upsell message style experiment
  static Experiment upsellMessageStyle() {
    return Experiment(
      id: 'upsell_message_style_v1',
      name: 'Upsell Message Style Test',
      description: 'Test different messaging styles for Pro upgrade prompts',
      status: ExperimentStatus.running,
      variants: [
        const ExperimentVariant(
          name: 'supportive',
          trafficAllocation: 0.25,
          parameters: {'messageStyle': 'supportive'},
        ),
        const ExperimentVariant(
          name: 'achievement',
          trafficAllocation: 0.25,
          parameters: {'messageStyle': 'achievement'},
        ),
        const ExperimentVariant(
          name: 'curiosity',
          trafficAllocation: 0.25,
          parameters: {'messageStyle': 'curiosity'},
        ),
        const ExperimentVariant(
          name: 'value',
          trafficAllocation: 0.25,
          parameters: {'messageStyle': 'value'},
        ),
      ],
      targetingCriteria: ['free_users_only'],
    );
  }
  
  /// Pro feature highlight timing experiment
  static Experiment proFeatureHighlightTiming() {
    return Experiment(
      id: 'pro_feature_timing_v1',
      name: 'Pro Feature Highlight Timing',
      description: 'Test when to show Pro feature highlights for maximum conversion',
      status: ExperimentStatus.running,
      variants: [
        const ExperimentVariant(
          name: 'after_2_sessions',
          trafficAllocation: 0.33,
          parameters: {'highlightAfterSessions': 2},
        ),
        const ExperimentVariant(
          name: 'after_3_sessions',
          trafficAllocation: 0.33,
          parameters: {'highlightAfterSessions': 3},
        ),
        const ExperimentVariant(
          name: 'after_5_sessions',
          trafficAllocation: 0.34,
          parameters: {'highlightAfterSessions': 5},
        ),
      ],
      targetingCriteria: ['free_users_only'],
    );
  }
  
  /// Streak reminder frequency experiment
  static Experiment streakReminderFrequency() {
    return Experiment(
      id: 'streak_reminder_freq_v1',
      name: 'Streak Reminder Frequency',
      description: 'Test optimal frequency for streak maintenance reminders',
      status: ExperimentStatus.running,
      variants: [
        const ExperimentVariant(
          name: 'daily',
          trafficAllocation: 0.5,
          parameters: {'reminderFrequency': 'daily'},
        ),
        const ExperimentVariant(
          name: 'every_other_day',
          trafficAllocation: 0.5,
          parameters: {'reminderFrequency': 'every_other_day'},
        ),
      ],
    );
  }
}