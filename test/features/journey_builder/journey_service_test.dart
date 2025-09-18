/// Tests for Journey Service
/// 
/// Validates journey creation, progress tracking, and Pro gating functionality.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/storage/local_storage.dart';
import 'package:mindtrainer/features/journey_builder/domain/mindfulness_journey.dart';
import 'package:mindtrainer/features/journey_builder/application/journey_service.dart';

class MockLocalStorage implements LocalStorage {
  final Map<String, String> _storage = {};
  
  @override
  Future<String?> getString(String key) async => _storage[key];
  
  @override
  Future<void> setString(String key, String value) async => _storage[key] = value;
  
  static Map<String, dynamic>? parseJson(String json) => {};
  static String encodeJson(Object obj) => '{}';
}

class MockProGates implements MindTrainerProGates {
  final bool _isProActive;
  
  MockProGates(this._isProActive);
  
  @override
  bool get isProActive => _isProActive;
  
  @override
  bool get unlimitedDailySessions => _isProActive;
  
  @override
  int get dailySessionLimit => _isProActive ? -1 : 5;
  
  @override
  bool canStartSession(int todaysSessionCount) => _isProActive || todaysSessionCount < 5;
}

void main() {
  group('Journey Service', () {
    late MockLocalStorage mockStorage;
    late JourneyService service;
    
    setUp(() {
      mockStorage = MockLocalStorage();
    });
    
    group('Pro Gating', () {
      test('Free users cannot create custom journeys', () {
        final proGates = MockProGates(false);
        service = JourneyService(proGates, mockStorage);
        
        expect(service.canCreateCustomJourneys, false);
        expect(service.hasUnlimitedJourneys, false);
        expect(service.maxCustomJourneys, 1);
        expect(service.maxStepsPerJourney, 5);
      });
      
      test('Pro users can create unlimited custom journeys', () {
        final proGates = MockProGates(true);
        service = JourneyService(proGates, mockStorage);
        
        expect(service.canCreateCustomJourneys, true);
        expect(service.hasUnlimitedJourneys, true);
        expect(service.maxCustomJourneys, -1); // Unlimited
        expect(service.maxStepsPerJourney, 30);
      });
      
      test('Free users get limited templates', () async {
        final proGates = MockProGates(false);
        service = JourneyService(proGates, mockStorage);
        
        final templates = await service.getAvailableTemplates();
        
        // Should only get free templates
        expect(templates.length, 3);
        expect(templates.every((t) => JourneyTemplates.freeTemplates.contains(t)), true);
      });
      
      test('Pro users get all templates', () async {
        final proGates = MockProGates(true);
        service = JourneyService(proGates, mockStorage);
        
        final templates = await service.getAvailableTemplates();
        
        // Should get all templates
        expect(templates.length, JourneyTemplates.builtInTemplates.length);
      });
    });
    
    group('Template System', () {
      test('Built-in templates are valid', () {
        for (final template in JourneyTemplates.builtInTemplates) {
          expect(template.id.isNotEmpty, true);
          expect(template.title.isNotEmpty, true);
          expect(template.description.isNotEmpty, true);
          expect(template.steps.isNotEmpty, true);
          expect(template.estimatedDays, greaterThan(0));
          expect(template.isTemplate, true);
          expect(template.createdBy, 'system');
          
          // Validate steps
          for (final step in template.steps) {
            expect(step.id.isNotEmpty, true);
            expect(step.title.isNotEmpty, true);
            expect(step.description.isNotEmpty, true);
            expect(step.recommendedDurationMinutes, greaterThan(0));
          }
        }
      });
      
      test('Free templates are correctly categorized', () {
        final freeTemplates = JourneyTemplates.freeTemplates;
        expect(freeTemplates.length, 3);
        
        // Should include beginner-friendly templates
        expect(freeTemplates.any((t) => t.id == 'beginner_foundations'), true);
        expect(freeTemplates.any((t) => t.id == 'stress_relief'), true);
        expect(freeTemplates.any((t) => t.category == JourneyCategory.focusBuilding), true);
      });
      
      test('Pro templates require Pro access', () {
        final proTemplates = JourneyTemplates.proTemplates;
        expect(proTemplates.isNotEmpty, true);
        
        // Should include advanced templates
        expect(proTemplates.any((t) => t.id == '21_day_habit_builder'), true);
      });
    });
    
    group('Custom Journey Creation', () {
      test('Free users cannot create journeys', () async {
        final proGates = MockProGates(false);
        service = JourneyService(proGates, mockStorage);
        
        final journey = await service.createCustomJourney(
          title: 'Test Journey',
          description: 'Test description',
          category: JourneyCategory.custom,
          difficulty: JourneyDifficulty.beginner,
          steps: [
            const JourneyStep(
              id: 'step1',
              title: 'Step 1',
              description: 'First step',
              recommendedDurationMinutes: 10,
            ),
          ],
        );
        
        expect(journey, isNull);
      });
      
      test('Pro users can create valid journeys', () async {
        final proGates = MockProGates(true);
        service = JourneyService(proGates, mockStorage);
        
        final steps = [
          const JourneyStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            recommendedDurationMinutes: 10,
            focusTags: ['breathing'],
          ),
          const JourneyStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Second step',
            recommendedDurationMinutes: 15,
            focusTags: ['mindfulness'],
          ),
        ];
        
        final journey = await service.createCustomJourney(
          title: 'Test Journey',
          description: 'A test journey for validation',
          category: JourneyCategory.stressRelief,
          difficulty: JourneyDifficulty.intermediate,
          steps: steps,
          tags: ['test', 'custom'],
        );
        
        expect(journey, isNotNull);
        expect(journey!.title, 'Test Journey');
        expect(journey.description, 'A test journey for validation');
        expect(journey.category, JourneyCategory.stressRelief);
        expect(journey.difficulty, JourneyDifficulty.intermediate);
        expect(journey.steps.length, 2);
        expect(journey.isTemplate, false);
        expect(journey.createdBy, 'user');
        expect(journey.tags, contains('test'));
        expect(journey.totalEstimatedMinutes, 25); // 10 + 15
        expect(journey.estimatedDays, greaterThanOrEqualTo(2));
      });
      
      test('Journey validation rejects invalid input', () async {
        final proGates = MockProGates(true);
        service = JourneyService(proGates, mockStorage);
        
        // Empty title
        var journey = await service.createCustomJourney(
          title: '',
          description: 'Valid description',
          category: JourneyCategory.custom,
          difficulty: JourneyDifficulty.beginner,
          steps: [
            const JourneyStep(
              id: 'step1',
              title: 'Step 1',
              description: 'Valid step',
              recommendedDurationMinutes: 10,
            ),
          ],
        );
        expect(journey, isNull);
        
        // Empty steps
        journey = await service.createCustomJourney(
          title: 'Valid Title',
          description: 'Valid description',
          category: JourneyCategory.custom,
          difficulty: JourneyDifficulty.beginner,
          steps: [],
        );
        expect(journey, isNull);
      });
      
      test('Free users have step limits', () async {
        final proGates = MockProGates(false);
        service = JourneyService(proGates, mockStorage);
        
        // Even if we create the journey (which should fail), 
        // let's test the limit logic by creating too many steps
        final tooManySteps = List.generate(10, (index) => JourneyStep(
          id: 'step_$index',
          title: 'Step $index',
          description: 'Step description',
          recommendedDurationMinutes: 10,
        ));
        
        final journey = await service.createCustomJourney(
          title: 'Limited Journey',
          description: 'Should fail due to step limit',
          category: JourneyCategory.custom,
          difficulty: JourneyDifficulty.beginner,
          steps: tooManySteps,
        );
        
        // Should fail because free users can't create journeys anyway,
        // but also because it exceeds step limit
        expect(journey, isNull);
      });
    });
    
    group('Journey Management', () {
      late JourneyService proService;
      
      setUp(() {
        final proGates = MockProGates(true);
        proService = JourneyService(proGates, mockStorage);
      });
      
      test('Can retrieve custom journeys', () async {
        // Create a journey first
        final journey = await proService.createCustomJourney(
          title: 'Retrievable Journey',
          description: 'For testing retrieval',
          category: JourneyCategory.focusBuilding,
          difficulty: JourneyDifficulty.beginner,
          steps: [
            const JourneyStep(
              id: 'step1',
              title: 'Test Step',
              description: 'Test description',
              recommendedDurationMinutes: 5,
            ),
          ],
        );
        
        expect(journey, isNotNull);
        
        // Retrieve all custom journeys
        final customJourneys = await proService.getCustomJourneys();
        expect(customJourneys.length, 1);
        expect(customJourneys.first.title, 'Retrievable Journey');
      });
      
      test('Can update custom journeys', () async {
        // Create a journey
        var journey = await proService.createCustomJourney(
          title: 'Original Title',
          description: 'Original description',
          category: JourneyCategory.custom,
          difficulty: JourneyDifficulty.beginner,
          steps: [
            const JourneyStep(
              id: 'step1',
              title: 'Original Step',
              description: 'Original step description',
              recommendedDurationMinutes: 10,
            ),
          ],
        );
        
        expect(journey, isNotNull);
        
        // Update the journey
        final updatedJourney = journey!.copyWith(
          title: 'Updated Title',
          description: 'Updated description',
        );
        
        final success = await proService.updateCustomJourney(updatedJourney);
        expect(success, true);
        
        // Verify update
        final customJourneys = await proService.getCustomJourneys();
        expect(customJourneys.first.title, 'Updated Title');
        expect(customJourneys.first.description, 'Updated description');
      });
      
      test('Can delete custom journeys', () async {
        // Create a journey
        final journey = await proService.createCustomJourney(
          title: 'To Delete',
          description: 'Will be deleted',
          category: JourneyCategory.custom,
          difficulty: JourneyDifficulty.beginner,
          steps: [
            const JourneyStep(
              id: 'step1',
              title: 'Step',
              description: 'Step description',
              recommendedDurationMinutes: 5,
            ),
          ],
        );
        
        expect(journey, isNotNull);
        
        // Delete the journey
        final success = await proService.deleteCustomJourney(journey!.id);
        expect(success, true);
        
        // Verify deletion
        final customJourneys = await proService.getCustomJourneys();
        expect(customJourneys.isEmpty, true);
      });
    });
    
    group('Journey Progress Tracking', () {
      late JourneyService proService;
      
      setUp(() {
        final proGates = MockProGates(true);
        proService = JourneyService(proGates, mockStorage);
      });
      
      test('Can start journey and track progress', () async {
        // Use a template journey
        final templates = await proService.getAvailableTemplates();
        expect(templates.isNotEmpty, true);
        
        final journey = templates.first;
        
        // Start the journey
        final progress = await proService.startJourney(journey.id);
        expect(progress, isNotNull);
        expect(progress!.journeyId, journey.id);
        expect(progress.currentStepIndex, 0);
        expect(progress.completionPercentage, 0.0);
        expect(progress.isCompleted, false);
        expect(progress.stepProgress.length, journey.steps.length);
        
        // Verify it becomes the active journey
        final activeProgress = await proService.getActiveJourneyProgress();
        expect(activeProgress, isNotNull);
        expect(activeProgress!.journeyId, journey.id);
      });
      
      test('Can complete journey steps', () async {
        // Start a journey
        final templates = await proService.getAvailableTemplates();
        final journey = templates.first;
        
        final progress = await proService.startJourney(journey.id);
        expect(progress, isNotNull);
        
        // Complete the first step
        final firstStep = journey.steps.first;
        final success = await proService.completeJourneyStep(
          journeyId: journey.id,
          stepId: firstStep.id,
          actualDurationMinutes: 12,
          sessionRating: 4,
          tagsUsed: ['focused', 'calm'],
          userNote: 'Great first session!',
        );
        
        expect(success, true);
        
        // Verify progress update
        final updatedProgress = await proService.getJourneyProgress(journey.id);
        expect(updatedProgress, isNotNull);
        
        final completedStep = updatedProgress!.stepProgress.first;
        expect(completedStep.isCompleted, true);
        expect(completedStep.actualDurationMinutes, 12);
        expect(completedStep.sessionRating, 4);
        expect(completedStep.tagsUsed, contains('focused'));
        expect(completedStep.userNote, 'Great first session!');
        
        expect(updatedProgress.currentStepIndex, 1); // Should advance
        expect(updatedProgress.completionPercentage, greaterThan(0.0));
      });
      
      test('Journey completion clears active journey', () async {
        // Create a minimal journey for testing completion
        final journey = await proService.createCustomJourney(
          title: 'Completion Test',
          description: 'Single step journey',
          category: JourneyCategory.custom,
          difficulty: JourneyDifficulty.beginner,
          steps: [
            const JourneyStep(
              id: 'only_step',
              title: 'Only Step',
              description: 'The only step',
              recommendedDurationMinutes: 10,
            ),
          ],
        );
        
        expect(journey, isNotNull);
        
        // Start and complete the journey
        final progress = await proService.startJourney(journey!.id);
        expect(progress, isNotNull);
        
        final success = await proService.completeJourneyStep(
          journeyId: journey.id,
          stepId: 'only_step',
          actualDurationMinutes: 15,
          sessionRating: 5,
        );
        
        expect(success, true);
        
        // Verify journey completion
        final completedProgress = await proService.getJourneyProgress(journey.id);
        expect(completedProgress!.isCompleted, true);
        expect(completedProgress.completionPercentage, 100.0);
        
        // Verify no active journey
        final activeProgress = await proService.getActiveJourneyProgress();
        expect(activeProgress, isNull);
      });
    });
    
    group('Journey Domain Objects', () {
      test('JourneyStep serialization works correctly', () {
        const step = JourneyStep(
          id: 'test_step',
          title: 'Test Step',
          description: 'A test step',
          recommendedDurationMinutes: 15,
          focusTags: ['test', 'mindfulness'],
          guidancePrompts: ['Focus on breath', 'Be present'],
          isRequired: true,
        );
        
        final json = step.toJson();
        final restored = JourneyStep.fromJson(json);
        
        expect(restored.id, step.id);
        expect(restored.title, step.title);
        expect(restored.description, step.description);
        expect(restored.recommendedDurationMinutes, step.recommendedDurationMinutes);
        expect(restored.focusTags, step.focusTags);
        expect(restored.guidancePrompts, step.guidancePrompts);
        expect(restored.isRequired, step.isRequired);
      });
      
      test('MindfulnessJourney calculations are correct', () {
        final journey = MindfulnessJourney(
          id: 'test_journey',
          title: 'Test Journey',
          description: 'A test journey',
          category: JourneyCategory.stressRelief,
          difficulty: JourneyDifficulty.intermediate,
          steps: [
            const JourneyStep(
              id: 'step1',
              title: 'Step 1',
              description: 'First step',
              recommendedDurationMinutes: 10,
            ),
            const JourneyStep(
              id: 'step2',
              title: 'Step 2',
              description: 'Second step',
              recommendedDurationMinutes: 20,
            ),
            const JourneyStep(
              id: 'step3',
              title: 'Step 3',
              description: 'Third step',
              recommendedDurationMinutes: 5,
              isRequired: false,
            ),
          ],
          estimatedDays: 3,
          isTemplate: false,
          createdAt: DateTime.now(),
          createdBy: 'user',
        );
        
        expect(journey.totalEstimatedMinutes, 35); // 10 + 20 + 5
        expect(journey.requiredSteps.length, 2); // First two are required
        expect(journey.categoryDescription, 'Stress Relief');
        expect(journey.difficultyDescription, 'Some experience helpful');
      });
      
      test('JourneyProgress tracks completion correctly', () {
        const progress = JourneyProgress(
          journeyId: 'test_journey',
          startedAt: const DateTime(2023, 1, 1),
          stepProgress: [
            JourneyStepProgress(
              stepId: 'step1',
              completedAt: const DateTime(2023, 1, 2),
              actualDurationMinutes: 12,
              sessionRating: 4,
            ),
            JourneyStepProgress(
              stepId: 'step2',
              actualDurationMinutes: 0, // Not completed yet
              sessionRating: 0,
            ),
            JourneyStepProgress(
              stepId: 'step3',
              completedAt: const DateTime(2023, 1, 3),
              actualDurationMinutes: 8,
              sessionRating: 5,
            ),
          ],
          currentStepIndex: 1,
        );
        
        expect(progress.completedStepsCount, 2);
        expect(progress.completionPercentage, closeTo(66.67, 0.1)); // 2/3 * 100
        expect(progress.isCompleted, false);
        expect(progress.currentStepProgress?.stepId, 'step2');
      });
    });
  });
}