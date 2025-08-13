import 'badge.dart';

class AchievementsSnapshot {
  final Map<String, Badge> unlocked;
  final DateTime updatedAt;

  const AchievementsSnapshot._({
    required this.unlocked,
    required this.updatedAt,
  });

  factory AchievementsSnapshot.empty([DateTime? updatedAt]) {
    return AchievementsSnapshot._(
      unlocked: const {},
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory AchievementsSnapshot.create({
    required Map<String, Badge> unlocked,
    DateTime? updatedAt,
  }) {
    return AchievementsSnapshot._(
      unlocked: Map.unmodifiable(unlocked),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory AchievementsSnapshot.fromJson(Map<String, dynamic> json) {
    final unlockedJson = json['unlocked'] as Map<String, dynamic>? ?? {};
    final unlocked = <String, Badge>{};

    for (final entry in unlockedJson.entries) {
      try {
        final badge = Badge.fromJson(entry.value as Map<String, dynamic>);
        unlocked[entry.key] = badge;
      } catch (e) {
        // Skip malformed badge entries
      }
    }

    return AchievementsSnapshot._(
      unlocked: unlocked,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final unlockedJson = <String, dynamic>{};
    for (final entry in unlocked.entries) {
      unlockedJson[entry.key] = entry.value.toJson();
    }

    return {
      'unlocked': unlockedJson,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Derived properties
  bool has(String id) => unlocked.containsKey(id);

  int get count => unlocked.length;

  List<Badge> get badges => unlocked.values.toList();

  List<Badge> get badgesSortedByUnlockedDate {
    final list = badges.toList();
    list.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt)); // Newest first
    return list;
  }

  // Create new snapshot with added/updated badges
  AchievementsSnapshot withBadges(Iterable<Badge> badges, [DateTime? updatedAt]) {
    final newUnlocked = Map<String, Badge>.from(unlocked);
    for (final badge in badges) {
      newUnlocked[badge.id] = badge;
    }

    return AchievementsSnapshot._(
      unlocked: newUnlocked,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Create new snapshot replacing all data
  AchievementsSnapshot replaced(Map<String, Badge> newUnlocked, [DateTime? updatedAt]) {
    return AchievementsSnapshot._(
      unlocked: Map.unmodifiable(newUnlocked),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AchievementsSnapshot &&
            runtimeType == other.runtimeType &&
            _mapEquals(unlocked, other.unlocked) &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return unlocked.hashCode ^ updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'AchievementsSnapshot(count: $count, updatedAt: ${updatedAt.toIso8601String()})';
  }

  // Helper for map equality comparison
  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}