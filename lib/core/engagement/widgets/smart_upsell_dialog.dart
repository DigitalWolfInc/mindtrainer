import 'package:flutter/material.dart';
import '../smart_upsell_service.dart';

/// Smart upsell dialog that adapts its design based on trigger context
class SmartUpsellDialog extends StatefulWidget {
  final UpsellPrompt prompt;
  final VoidCallback onUpgradeSelected;
  final VoidCallback onDismissed;

  const SmartUpsellDialog({
    super.key,
    required this.prompt,
    required this.onUpgradeSelected,
    required this.onDismissed,
  });

  @override
  State<SmartUpsellDialog> createState() => _SmartUpsellDialogState();
}

class _SmartUpsellDialogState extends State<SmartUpsellDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    if (widget.prompt.visualStyle == UpsellPromptStyle.celebratory ||
        widget.prompt.visualStyle == UpsellPromptStyle.achievement) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _getGradientForStyle(widget.prompt.visualStyle),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildContent(),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: _buildIcon(),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.prompt.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor = Colors.white;
    
    switch (widget.prompt.visualStyle) {
      case UpsellPromptStyle.celebratory:
        iconData = Icons.celebration;
        break;
      case UpsellPromptStyle.dataFocused:
        iconData = Icons.analytics;
        break;
      case UpsellPromptStyle.achievement:
        iconData = Icons.emoji_events;
        break;
      case UpsellPromptStyle.success:
        iconData = Icons.check_circle;
        break;
      case UpsellPromptStyle.discovery:
        iconData = Icons.explore;
        break;
      case UpsellPromptStyle.limitation:
        iconData = Icons.trending_up;
        break;
      case UpsellPromptStyle.curiosity:
        iconData = Icons.lightbulb;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 48,
        color: iconColor,
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Text(
            widget.prompt.message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildFeaturesList(),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Mood-focus correlations',
      'Tag performance insights', 
      'Keyword uplift analysis',
      'Unlimited historical data',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pro Analytics Include:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  feature,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _handleResponse('upgrade_tapped');
                widget.onUpgradeSelected();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _getPrimaryColorForStyle(widget.prompt.visualStyle),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.prompt.primaryAction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                _handleResponse('maybe_later');
                widget.onDismissed();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.prompt.secondaryAction,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleResponse(String action) {
    final responseTime = _startTime != null 
        ? DateTime.now().difference(_startTime!).inSeconds 
        : 0;
    
    final response = UpsellResponse(
      action: action,
      responseTimeSeconds: responseTime,
      userEngagementContext: 'high', // Could be calculated based on session data
    );
    
    SmartUpsellService().trackUpsellResponse(widget.prompt, response);
  }

  LinearGradient _getGradientForStyle(UpsellPromptStyle style) {
    switch (style) {
      case UpsellPromptStyle.celebratory:
        return const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UpsellPromptStyle.dataFocused:
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UpsellPromptStyle.achievement:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UpsellPromptStyle.success:
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UpsellPromptStyle.discovery:
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UpsellPromptStyle.limitation:
        return const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UpsellPromptStyle.curiosity:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getPrimaryColorForStyle(UpsellPromptStyle style) {
    switch (style) {
      case UpsellPromptStyle.celebratory:
        return const Color(0xFFFF6B35);
      case UpsellPromptStyle.dataFocused:
        return const Color(0xFF2196F3);
      case UpsellPromptStyle.achievement:
        return const Color(0xFFFFD700);
      case UpsellPromptStyle.success:
        return const Color(0xFF4CAF50);
      case UpsellPromptStyle.discovery:
        return const Color(0xFF9C27B0);
      case UpsellPromptStyle.limitation:
        return const Color(0xFFFF5722);
      case UpsellPromptStyle.curiosity:
        return const Color(0xFFFF9800);
    }
  }
}

/// Simplified banner-style upsell for less intrusive moments
class SmartUpsellBanner extends StatelessWidget {
  final UpsellPrompt prompt;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const SmartUpsellBanner({
    super.key,
    required this.prompt,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _getGradientForStyle(prompt.visualStyle),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildBannerIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getShortMessage(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _getPrimaryColorForStyle(prompt.visualStyle),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'Upgrade',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onDismiss,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerIcon() {
    IconData iconData = Icons.star; // Default icon
    
    switch (prompt.visualStyle) {
      case UpsellPromptStyle.celebratory:
        iconData = Icons.celebration;
        break;
      case UpsellPromptStyle.dataFocused:
        iconData = Icons.analytics;
        break;
      case UpsellPromptStyle.achievement:
        iconData = Icons.emoji_events;
        break;
      default:
        iconData = Icons.star;
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

  String _getShortMessage() {
    if (prompt.message.length <= 60) return prompt.message;
    return '${prompt.message.substring(0, 57)}...';
  }

  LinearGradient _getGradientForStyle(UpsellPromptStyle style) {
    return SmartUpsellDialog(
      prompt: prompt,
      onUpgradeSelected: () {},
      onDismissed: () {},
    )._getGradientForStyle(style);
  }

  Color _getPrimaryColorForStyle(UpsellPromptStyle style) {
    return SmartUpsellDialog(
      prompt: prompt,
      onUpgradeSelected: () {},
      onDismissed: () {},
    )._getPrimaryColorForStyle(style);
  }
}