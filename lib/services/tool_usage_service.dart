import '../data/tool_usage_store.dart';

/// Thin wrapper service for tool usage tracking
class ToolUsageService {
  static ToolUsageService? _instance;
  final ToolUsageStore _store;

  ToolUsageService._(this._store);

  static ToolUsageService get instance {
    _instance ??= ToolUsageService._(ToolUsageStore.instance);
    return _instance!;
  }

  /// For testing - reset the singleton
  static void resetInstance() {
    _instance = null;
  }

  /// Record tool usage (guards against null/unknown toolId)
  Future<void> recordUsage(String? toolId) async {
    if (toolId == null || toolId.trim().isEmpty) return;
    await _store.record(toolId);
  }

  /// Get recent tool usage entries
  List<ToolUsage> getRecent(int limit) {
    return _store.recent(limit: limit);
  }

  /// Initialize the service (loads data)
  Future<void> init() async {
    await _store.load();
  }
}