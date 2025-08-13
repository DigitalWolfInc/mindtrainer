/// MTDS Primary Pill Button - Main CTA button with states
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Button states for styling
enum MtdsButtonState { idle, pressed, disabled }

/// Primary pill-shaped button for main CTAs
/// 56px height with proper accessibility and haptics
class MtdsPrimaryPillButton extends StatefulWidget {
  const MtdsPrimaryPillButton({
    super.key,
    required this.text,
    this.onPressed,
    this.state = MtdsButtonState.idle,
    this.width,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final MtdsButtonState state;
  final double? width;
  final IconData? icon;

  @override
  State<MtdsPrimaryPillButton> createState() => _MtdsPrimaryPillButtonState();
}

class _MtdsPrimaryPillButtonState extends State<MtdsPrimaryPillButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    if (widget.state == MtdsButtonState.disabled || widget.onPressed == null) {
      return MtdsColors.accentDisabled;
    }
    if (_isPressed || widget.state == MtdsButtonState.pressed) {
      return MtdsColors.accentPressed;
    }
    return MtdsColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && widget.state != MtdsButtonState.disabled;

    return SizedBox(
      width: widget.width,
      height: MtdsSizes.pillButtonHeight,
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(MtdsRadius.pill),
        child: InkWell(
          onTap: isEnabled ? () {
            // Soft haptic feedback for primary actions
            HapticFeedback.lightImpact();
            widget.onPressed?.call();
          } : null,
          onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
          borderRadius: BorderRadius.circular(MtdsRadius.pill),
          child: Container(
            height: MtdsSizes.pillButtonHeight,
            padding: const EdgeInsets.symmetric(horizontal: MtdsSpacing.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Optional leading icon
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: MtdsSizes.iconSm,
                    color: isEnabled ? MtdsColors.textPrimary : MtdsColors.textSecondary,
                  ),
                  SizedBox(width: MtdsSpacing.sm),
                ],
                
                // Button text
                Text(
                  widget.text,
                  style: MtdsTypography.button.copyWith(
                    color: isEnabled ? MtdsColors.textPrimary : MtdsColors.textSecondary,
                  ),
                  semanticsLabel: widget.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}