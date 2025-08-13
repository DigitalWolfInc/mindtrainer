/// Breathing Pattern Selector Widget
/// 
/// Allows Pro users to select breathing patterns for guided sessions.

import 'package:flutter/material.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../domain/focus_environment.dart';

class BreathingPatternSelector extends StatelessWidget {
  final BreathingPattern? selectedPattern;
  final ValueChanged<BreathingPattern?>? onPatternSelected;
  final bool enabled;
  final VoidCallback? onProUpgradeRequested;
  
  const BreathingPatternSelector({
    super.key,
    required this.selectedPattern,
    this.onPatternSelected,
    this.enabled = true,
    this.onProUpgradeRequested,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Breathing Guide',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (!enabled)
              GestureDetector(
                onTap: onProUpgradeRequested,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          enabled
              ? 'Choose a breathing pattern to guide your session'
              : 'Upgrade to Pro for guided breathing patterns',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        // None option
        _buildPatternOption(
          context,
          null,
          'No Breathing Guide',
          'Focus without breathing cues',
          Icons.do_not_disturb_on,
          isEnabled: true,
        ),
        
        const SizedBox(height: 8),
        
        // Breathing patterns
        ...BreathingPattern.patterns.map((pattern) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPatternOption(
              context,
              pattern,
              pattern.name,
              '${pattern.description} • ${pattern.cyclesPerMinute.toStringAsFixed(1)} cycles/min',
              Icons.air,
              isEnabled: enabled,
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildPatternOption(
    BuildContext context,
    BreathingPattern? pattern,
    String title,
    String description,
    IconData icon,
    {required bool isEnabled}
  ) {
    final isSelected = selectedPattern == pattern;
    
    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          onPatternSelected?.call(pattern);
        } else {
          onProUpgradeRequested?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                      if (!isEnabled && pattern != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                  
                  // Show breathing rhythm for patterns
                  if (pattern != null && isEnabled) ...[
                    const SizedBox(height: 8),
                    _buildBreathingVisualization(context, pattern),
                  ],
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBreathingVisualization(BuildContext context, BreathingPattern pattern) {
    return Row(
      children: [
        _buildBreathingPhase(context, 'In', pattern.inhaleSeconds, Colors.blue[300]!),
        if (pattern.holdSeconds > 0) ...[
          const SizedBox(width: 4),
          _buildBreathingPhase(context, 'Hold', pattern.holdSeconds, Colors.orange[300]!),
        ],
        const SizedBox(width: 4),
        _buildBreathingPhase(context, 'Out', pattern.exhaleSeconds, Colors.green[300]!),
        if (pattern.pauseSeconds > 0) ...[
          const SizedBox(width: 4),
          _buildBreathingPhase(context, 'Pause', pattern.pauseSeconds, Colors.grey[300]!),
        ],
      ],
    );
  }
  
  Widget _buildBreathingPhase(BuildContext context, String label, int seconds, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $seconds',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}