class AnimalMood {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const AnimalMood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });

  static const List<AnimalMood> allMoods = [
    AnimalMood(
      id: 'energetic_rabbit',
      name: 'Energetic Rabbit',
      emoji: '🐰',
      description: 'Feeling bouncy and ready to hop into action',
    ),
    AnimalMood(
      id: 'calm_turtle',
      name: 'Calm Turtle',
      emoji: '🐢',
      description: 'Moving at your own peaceful pace',
    ),
    AnimalMood(
      id: 'curious_cat',
      name: 'Curious Cat',
      emoji: '🐱',
      description: 'Interested in exploring what\'s around you',
    ),
    AnimalMood(
      id: 'wise_owl',
      name: 'Wise Owl',
      emoji: '🦉',
      description: 'Feeling thoughtful and observant',
    ),
    AnimalMood(
      id: 'playful_dolphin',
      name: 'Playful Dolphin',
      emoji: '🐬',
      description: 'Ready to dive into something fun',
    ),
    AnimalMood(
      id: 'gentle_deer',
      name: 'Gentle Deer',
      emoji: '🦌',
      description: 'Moving through your day with quiet grace',
    ),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
  };

  factory AnimalMood.fromJson(Map<String, dynamic> json) => AnimalMood(
    id: json['id'],
    name: json['name'],
    emoji: json['emoji'],
    description: json['description'],
  );
}