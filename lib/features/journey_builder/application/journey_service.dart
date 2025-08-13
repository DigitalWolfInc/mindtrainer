/// Journey Service for MindTrainer Pro
/// 
/// Manages custom journeys, templates, and progress tracking.

import 'dart:math';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/session_tags.dart';
import '../domain/mindfulness_journey.dart';

/// Service for managing mindfulness journeys
class JourneyService {
  static const String _journeysKey = 'custom_journeys';
  static const String _progressKey = 'journey_progress';
  static const String _activeJourneyKey = 'active_journey_id';
  static const int _maxFreeCustomJourneys = 1;
  static const int _maxFreeJourneySteps = 5;
  
  final MindTrainerProGates _proGates;
  final LocalStorage _storage;
  
  JourneyService(this._proGates, this._storage);
  
  /// Check if user can access journey building
  bool get canCreateCustomJourneys => _proGates.isProActive;
  
  /// Check if user can access unlimited journeys
  bool get hasUnlimitedJourneys => _proGates.isProActive;
  
  /// Get maximum number of custom journeys for current user
  int get maxCustomJourneys => _proGates.isProActive ? -1 : _maxFreeCustomJourneys;
  
  /// Get maximum steps per journey for current user
  int get maxStepsPerJourney => _proGates.isProActive ? 30 : _maxFreeJourneySteps;
  
  /// Get all available journey templates
  Future<List<MindfulnessJourney>> getAvailableTemplates() async {
    final templates = <MindfulnessJourney>[];
    
    // Add free templates (always available)
    templates.addAll(JourneyTemplates.freeTemplates);
    
    // Add Pro templates if user has Pro
    if (_proGates.isProActive) {
      templates.addAll(JourneyTemplates.proTemplates);
    }
    
    return templates;
  }
  
