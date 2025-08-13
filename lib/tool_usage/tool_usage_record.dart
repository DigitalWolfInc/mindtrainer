/// A record of tool usage with timestamp
class ToolUsageRecord {
  final String toolId;
  final DateTime timestamp;

  const ToolUsageRecord({
    required this.toolId,
    required this.timestamp,
  });

  /// Create from JSON
  factory ToolUsageRecord.fromJson(Map<String, dynamic> json) {
    return ToolUsageRecord(
      toolId: json['toolId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'toolId': toolId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a new usage record with current timestamp
  factory ToolUsageRecord.now(String toolId) {
    return ToolUsageRecord(
      toolId: toolId,
      timestamp: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolUsageRecord &&
        other.toolId == toolId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(toolId, timestamp);

  @override
  String toString() {
    return 'ToolUsageRecord(toolId: $toolId, timestamp: $timestamp)';
  }
}