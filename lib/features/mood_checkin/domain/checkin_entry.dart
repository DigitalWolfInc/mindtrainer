import 'animal_mood.dart';

class CheckinEntry {
  final DateTime timestamp;
  final AnimalMood animalMood;

  const CheckinEntry({
    required this.timestamp,
    required this.animalMood,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'animalMood': animalMood.toJson(),
  };

  factory CheckinEntry.fromJson(Map<String, dynamic> json) => CheckinEntry(
    timestamp: DateTime.parse(json['timestamp']),
    animalMood: AnimalMood.fromJson(json['animalMood']),
  );
}