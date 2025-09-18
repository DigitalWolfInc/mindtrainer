import 'tool_usage_store.dart';
import 'tool_usage_record.dart';
import '../core/analytics/engagement_analytics.dart';

/// Service for managing tool usage tracking
/// Provides high-level API for recording and retrieving tool usage
class ToolUsageService {
  static ToolUsageService? _instance;
  final ToolUsageStore _store;
  final EngagementAnalytics? _analyticsService;

  ToolUsageService._(this._store, [this._analyticsService]);

  /// Singleton instance
  static ToolUsageService get instance {
    _instance ??= ToolUsageService._(ToolUsageStore.instance);
    return _instance!;
  }

  /// Create instance with analytics service for production use
  static ToolUsageService createWithAnalytics(EngagementAnalytics analyticsService) {
    return ToolUsageService._(ToolUsageStore.instance, analyticsService);
  }

  /// For testing - reset the singleton
  static void resetInstance() {
    _instance = null;
    // Note: ToolUsageStore.resetInstance() should be called separately in tests
  }

  /// Initialize the service
  Future<void> init() async {
    await _store.init();
  }

  /// Record usage of a tool with current timestamp
  Future<void> recordUsage(String toolId) async {
    if (toolId.isEmpty) return; // Ignore empty tool IDs
    
    await _store.recordUsage(toolId);
    
    // Route to analytics service if available
    _analyticsService?.trackEvent('tool_usage', {
      'tool_id': toolId,
      'source': 'tool_selection',
    });
  }

  /// Get recent usage records with timestamps
  List<ToolUsageRecord> getRecentUsage(int limit) {
    return _store.getRecentUsage(limit);
  }

  /// Get recent unique tool IDs (most recent first, no duplicates)
  List<String> getRecentUniqueTools(int limit) {
    return _store.getRecentUniqueTools(limit);
  }

  /// Get usage statistics for a specific tool
  ToolUsageStats getToolStats(String toolId) {
    final usageCount = _store.getUsageCount(toolId);
    final lastUsed = _store.getLastUsageTime(toolId);
    
    return ToolUsageStats(
      toolId: toolId,
      usageCount: usageCount,
      lastUsed: lastUsed,
    );
  }

  /// Get overall usage statistics
  OverallUsageStats getOverallStats() {
    final totalUsage = _store.totalUsageCount;
    final uniqueTools = _store.getAllUsage()
        .map((record) => record.toolId)
        .toSet()
        .length;
    
    final lastUsed = _store.getAllUsage().isNotEmpty 
        ? _store.getAllUsage().first.timestamp
        : null;
    
    return OverallUsageStats(
      totalUsageCount: totalUsage,
      uniqueToolsUsed: uniqueTools,
      lastActivity: lastUsed,
    );
  }

  /// Check if there is any usage history
  bool get hasUsageHistory => _store.hasUsageHistory;

  /// Clear all usage history
  Future<void> clearHistory() async {
    await _store.clearHistory();
  }

  /// Get the store instance for direct access (for UI listening)
  ToolUsageStore get store => _store;
}

/// Statistics for a specific tool
class ToolUsageStats {
  final String toolId;
  final int usageCount;
  final DateTime? lastUsed;

  const ToolUsageStats({
    required this.toolId,
    required this.usageCount,
    this.lastUsed,
  });

  @override
  String toString() {
    return 'ToolUsageStats(toolId: $toolId, count: $usageCount, lastUsed: $lastUsed)';
  }
}

/// Overall usage statistics
class OverallUsageStats {
  final int totalUsageCount;
  final int uniqueToolsUsed;
  final DateTime? lastActivity;

  const OverallUsageStats({
    required this.totalUsageCount,
    required this.uniqueToolsUsed,
    this.lastActivity,
  });

  @override
  String toString() {
    return 'OverallUsageStats(total: $totalUsageCount, unique: $uniqueToolsUsed, lastActivity: $lastActivity)';
  }
}