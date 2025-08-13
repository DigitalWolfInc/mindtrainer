import 'package:flutter/material.dart';
import '../engagement_cue_service.dart';

/// Widget that displays engagement cues in an attractive, non-intrusive way
class EngagementCueCard extends StatelessWidget {
  final EngagementCue cue;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const EngagementCueCard({
    super.key,
    required this.cue,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: _getGradientForCue(cue.type),
          ),
          child: Row(
            children: [
              _buildCueIcon(cue.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cue.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildPriorityIndicator(cue.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cue.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _getPrimaryColorForCue(cue.type),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            cue.actionText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onDismiss,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCueIcon(EngagementCueType type) {
    IconData iconData;
    
    switch (type) {
      case EngagementCueType.streakContinuation:
        iconData = Icons.local_fire_department;
        break;
      case EngagementCueType.reEngagement:
        iconData = Icons.refresh;
        break;
      case EngagementCueType.proFeatureReminder:
        iconData = Icons.star;
        break;
      case EngagementCueType.goalProgress:
        iconData = Icons.track_changes;
        break;
      case EngagementCueType.focusImprovement:
        iconData = Icons.trending_up;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildPriorityIndicator(EngagementPriority priority) {
    if (priority != EngagementPriority.high) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Priority',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  LinearGradient _getGradientForCue(EngagementCueType type) {
    switch (type) {
      case EngagementCueType.streakContinuation:
        return const LinearGradient(
          colors: [Colors.deepOrange, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EngagementCueType.reEngagement:
        return const LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EngagementCueType.proFeatureReminder:
        return const LinearGradient(
          colors: [Colors.amber, Colors.orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EngagementCueType.goalProgress:
        return const LinearGradient(
          colors: [Colors.green, Colors.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case EngagementCueType.focusImprovement:
        return const LinearGradient(
          colors: [Colors.purple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getPrimaryColorForCue(EngagementCueType type) {
    switch (type) {
      case EngagementCueType.streakContinuation:
        return Colors.deepOrange;
      case EngagementCueType.reEngagement:
        return Colors.blue;
      case EngagementCueType.proFeatureReminder:
        return Colors.amber[800]!;
      case EngagementCueType.goalProgress:
        return Colors.green;
      case EngagementCueType.focusImprovement:
        return Colors.purple;
    }
  }
}

/// Compact version of engagement cue for less prominent placement
class EngagementCueBanner extends StatelessWidget {
  final EngagementCue cue;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const EngagementCueBanner({
    super.key,
    required this.cue,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: _getGradientForCue(cue.type),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              _getIconForCue(cue.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cue.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(
                cue.actionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getGradientForCue(EngagementCueType type) {
    return EngagementCueCard(
      cue: cue,
      onTap: () {},
      onDismiss: () {},
    )._getGradientForCue(type);
  }

  IconData _getIconForCue(EngagementCueType type) {
    switch (type) {
      case EngagementCueType.streakContinuation:
        return Icons.local_fire_department;
      case EngagementCueType.reEngagement:
        return Icons.refresh;
      case EngagementCueType.proFeatureReminder:
        return Icons.star;
      case EngagementCueType.goalProgress:
        return Icons.track_changes;
      case EngagementCueType.focusImprovement:
        return Icons.trending_up;
    }
  }
}