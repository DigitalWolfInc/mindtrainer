import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/mood_checkin/domain/animal_mood.dart';
import 'package:mindtrainer/features/mood_checkin/domain/checkin_entry.dart';

void main() {
  group('AnimalMood', () {
    test('should have at least 5 predefined moods', () {
      expect(AnimalMood.allMoods.length, greaterThanOrEqualTo(5));
    });

    test('should serialize and deserialize correctly', () {
      const mood = AnimalMood(
        id: 'test_animal',
        name: 'Test Animal',
        emoji: '🐾',
        description: 'Test description',
      );

      final json = mood.toJson();
      final deserializedMood = AnimalMood.fromJson(json);

      expect(deserializedMood.id, mood.id);
      expect(deserializedMood.name, mood.name);
      expect(deserializedMood.emoji, mood.emoji);
      expect(deserializedMood.description, mood.description);
    });
  });

  group('CheckinEntry', () {
    test('should serialize and deserialize correctly', () {
      final timestamp = DateTime.now();
      const mood = AnimalMood(
        id: 'test_animal',
        name: 'Test Animal',
        emoji: '🐾',
        description: 'Test description',
      );

      final entry = CheckinEntry(
        timestamp: timestamp,
        animalMood: mood,
      );

      final json = entry.toJson();
      final deserializedEntry = CheckinEntry.fromJson(json);

      expect(deserializedEntry.timestamp, timestamp);
      expect(deserializedEntry.animalMood.id, mood.id);
    });
  });
}