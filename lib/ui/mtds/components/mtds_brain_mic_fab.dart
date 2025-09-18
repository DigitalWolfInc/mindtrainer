/// MTDS Brain Mic FAB - Special floating action button for voice+brain
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mtds_theme.dart';
import '../mtds_tokens.dart';

/// Special FAB combining brain and microphone functionality
/// Supports tap and hold gestures with proper haptics
class MtdsBrainMicFab extends StatefulWidget {
  const MtdsBrainMicFab({
    super.key,
    this.onTap,
    this.onTapHold,
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final VoidCallback? onTapHold;
  final bool enabled;

  @override
  State<MtdsBrainMicFab> createState() => _MtdsBrainMicFabState();
}

class _MtdsBrainMicFabState extends State<MtdsBrainMicFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: MtdsMotion.quick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: MtdsMotion.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTap() {
    if (widget.enabled && widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handleLongPress() {
    if (widget.enabled && widget.onTapHold != null) {
      // Stronger haptic for hold gesture
      HapticFeedback.mediumImpact();
      widget.onTapHold!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: widget.enabled ? MtdsColors.accent : MtdsColors.accentDisabled,
              shape: BoxShape.circle,
              boxShadow: MtdsElevation.card,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _handleTap,
                onLongPress: _handleLongPress,
                onTapDown: (_) => _handleTapDown(),
                onTapUp: (_) => _handleTapUp(),
                onTapCancel: _handleTapUp,
                customBorder: const CircleBorder(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Brain icon (background)
                    Positioned(
                      left: 16,
                      child: Icon(
                        Icons.psychology_outlined,
                        color: widget.enabled 
                            ? MtdsColors.textPrimary 
                            : MtdsColors.textSecondary,
                        size: MtdsSizes.iconSm,
                      ),
                    ),
                    
                    // Mic icon (foreground)
                    Positioned(
                      right: 16,
                      child: Icon(
                        Icons.mic_rounded,
                        color: widget.enabled 
                            ? MtdsColors.textPrimary 
                            : MtdsColors.textSecondary,
                        size: MtdsSizes.iconMd,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}