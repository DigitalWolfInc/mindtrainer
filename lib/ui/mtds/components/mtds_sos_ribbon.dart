/// MTDS SOS Ribbon - High-contrast emergency help ribbon
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// High-contrast neutral ribbon for emergency help access
/// Uses different color scheme for accessibility and prominence
class MtdsSosRibbon extends StatelessWidget {
  const MtdsSosRibbon({
    super.key,
    this.onTap,
    this.text = 'Need help right now?',
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(MtdsSpacing.lg),
      decoration: BoxDecoration(
        color: MtdsColors.sosSurface,
        borderRadius: BorderRadius.circular(MtdsRadius.chip),
        boxShadow: MtdsElevation.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && onTap != null ? () {
            // No haptic feedback for emergency actions to avoid delays
            onTap!();
          } : null,
          borderRadius: BorderRadius.circular(MtdsRadius.chip),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: MtdsSizes.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: MtdsSpacing.lg,
              vertical: MtdsSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emergency icon
                Icon(
                  Icons.emergency_outlined,
                  color: MtdsColors.sosText,
                  size: MtdsSizes.iconMd,
                ),
                SizedBox(width: MtdsSpacing.sm),
                
                // Help text
                Flexible(
                  child: Text(
                    text,
                    style: MtdsTypography.button.copyWith(
                      color: MtdsColors.sosText,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    semanticsLabel: text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}