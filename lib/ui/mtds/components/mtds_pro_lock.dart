/// MTDS Pro Lock - Soft overlay with upgrade CTA
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Pro feature overlay with soft lock and upgrade CTA
/// Shows "Preview → Upgrade" pattern
class MtdsProLock extends StatelessWidget {
  const MtdsProLock({
    super.key,
    required this.child,
    this.onUpgradeTap,
    this.enabled = true,
    this.showOverlay = true,
  });

  final Widget child;
  final VoidCallback? onUpgradeTap;
  final bool enabled;
  final bool showOverlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Original content (slightly dimmed if locked)
        Opacity(
          opacity: showOverlay ? 0.5 : 1.0,
          child: child,
        ),
        
        // Overlay when locked
        if (showOverlay)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: MtdsColors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(MtdsRadius.card),
              ),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled && onUpgradeTap != null ? () {
                      // Soft haptic feedback
                      HapticFeedback.lightImpact();
                      onUpgradeTap!();
                    } : null,
                    borderRadius: BorderRadius.circular(MtdsRadius.chip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MtdsSpacing.md,
                        vertical: MtdsSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: MtdsColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(MtdsRadius.chip),
                        border: Border.all(
                          color: MtdsColors.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lock icon
                          Icon(
                            Icons.lock_outline_rounded,
                            color: MtdsColors.accent,
                            size: MtdsSizes.iconSm,
                          ),
                          SizedBox(width: MtdsSpacing.xs),
                          
                          // CTA text
                          Text(
                            'Preview → Upgrade',
                            style: MtdsTypography.button.copyWith(
                              color: MtdsColors.accent,
                              fontSize: 14,
                            ),
                            semanticsLabel: 'Preview then upgrade to unlock this feature',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}