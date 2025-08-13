/// Pure Dart A/B Testing Framework for MindTrainer
/// 
/// Provides lightweight experimentation without external dependencies.
/// Supports feature toggles, variant testing, and controlled rollouts.

import 'dart:math';
import '../storage/local_storage.dart';

/// Experiment variant definition
class ExperimentVariant {
  final String id;
  final String name;
  final double weight;
  final Map<String, dynamic> config;
  
  const ExperimentVariant({
    required this.id,
    required this.name,
    required this.weight,
    this.config = const {},
  });
}

/// Experiment configuration
class Experiment {
  final String id;
  final String name;
  final List<ExperimentVariant> variants;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool enabled;
  
  const Experiment({
    required this.id,
    required this.name,
    required this.variants,
    this.startDate,
    this.endDate,
    this.enabled = true,
  });
  
  /// Check if experiment is currently active
  bool get isActive {
    if (!enabled) return false;
    
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    return true;
  }
  
  /// Get total weight for normalization
  double get totalWeight => variants.fold(0.0, (sum, v) => sum + v.weight);
}

/// A/B Testing Framework
class ExperimentFramework {
  static const String _storagePrefix = 'experiment_';
  static const String _assignmentsKey = 'user_assignments';
  
  final LocalStorage _storage;
  final Map<String, Experiment> _experiments = {};
  final Map<String, String> _userAssignments = {};
  final Random _random = Random();
  
  ExperimentFramework(this._storage);
  
  /// Initialize framework and load user assignments
  Future<void> initialize() async {
    await _loadUserAssignments();
  }
  
  /// Register an experiment
  void registerExperiment(Experiment experiment) {
    _experiments[experiment.id] = experiment;
  }
  
  /// Get variant for user in experiment
  ExperimentVariant? getVariant(String experimentId) {
    final experiment = _experiments[experimentId];
    if (experiment == null || !experiment.isActive) return null;
    
    // Check existing assignment
    final existingAssignment = _userAssignments[experimentId];
    if (existingAssignment != null) {
      return experiment.variants.firstWhere(
        (v) => v.id == existingAssignment,
        orElse: () => _assignVariant(experiment),
      );
    }
    
    // Assign new variant
    return _assignVariant(experiment);
  }
  
  /// Check if user is in experiment variant
  bool isInVariant(String experimentId, String variantId) {
    final variant = getVariant(experimentId);
    return variant?.id == variantId;
  }
  
  /// Get experiment configuration value
  T? getConfig<T>(String experimentId, String key, [T? defaultValue]) {
    final variant = getVariant(experimentId);
    if (variant == null) return defaultValue;
    
    final value = variant.config[key];
    return value is T ? value : defaultValue;
  }
  
  /// Force assignment to specific variant (for testing)
  Future<void> forceAssignment(String experimentId, String variantId) async {
    _userAssignments[experimentId] = variantId;
    await _saveUserAssignments();
  }
  
  /// Clear all assignments (for testing)
  Future<void> clearAssignments() async {
    _userAssignments.clear();
    await _saveUserAssignments();
  }
  
  /// Get all current assignments for debugging
  Map<String, String> get assignments => Map.unmodifiable(_userAssignments);
  
  /// Assign variant based on weights
  ExperimentVariant _assignVariant(Experiment experiment) {
    final totalWeight = experiment.totalWeight;
    if (totalWeight == 0) return experiment.variants.first;
    
    final randomValue = _random.nextDouble() * totalWeight;
    double cumulative = 0;
    
    for (final variant in experiment.variants) {
      cumulative += variant.weight;
      if (randomValue <= cumulative) {
        _userAssignments[experiment.id] = variant.id;
        _saveUserAssignments();
        return variant;
      }
    }
    
    // Fallback to first variant
    final variant = experiment.variants.first;
    _userAssignments[experiment.id] = variant.id;
    _saveUserAssignments();
    return variant;
  }
  
