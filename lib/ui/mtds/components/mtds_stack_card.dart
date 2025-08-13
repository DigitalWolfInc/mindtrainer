/// MTDS Stack Card - Primary list card component
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Primary card component for stacked list views
/// Matches existing stacked list look with MTDS styling
class MtdsStackCard extends StatelessWidget {
  const MtdsStackCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null && enabled;
    
    return Container(
      decoration: BoxDecoration(
        color: MtdsColors.surface,
        borderRadius: BorderRadius.circular(MtdsRadius.card),
        boxShadow: MtdsElevation.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? () {
            // Soft haptic feedback for primary actions
            HapticFeedback.lightImpact();
            onTap!();
          } : null,
          borderRadius: BorderRadius.circular(MtdsRadius.card),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: MtdsSizes.minTouchTarget + MtdsSpacing.lg,
            ),
            padding: padding ?? const EdgeInsets.all(MtdsSpacing.lg),
            child: Row(
              children: [
                // Leading icon
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    color: enabled ? MtdsColors.accent : MtdsColors.accentDisabled,
                    size: MtdsSizes.iconMd,
                  ),
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
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          semanticsLabel: subtitle,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Trailing content
                if (trailing != null) ...[
                  SizedBox(width: MtdsSpacing.md),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}