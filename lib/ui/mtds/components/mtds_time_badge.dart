/// MTDS Time Badge - Duration indicator component
import 'package:flutter/material.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Time badge showing duration in minutes
/// Displays as "• 1m • 3m • 10m" format
class MtdsTimeBadge extends StatelessWidget {
  const MtdsTimeBadge({
    super.key,
    required this.minutes,
    this.showBullet = true,
  });

  final int minutes;
  final bool showBullet;

  String get _formattedTime {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional bullet point
        if (showBullet) ...[
          Text(
            '•',
            style: MtdsTypography.body.copyWith(
              color: MtdsColors.textSecondary,
              fontSize: 12,
            ),
          ),
          SizedBox(width: MtdsSpacing.xs),
        ],
        
        // Duration text
        Text(
          _formattedTime,
          style: MtdsTypography.body.copyWith(
            color: MtdsColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          semanticsLabel: '$minutes minutes',
        ),
      ],
    );
  }
}

/// Multiple time badges in a row with bullet separators
class MtdsTimeBadgeRow extends StatelessWidget {
  const MtdsTimeBadgeRow({
    super.key,
    required this.durations,
  });

  final List<int> durations;

  @override
  Widget build(BuildContext context) {
    if (durations.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: durations
          .asMap()
          .entries
          .map((entry) => MtdsTimeBadge(
                minutes: entry.value,
                showBullet: entry.key > 0, // No bullet for first item
              ))
          .expand((badge) => [badge, SizedBox(width: MtdsSpacing.xs)])
          .take(durations.length * 2 - 1) // Remove last spacer
          .toList(),
    );
  }
}