  /// Load user assignments from storage
  Future<void> _loadUserAssignments() async {
    try {
      final stored = await _storage.getString(_assignmentsKey);
      if (stored != null) {
        final Map<String, dynamic> data = 
            LocalStorage.parseJson(stored) ?? {};
        
        _userAssignments.clear();
        data.forEach((key, value) {
          if (value is String) {
            _userAssignments[key] = value;
          }
        });
      }
    } catch (e) {
      // Ignore errors, start fresh
    }
  }
  
  /// Save user assignments to storage
  Future<void> _saveUserAssignments() async {
    try {
      await _storage.setString(
        _assignmentsKey, 
        LocalStorage.encodeJson(_userAssignments),
      );
    } catch (e) {
      // Ignore storage errors
    }
  }
}

/// Feature flags system built on experiments
class FeatureFlags {
  final ExperimentFramework _framework;
  
  FeatureFlags(this._framework);
  
  /// Check if feature is enabled
  bool isEnabled(String featureId) {
    return _framework.isInVariant(featureId, 'enabled');
  }
  
  /// Get feature configuration
  T? getFeatureConfig<T>(String featureId, String key, [T? defaultValue]) {
    return _framework.getConfig<T>(featureId, key, defaultValue);
  }
  
  /// Create simple feature toggle experiment
  void registerFeatureToggle(
    String featureId, 
    String name, {
    double enabledPercentage = 50.0,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final experiment = Experiment(
      id: featureId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      variants: [
        ExperimentVariant(
          id: 'enabled',
          name: 'Enabled',
          weight: enabledPercentage,
        ),
        ExperimentVariant(
          id: 'disabled', 
          name: 'Disabled',
          weight: 100.0 - enabledPercentage,
        ),
      ],
    );
    
    _framework.registerExperiment(experiment);
  }
}

/// Common experiments for MindTrainer
class MindTrainerExperiments {
  static const String upsellMessageStyle = 'upsell_message_style';
  static const String streakReminderTiming = 'streak_reminder_timing';
  static const String onboardingFlow = 'onboarding_flow';
  static const String proFeaturePreview = 'pro_feature_preview';
  static const String inactivitySummary = 'inactivity_summary';
  
  /// Register all MindTrainer experiments
  static void registerAll(ExperimentFramework framework) {
    // Upsell message style variants
    framework.registerExperiment(Experiment(
      id: upsellMessageStyle,
      name: 'Upsell Message Style',
      variants: [
        ExperimentVariant(
          id: 'supportive',
          name: 'Supportive',
          weight: 33.3,
          config: {
            'tone': 'supportive',
            'focus': 'journey',
            'cta': 'Continue your growth',
          },
        ),
        ExperimentVariant(
          id: 'achievement',
          name: 'Achievement-Based',
          weight: 33.3,
          config: {
            'tone': 'celebration',
            'focus': 'accomplishment',
            'cta': 'Unlock your potential',
          },
        ),
        ExperimentVariant(
          id: 'curiosity',
          name: 'Curiosity-Based',
          weight: 33.4,
          config: {
            'tone': 'intriguing',
            'focus': 'discovery',
            'cta': 'Discover more',
          },
        ),
      ],
    ));
    
    // Streak reminder timing
    framework.registerExperiment(Experiment(
      id: streakReminderTiming,
      name: 'Streak Reminder Timing',
      variants: [
        ExperimentVariant(
          id: 'early_evening',
          name: 'Early Evening',
          weight: 50.0,
          config: {'hour': 18, 'message': 'Keep your streak alive'},
        ),
        ExperimentVariant(
          id: 'late_evening',
          name: 'Late Evening', 
          weight: 50.0,
          config: {'hour': 20, 'message': 'End the day mindfully'},
        ),
      ],
    ));
    
    // Pro feature preview style
    framework.registerExperiment(Experiment(
      id: proFeaturePreview,
      name: 'Pro Feature Preview',
      variants: [
        ExperimentVariant(
          id: 'teaser',
          name: 'Teaser Preview',
          weight: 50.0,
          config: {'preview_type': 'teaser', 'blur_level': 0.7},
        ),
        ExperimentVariant(
          id: 'sample',
          name: 'Sample Preview',
          weight: 50.0,
          config: {'preview_type': 'sample', 'sample_count': 3},
        ),
      ],
    ));
  }
}