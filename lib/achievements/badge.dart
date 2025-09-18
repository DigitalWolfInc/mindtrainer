class Badge {
  final String id;
  final String title;
  final String description;
  final int tier;
  final DateTime unlockedAt;
  final Map<String, dynamic>? meta;
  final String? category;

  const Badge._({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.unlockedAt,
    this.meta,
    this.category,
  });

  factory Badge.create({
    required String id,
    required String title,
    required String description,
    int tier = 1,
    DateTime? unlockedAt,
    Map<String, dynamic>? meta,
    String? category,
  }) {
    return Badge._(
      id: id,
      title: title,
      description: description,
      tier: tier,
      unlockedAt: unlockedAt ?? DateTime.now(),
      meta: meta,
      category: category,
    );
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge._(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tier: json['tier'] as int? ?? 1,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      meta: json['meta'] as Map<String, dynamic>?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tier': tier,
      'unlockedAt': unlockedAt.toIso8601String(),
      'meta': meta,
      'category': category,
    };
  }

  Badge copyWith({
    String? id,
    String? title,
    String? description,
    int? tier,
    DateTime? unlockedAt,
    Map<String, dynamic>? meta,
    String? category,
  }) {
    return Badge._(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      meta: meta ?? this.meta,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Badge &&
            runtimeType == other.runtimeType &&
            id == other.id; // Equality by id only
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Badge(id: $id, title: $title, tier: $tier, unlockedAt: ${unlockedAt.toIso8601String()})';
  }
}