/// Focus Environment Selector Widget
/// 
/// Allows users to choose from available focus environments with Pro gating.

import 'package:flutter/material.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../domain/focus_environment.dart';

class FocusEnvironmentSelector extends StatelessWidget {
  final FocusEnvironment selectedEnvironment;
  final MindTrainerProGates proGates;
  final ValueChanged<FocusEnvironment> onEnvironmentSelected;
  final VoidCallback? onProUpgradeRequested;
  
  const FocusEnvironmentSelector({
    super.key,
    required this.selectedEnvironment,
    required this.proGates,
    required this.onEnvironmentSelected,
    this.onProUpgradeRequested,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Focus Environment',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Free environments section
        _buildSection(
          context,
          'Free',
          FocusEnvironmentConfig.freeEnvironments,
          Colors.green,
        ),
        
        const SizedBox(height: 16),
        
        // Pro environments section
        _buildSection(
          context,
          'Pro',
          FocusEnvironmentConfig.proEnvironments,
          Colors.amber,
        ),
      ],
    );
  }
  
  Widget _buildSection(
    BuildContext context,
    String title,
    List<FocusEnvironmentConfig> environments,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              title == 'Pro' ? Icons.star : Icons.check_circle,
              color: accentColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: environments.map((config) {
            return _buildEnvironmentCard(context, config);
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildEnvironmentCard(BuildContext context, FocusEnvironmentConfig config) {
    final isSelected = selectedEnvironment == config.environment;
    final isAvailable = !config.isProOnly || proGates.isProActive;
    final colorTheme = Color(int.parse(config.colorTheme.substring(1), radix: 16) + 0xFF000000);
    
    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          onEnvironmentSelected(config.environment);
        } else {
          onProUpgradeRequested?.call();
        }
      },
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? colorTheme : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorTheme, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorTheme.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        _getEnvironmentIcon(config.environment),
                        color: isSelected ? Colors.white : colorTheme,
                        size: 20,
                      ),
                      if (!isAvailable)
                        Icon(
                          Icons.lock,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          config.name,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          config.description,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isSelected 
                                ? Colors.white70 
                                : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Overlay for locked environments
            if (!isAvailable)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  IconData _getEnvironmentIcon(FocusEnvironment environment) {
    switch (environment) {
      case FocusEnvironment.silence:
        return Icons.volume_off;
      case FocusEnvironment.forest:
        return Icons.park;
      case FocusEnvironment.ocean:
        return Icons.waves;
      case FocusEnvironment.rain:
        return Icons.grain;
      case FocusEnvironment.cafe:
        return Icons.local_cafe;
      case FocusEnvironment.mountains:
        return Icons.landscape;
      case FocusEnvironment.fireplace:
        return Icons.fireplace;
      case FocusEnvironment.whiteNoise:
        return Icons.graphic_eq;
      case FocusEnvironment.brownNoise:
        return Icons.equalizer;
      case FocusEnvironment.binauralBeats:
        return Icons.headphones;
      case FocusEnvironment.nature:
        return Icons.nature;
      case FocusEnvironment.storm:
        return Icons.thunderstorm;
    }
  }
}