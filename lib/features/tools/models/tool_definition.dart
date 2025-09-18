/// Tool execution mode
enum ToolMode { quick, guided }

/// Tool difficulty/complexity level
enum ToolLevel { beginner, intermediate, advanced }

/// Tool category for organization
enum ToolCategory { breathing, grounding, reflection, movement, sleep }

/// Definition of a mindfulness tool
class ToolDefinition {
  final String id;
  final String title;
  final String description;
  final ToolCategory category;
  final Duration quickDuration;
  final Duration guidedDuration;
  final ToolLevel level;
  final bool isProOnly;
  final List<String> tags;
  
  const ToolDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.quickDuration,
    required this.guidedDuration,
    this.level = ToolLevel.beginner,
    this.isProOnly = false,
    this.tags = const [],
  });
  
  /// Get duration for specified mode
  Duration getDuration(ToolMode mode) {
    switch (mode) {
      case ToolMode.quick:
        return quickDuration;
      case ToolMode.guided:
        return guidedDuration;
    }
  }
  
  /// Format duration for display
  String formatDuration(ToolMode mode) {
    final duration = getDuration(mode);
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m';
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() => 'ToolDefinition(id: $id, title: $title)';
}

/// Registry of core tools
class CoreToolRegistry {
  static const List<ToolDefinition> tools = [
    ToolDefinition(
      id: 'calm-breath',
      title: 'Calm Breath',
      description: 'Simple breathing to center yourself',
      category: ToolCategory.breathing,
      quickDuration: Duration(minutes: 1),
      guidedDuration: Duration(minutes: 3),
      tags: ['anxiety', 'stress', 'quick'],
    ),
    
    ToolDefinition(
      id: 'ground-orient-5-4-3-2-1',
      title: 'Ground & Orient',
      description: '5-4-3-2-1 sensory grounding technique',
      category: ToolCategory.grounding,
      quickDuration: Duration(minutes: 2),
      guidedDuration: Duration(minutes: 5),
      tags: ['grounding', 'present', 'senses'],
    ),
    
    ToolDefinition(
      id: 'perspective-flip',
      title: 'Perspective Flip',
      description: 'Reframe challenges from different angles',
      category: ToolCategory.reflection,
      quickDuration: Duration(minutes: 3),
      guidedDuration: Duration(minutes: 8),
      tags: ['stuck', 'reframe', 'perspective'],
    ),
    
    ToolDefinition(
      id: 'tiny-next-step',
      title: 'Tiny Next Step',
      description: 'Find the smallest step forward',
      category: ToolCategory.reflection,
      quickDuration: Duration(minutes: 1),
      guidedDuration: Duration(minutes: 3),
      tags: ['motivation', 'action', 'momentum'],
    ),
    
    ToolDefinition(
      id: 'brain-dump-park',
      title: 'Brain Dump → Park It',
      description: 'Clear mental clutter by writing it down',
      category: ToolCategory.reflection,
      quickDuration: Duration(minutes: 3),
      guidedDuration: Duration(minutes: 7),
      tags: ['overwhelm', 'clarity', 'organize'],
    ),
    
    ToolDefinition(
      id: 'wind-down-timer',
      title: 'Wind-Down Timer',
      description: 'Gentle transition toward rest',
      category: ToolCategory.sleep,
      quickDuration: Duration(minutes: 10),
      guidedDuration: Duration(minutes: 20),
      tags: ['sleep', 'evening', 'rest'],
    ),
    
    // PRO example
    ToolDefinition(
      id: 'sleep-sounds-pro',
      title: 'Sleep Sounds',
      description: 'Curated soundscapes for deep rest',
      category: ToolCategory.sleep,
      quickDuration: Duration(minutes: 15),
      guidedDuration: Duration(minutes: 45),
      isProOnly: true,
      tags: ['sleep', 'sounds', 'premium'],
    ),
  ];
  
  /// Get tool by ID
  static ToolDefinition? findById(String id) {
    try {
      return tools.firstWhere((tool) => tool.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get tools by category
  static List<ToolDefinition> byCategory(ToolCategory category) {
    return tools.where((tool) => tool.category == category).toList();
  }
  
  /// Get free tools only
  static List<ToolDefinition> get freeTools {
    return tools.where((tool) => !tool.isProOnly).toList();
  }
  
  /// Get PRO tools only
  static List<ToolDefinition> get proTools {
    return tools.where((tool) => tool.isProOnly).toList();
  }
}