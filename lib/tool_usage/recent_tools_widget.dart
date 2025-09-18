import 'package:flutter/material.dart';
import 'tool_usage_service.dart';
import '../favorites/tool_definitions.dart';

/// Widget that displays recently used tools
class RecentToolsSection extends StatelessWidget {
  final Function(String toolId) onToolTap;

  const RecentToolsSection({
    super.key,
    required this.onToolTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ToolUsageService.instance.store,
      builder: (context, _) {
        final usageService = ToolUsageService.instance;
        final recentTools = usageService.getRecentUniqueTools(5);
        
        if (recentTools.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentTools.length,
                  itemBuilder: (context, index) {
                    final toolId = recentTools[index];
                    return RecentToolTile(
                      toolId: toolId,
                      onTap: () => onToolTap(toolId),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact tile for displaying a recent tool
class RecentToolTile extends StatelessWidget {
  final String toolId;
  final VoidCallback onTap;

  const RecentToolTile({
    super.key,
    required this.toolId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tool = ToolRegistry.getTool(toolId);
    if (tool == null) {
      return const SizedBox.shrink();
    }

    // Get last usage time for display
    final lastUsed = ToolUsageService.instance.store.getLastUsageTime(toolId);
    final timeAgo = lastUsed != null ? _formatTimeAgo(lastUsed) : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tool.icon,
                size: 22,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 6),
              Text(
                tool.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (timeAgo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Format time ago in a compact way
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}