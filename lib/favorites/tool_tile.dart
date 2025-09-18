import 'package:flutter/material.dart';
import 'favorite_tools_store.dart';
import 'tool_definitions.dart';

/// Time badge widget for displaying estimated duration
class _TimeBadge extends StatelessWidget {
  final Duration duration;
  final double fontSize;

  const _TimeBadge({
    required this.duration,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    return Text(
      '• ${minutes}m',
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// A tool tile that includes favorite functionality
class ToolTile extends StatelessWidget {
  final String toolId;
  final VoidCallback onTap;
  final Widget? trailing; // For Pro badges, etc.
  final ButtonStyle? style;

  const ToolTile({
    super.key,
    required this.toolId,
    required this.onTap,
    this.trailing,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final tool = ToolRegistry.getTool(toolId);
    if (tool == null) {
      // Fallback for unknown tool
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: FavoriteToolsStore.instance,
      builder: (context, _) {
        final store = FavoriteToolsStore.instance;
        final isFavorite = store.isFavorite(toolId);

        return Row(
          children: [
            // Favorite toggle button
            IconButton(
              onPressed: () {
                store.toggleFavorite(toolId);
              },
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey[600],
                size: 20,
              ),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
            const SizedBox(width: 8),
            
            // Main tool button
            Expanded(
              child: ElevatedButton(
                style: style ?? ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tool.icon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tool.title),
                          if (tool.estimated != null)
                            _TimeBadge(duration: tool.estimated!),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact tool tile for favorites section
class FavoriteToolTile extends StatelessWidget {
  final String toolId;
  final VoidCallback onTap;

  const FavoriteToolTile({
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tool.icon,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                tool.title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (tool.estimated != null) ...[
                const SizedBox(height: 4),
                _TimeBadge(duration: tool.estimated!, fontSize: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}