/// Optimization Widgets for MindTrainer
/// 
/// UI components that integrate with the optimization system
/// for engagement cues, upsell messages, and performance monitoring.

import 'package:flutter/material.dart';
import 'engagement_system.dart';
import 'upsell_strategy.dart';
import 'optimization_manager.dart';

/// Engagement cue display widget
class EngagementCueWidget extends StatelessWidget {
  final EngagementCue cue;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final OptimizationManager optimizationManager;
  
  const EngagementCueWidget({
    super.key,
    required this.cue,
    this.onAction,
    this.onDismiss,
    required this.optimizationManager,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCueIcon(), color: _getCueColor()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cue.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    await optimizationManager.dismissEngagementCue(cue.type);
                    onDismiss?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cue.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (cue.actionLabel != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onAction,
                    child: Text(cue.actionLabel!),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getCueIcon() {
    switch (cue.type) {
      case CueType.streakReminder:
        return Icons.local_fire_department;
      case CueType.proFeatureDiscovery:
        return Icons.star;
      case CueType.goalProgress:
        return Icons.trending_up;
      case CueType.returnWelcome:
        return Icons.waving_hand;
      case CueType.achievementCelebration:
        return Icons.celebration;
      case CueType.inactivitySummary:
        return Icons.insights;
    }
  }
  
  Color _getCueColor() {
    switch (cue.type) {
      case CueType.streakReminder:
        return Colors.orange;
      case CueType.proFeatureDiscovery:
        return Colors.amber;
      case CueType.goalProgress:
        return Colors.green;
      case CueType.returnWelcome:
        return Colors.blue;
      case CueType.achievementCelebration:
        return Colors.purple;
      case CueType.inactivitySummary:
        return Colors.teal;
    }
  }
}

/// Upsell message display widget
class UpsellMessageWidget extends StatelessWidget {
  final UpsellMessage message;
  final UpsellOpportunity opportunity;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;
  final OptimizationManager optimizationManager;
  
  const UpsellMessageWidget({
    super.key,
    required this.message,
    required this.opportunity,
    this.onUpgrade,
    this.onDismiss,
    required this.optimizationManager,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: _getStyleGradient(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStyleIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message.headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () async {
                    await optimizationManager.onUpsellInteraction(
                      trigger: opportunity.trigger,
                      action: 'dismissed',
                      opportunity: opportunity,
                    );
                    onDismiss?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (message.secondaryAction != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await optimizationManager.onUpsellInteraction(
                          trigger: opportunity.trigger,
                          action: 'secondary',
                          opportunity: opportunity,
                        );
                        onDismiss?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: Text(message.secondaryAction!),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: message.secondaryAction != null ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      await optimizationManager.onUpsellInteraction(
                        trigger: opportunity.trigger,
                        action: 'converted',
                        opportunity: opportunity,
                      );
                      onUpgrade?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _getStyleColor(),
                      elevation: 0,
                    ),
                    child: Text(message.ctaText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Gradient _getStyleGradient() {
    switch (message.style) {
      case MessageStyle.supportive:
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MessageStyle.achievement:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MessageStyle.curiosity:
        return const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
  
  Color _getStyleColor() {
    switch (message.style) {
      case MessageStyle.supportive:
        return const Color(0xFF4CAF50);
      case MessageStyle.achievement:
        return const Color(0xFFFF9800);
      case MessageStyle.curiosity:
        return const Color(0xFF673AB7);
    }
  }
  
  IconData _getStyleIcon() {
    switch (message.style) {
      case MessageStyle.supportive:
        return Icons.favorite;
      case MessageStyle.achievement:
        return Icons.emoji_events;
      case MessageStyle.curiosity:
        return Icons.explore;
    }
  }
}

/// Performance-monitored screen wrapper
class OptimizedScreen extends StatefulWidget {
  final String screenName;
  final Widget child;
  final OptimizationManager optimizationManager;
  
  const OptimizedScreen({
    super.key,
    required this.screenName,
    required this.child,
    required this.optimizationManager,
  });
  
  @override
  State<OptimizedScreen> createState() => _OptimizedScreenState();
}

class _OptimizedScreenState extends State<OptimizedScreen> {
  @override
  void initState() {
    super.initState();
    
    // Measure screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.optimizationManager.performance.endMeasurement(
        PerformanceMetric.screenTransition,
        'load_${widget.screenName}',
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.optimizationManager.measureWidgetBuild(
      widget.screenName,
      () => widget.child,
    );
  }
}

/// Engagement cue list widget
class EngagementCuesWidget extends StatefulWidget {
  final OptimizationManager optimizationManager;
  final int maxCues;
  
  const EngagementCuesWidget({
    super.key,
    required this.optimizationManager,
    this.maxCues = 2,
  });
  
  @override
  State<EngagementCuesWidget> createState() => _EngagementCuesWidgetState();
}

class _EngagementCuesWidgetState extends State<EngagementCuesWidget> {
  List<EngagementCue> _cues = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCues();
  }
  
  Future<void> _loadCues() async {
    try {
      final cues = await widget.optimizationManager.getEngagementCues();
      
      if (mounted) {
        setState(() {
          _cues = cues.take(widget.maxCues).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
  
  void _dismissCue(int index) {
    if (index < _cues.length) {
      setState(() {
        _cues.removeAt(index);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_cues.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: _cues.asMap().entries.map((entry) {
        final index = entry.key;
        final cue = entry.value;
        
        return EngagementCueWidget(
          cue: cue,
          optimizationManager: widget.optimizationManager,
          onDismiss: () => _dismissCue(index),
          onAction: () {
            // Handle cue action based on type
            switch (cue.type) {
              case CueType.proFeatureDiscovery:
                // Navigate to Pro features
                break;
              case CueType.streakReminder:
                // Navigate to session start
                break;
              default:
                break;
            }
            _dismissCue(index);
          },
        );
      }).toList(),
    );
  }
}

/// Performance debug overlay (development only)
class PerformanceDebugOverlay extends StatelessWidget {
  final OptimizationManager optimizationManager;
  final Widget child;
  
  const PerformanceDebugOverlay({
    super.key,
    required this.optimizationManager,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    assert(() {
      return true;
    }());
    
    return Stack(
      children: [
        child,
        if (optimizationManager.isFeatureEnabled('performance_monitoring'))
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: optimizationManager.performance.getPerformanceSummary(
                  period: const Duration(minutes: 5),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    );
                  }
                  
                  final summary = snapshot.data!;
                  return Text(
                    'Perf: ${summary['total_measurements']} ops',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}