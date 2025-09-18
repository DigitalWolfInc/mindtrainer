import 'dart:convert';

/// Journal entry types supported
enum JournalType { text, voice, photo }

/// A journal entry with optional media
class JournalEntry {
  final String id;
  final JournalType type;
  final String? text;
  final String? mediaPath;
  final List<String> tags;
  final DateTime timestamp;
  
  const JournalEntry({
    required this.id,
    required this.type,
    this.text,
    this.mediaPath,
    required this.tags,
    required this.timestamp,
  });
  
  /// Create text entry
  factory JournalEntry.text({
    required String id,
    required String text,
    List<String> tags = const [],
    DateTime? timestamp,
  }) {
    return JournalEntry(
      id: id,
      type: JournalType.text,
      text: text,
      tags: tags,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
  
  /// Create voice entry
  factory JournalEntry.voice({
    required String id,
    required String mediaPath,
    String? text,
    List<String> tags = const [],
    DateTime? timestamp,
  }) {
    return JournalEntry(
      id: id,
      type: JournalType.voice,
      text: text,
      mediaPath: mediaPath,
      tags: tags,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
  
  /// Create photo entry
  factory JournalEntry.photo({
    required String id,
    required String mediaPath,
    String? text,
    List<String> tags = const [],
    DateTime? timestamp,
  }) {
    return JournalEntry(
      id: id,
      type: JournalType.photo,
      text: text,
      mediaPath: mediaPath,
      tags: tags,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
  
  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'mediaPath': mediaPath,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// Deserialize from JSON
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      type: JournalType.values.byName(json['type'] as String),
      text: json['text'] as String?,
      mediaPath: json['mediaPath'] as String?,
      tags: List<String>.from(json['tags'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  /// Copy with modifications
  JournalEntry copyWith({
    String? id,
    JournalType? type,
    String? text,
    String? mediaPath,
    List<String>? tags,
    DateTime? timestamp,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaPath: mediaPath ?? this.mediaPath,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() => 'JournalEntry(id: $id, type: $type, timestamp: $timestamp)';
}