/// MTDS List Tile - Cohesive rows for settings and history
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Consistent list tile for settings and history screens
/// Matches MTDS design patterns with proper accessibility
class MtdsListTile extends StatelessWidget {
  const MtdsListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null && enabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? () {
          // Soft haptic feedback
          HapticFeedback.lightImpact();
          onTap!();
        } : null,
        child: Container(
          constraints: BoxConstraints(
            minHeight: dense ? 48.0 : MtdsSizes.listTileHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: MtdsSpacing.lg,
            vertical: dense ? MtdsSpacing.sm : MtdsSpacing.md,
          ),
          child: Row(
            children: [
              // Leading widget
              if (leading != null) ...[
                leading!,
                SizedBox(width: MtdsSpacing.md),
              ],
              
              // Content column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      title,
                      style: MtdsTypography.body.copyWith(
                        color: enabled ? MtdsColors.textPrimary : MtdsColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: title,
                    ),
                    
                    // Subtitle
                    if (subtitle != null) ...[
                      SizedBox(height: MtdsSpacing.xs),
                      Text(
                        subtitle!,
                        style: MtdsTypography.body.copyWith(
                          color: enabled ? MtdsColors.textSecondary : MtdsColors.accentDisabled,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing widget
              if (trailing != null) ...[
                SizedBox(width: MtdsSpacing.md),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}