  /// Get user's custom journeys
  Future<List<MindfulnessJourney>> getCustomJourneys() async {
    try {
      final stored = await _storage.getString(_journeysKey);
      if (stored != null) {
        final List<dynamic> data = LocalStorage.parseJson(stored) ?? [];
        return data
            .map((json) => MindfulnessJourney.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Ignore errors, return empty list
    }
    
    return [];
  }
  
  /// Get all journeys (templates + custom)
  Future<List<MindfulnessJourney>> getAllJourneys() async {
    final templates = await getAvailableTemplates();
    final custom = await getCustomJourneys();
    
    return [...templates, ...custom];
  }
  
  /// Create a new custom journey
  Future<MindfulnessJourney?> createCustomJourney({
    required String title,
    required String description,
    required JourneyCategory category,
    required JourneyDifficulty difficulty,
    required List<JourneyStep> steps,
    List<String> tags = const [],
  }) async {
    if (!canCreateCustomJourneys) {
      return null; // Pro feature required
    }
    
    // Check limits for free users
    if (!_proGates.isProActive) {
      final existingJourneys = await getCustomJourneys();
      if (existingJourneys.length >= _maxFreeCustomJourneys) {
        return null; // Free user limit reached
      }
      
      if (steps.length > _maxFreeJourneySteps) {
        return null; // Step limit exceeded
      }
    }
    
    // Validate inputs
    if (title.trim().isEmpty || steps.isEmpty) {
      return null; // Invalid input
    }
    
    final journey = MindfulnessJourney(
      id: _generateJourneyId(),
      title: title.trim(),
      description: description.trim(),
      category: category,
      difficulty: difficulty,
      steps: steps,
      estimatedDays: _calculateEstimatedDays(steps),
      isTemplate: false,
      isPublic: false,
      createdAt: DateTime.now(),
      createdBy: 'user', // In real app, would be actual user ID
      tags: tags,
    );
    
    // Save journey
    final success = await _saveCustomJourney(journey);
    return success ? journey : null;
  }
  
  /// Update existing custom journey
  Future<bool> updateCustomJourney(MindfulnessJourney journey) async {
    if (!canCreateCustomJourneys || journey.isTemplate) {
      return false; // Can't update templates or without Pro
    }
    
    // Check step limits for free users
    if (!_proGates.isProActive && journey.steps.length > _maxFreeJourneySteps) {
      return false;
    }
    
    final updatedJourney = journey.copyWith(
      lastModifiedAt: DateTime.now(),
    );
    
    return await _updateCustomJourney(updatedJourney);
  }
  
  /// Delete custom journey
  Future<bool> deleteCustomJourney(String journeyId) async {
    if (!canCreateCustomJourneys) {
      return false;
    }
    
    try {
      final journeys = await getCustomJourneys();
      final updatedJourneys = journeys.where((j) => j.id != journeyId).toList();
      
      final jsonJourneys = updatedJourneys.map((j) => j.toJson()).toList();
      await _storage.setString(_journeysKey, LocalStorage.encodeJson(jsonJourneys));
      
      // Also delete any progress for this journey
      await _deleteJourneyProgress(journeyId);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Start a journey
  Future<JourneyProgress?> startJourney(String journeyId) async {
    final allJourneys = await getAllJourneys();
    final journey = allJourneys.where((j) => j.id == journeyId).firstOrNull;
    
    if (journey == null) {
      return null; // Journey not found
    }
    
    // Check Pro access for Pro-only templates
    if (journey.isTemplate && JourneyTemplates.proTemplates.any((t) => t.id == journey.id)) {
      if (!_proGates.isProActive) {
        return null; // Pro feature required
      }
    }
    
    // Initialize progress
    final progress = JourneyProgress(
      journeyId: journeyId,
      startedAt: DateTime.now(),
      stepProgress: journey.steps
          .map((step) => JourneyStepProgress(stepId: step.id))
          .toList(),
      currentStepIndex: 0,
    );
    
    // Save progress
    await _saveJourneyProgress(progress);
    
    // Set as active journey
    await _storage.setString(_activeJourneyKey, journeyId);
    
    return progress;
  }
  
  /// Get journey progress
  Future<JourneyProgress?> getJourneyProgress(String journeyId) async {
    try {
      final stored = await _storage.getString('${_progressKey}_$journeyId');
      if (stored != null) {
        final data = LocalStorage.parseJson(stored);
        if (data != null) {
          return JourneyProgress.fromJson(data);
        }
      }
    } catch (e) {
      // Ignore errors
    }
    
    return null;
  }
  
  /// Get active journey progress
  Future<JourneyProgress?> getActiveJourneyProgress() async {
    try {
      final activeJourneyId = await _storage.getString(_activeJourneyKey);
      if (activeJourneyId != null) {
        return await getJourneyProgress(activeJourneyId);
      }
    } catch (e) {
      // Ignore errors
    }
    
    return null;
  }
  
  /// Complete a journey step
  Future<bool> completeJourneyStep({
    required String journeyId,
    required String stepId,
    required int actualDurationMinutes,
    int sessionRating = 5,
    List<String> tagsUsed = const [],
    String? userNote,
  }) async {
    final progress = await getJourneyProgress(journeyId);
    if (progress == null) {
      return false;
    }
    
    // Find and update the step progress
    final stepIndex = progress.stepProgress.indexWhere((p) => p.stepId == stepId);
    if (stepIndex == -1) {
      return false;
    }
    
    final updatedStepProgress = [...progress.stepProgress];
    updatedStepProgress[stepIndex] = JourneyStepProgress(
      stepId: stepId,
      completedAt: DateTime.now(),
      actualDurationMinutes: actualDurationMinutes,
      sessionRating: sessionRating,
      tagsUsed: tagsUsed,
      userNote: userNote,
    );
    
    // Update current step index if this was the current step
    var newCurrentIndex = progress.currentStepIndex;
    if (stepIndex == progress.currentStepIndex) {
      newCurrentIndex = (stepIndex + 1).clamp(0, progress.stepProgress.length);
    }
    
    // Check if journey is now complete
    final allCompleted = updatedStepProgress.every((p) => p.isCompleted);
    final completedAt = allCompleted ? DateTime.now() : null;
    
    final updatedProgress = JourneyProgress(
      journeyId: journeyId,
      startedAt: progress.startedAt,
      stepProgress: updatedStepProgress,
      currentStepIndex: newCurrentIndex,
      completedAt: completedAt,
      userMetadata: progress.userMetadata,
    );
    
    await _saveJourneyProgress(updatedProgress);
    
    // If journey completed, clear active journey
    if (allCompleted) {
      await _storage.setString(_activeJourneyKey, '');
    }
    
    return true;
  }
  
  /// Get journey analytics
  Future<Map<String, dynamic>> getJourneyAnalytics() async {
    try {
      final allJourneys = await getAllJourneys();
      final progressList = <JourneyProgress>[];
      
      // Load progress for all journeys
      for (final journey in allJourneys) {
        final progress = await getJourneyProgress(journey.id);
        if (progress != null) {
          progressList.add(progress);
        }
      }
      
      // Calculate statistics
      final completedJourneys = progressList.where((p) => p.isCompleted).length;
      final inProgressJourneys = progressList.where((p) => !p.isCompleted && p.stepProgress.any((s) => s.isCompleted)).length;
      final totalStepsCompleted = progressList.fold<int>(0, (sum, p) => sum + p.completedStepsCount);
      
      final averageCompletionRate = progressList.isNotEmpty
          ? progressList.map((p) => p.completionPercentage).reduce((a, b) => a + b) / progressList.length
          : 0.0;
      
      // Most popular categories
      final categoryStats = <JourneyCategory, int>{};
      for (final journey in allJourneys) {
        final progress = progressList.where((p) => p.journeyId == journey.id).firstOrNull;
        if (progress != null && progress.completedStepsCount > 0) {
          categoryStats[journey.category] = (categoryStats[journey.category] ?? 0) + 1;
        }
      }
      
      return {
        'total_journeys': allJourneys.length,
        'completed_journeys': completedJourneys,
        'in_progress_journeys': inProgressJourneys,
        'total_steps_completed': totalStepsCompleted,
        'average_completion_rate': averageCompletionRate,
        'most_popular_category': categoryStats.isNotEmpty
            ? categoryStats.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString()
            : null,
        'category_stats': categoryStats.map((k, v) => MapEntry(k.toString(), v)),
      };
    } catch (e) {
      return {'error': 'Failed to load analytics: $e'};
    }
  }
  
  /// Create journey from template
  Future<MindfulnessJourney?> createJourneyFromTemplate(
    String templateId, {
    String? customTitle,
    List<JourneyStep>? additionalSteps,
  }) async {
    if (!canCreateCustomJourneys) {
      return null;
    }
    
    final templates = await getAvailableTemplates();
    final template = templates.where((t) => t.id == templateId).firstOrNull;
    
    if (template == null) {
      return null;
    }
    
    final steps = [...template.steps];
    if (additionalSteps != null) {
      steps.addAll(additionalSteps);
    }
    
    // Check step limits
    if (!_proGates.isProActive && steps.length > _maxFreeJourneySteps) {
      return null;
    }
    
    return await createCustomJourney(
      title: customTitle ?? '${template.title} (Custom)',
      description: template.description,
      category: template.category,
      difficulty: template.difficulty,
      steps: steps,
      tags: [...template.tags, 'custom_from_template'],
    );
  }
  
  /// Generate unique journey ID
  String _generateJourneyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'custom_journey_${timestamp}_$random';
  }
  
  /// Calculate estimated days for a journey
  int _calculateEstimatedDays(List<JourneyStep> steps) {
    // Simple heuristic: assume 1 step per day, with minimum of steps.length
    // and maximum based on total duration
    final totalMinutes = steps.fold(0, (sum, step) => sum + step.recommendedDurationMinutes);
    
    // If total time is very long, spread over more days
    if (totalMinutes > 200) return (steps.length * 1.5).round();
    if (totalMinutes > 100) return (steps.length * 1.2).round();
    
    return max(steps.length, 3); // Minimum 3 days
  }
  
  /// Save custom journey to storage
  Future<bool> _saveCustomJourney(MindfulnessJourney journey) async {
    try {
      final journeys = await getCustomJourneys();
      journeys.add(journey);
      
      final jsonJourneys = journeys.map((j) => j.toJson()).toList();
      await _storage.setString(_journeysKey, LocalStorage.encodeJson(jsonJourneys));
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Update existing custom journey
  Future<bool> _updateCustomJourney(MindfulnessJourney journey) async {
    try {
      final journeys = await getCustomJourneys();
      final index = journeys.indexWhere((j) => j.id == journey.id);
      
      if (index != -1) {
        journeys[index] = journey;
        
        final jsonJourneys = journeys.map((j) => j.toJson()).toList();
        await _storage.setString(_journeysKey, LocalStorage.encodeJson(jsonJourneys));
        
        return true;
      }
    } catch (e) {
      // Ignore errors
    }
    
    return false;
  }
  
  /// Save journey progress
  Future<void> _saveJourneyProgress(JourneyProgress progress) async {
    try {
      await _storage.setString(
        '${_progressKey}_${progress.journeyId}',
        LocalStorage.encodeJson(progress.toJson()),
      );
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Delete journey progress
  Future<void> _deleteJourneyProgress(String journeyId) async {
    try {
      await _storage.setString('${_progressKey}_$journeyId', '');
    } catch (e) {
      // Ignore errors
    }
  }
}

// Extension to add firstOrNull method
extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}