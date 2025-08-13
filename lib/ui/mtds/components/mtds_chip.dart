/// MTDS Chip - Selectable chips with idle/selected states
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Selectable chip component with proper MTDS styling
class MtdsChip extends StatelessWidget {
  const MtdsChip._({
    super.key,
    required this.text,
    required this.selected,
    this.onTap,
    this.enabled = true,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  /// Creates a selectable chip (const version)
  const factory MtdsChip.selectable({
    Key? key,
    required String text,
    required bool selected,
    VoidCallback? onTap,
  }) = MtdsChip._;

  /// Creates a selectable chip with enabled parameter
  factory MtdsChip.enabled({
    Key? key,
    required String text,
    required bool selected,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return MtdsChip._(
      key: key,
      text: text,
      selected: selected,
      onTap: onTap,
      enabled: enabled,
    );
  }

  Color get _backgroundColor {
    if (!enabled) return MtdsColors.accentDisabled;
    return selected ? MtdsColors.chipSelected : MtdsColors.chipIdle;
  }

  Color get _textColor {
    if (!enabled) return MtdsColors.textSecondary;
    return MtdsColors.textPrimary;
  }

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
        borderRadius: BorderRadius.circular(MtdsRadius.chip),
        child: Container(
          height: MtdsSizes.chipHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: MtdsSpacing.md,
            vertical: MtdsSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(MtdsRadius.chip),
          ),
          child: Center(
            child: Text(
              text,
              style: MtdsTypography.button.copyWith(
                color: _textColor,
                fontSize: 15, // Slightly smaller for chips
              ),
              textAlign: TextAlign.center,
              semanticsLabel: text,
            ),
          ),
        ),
      ),
    );
  }
}