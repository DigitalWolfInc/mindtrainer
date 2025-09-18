import 'package:flutter/material.dart';
import '../../core/feature_flags.dart';
import '../../ui/mtds/components/mtds_stack_card.dart';
import '../../ui/mtds/components/mtds_time_badge.dart';
import '../../ui/mtds/components/mtds_block.dart';
import '../../a11y/a11y.dart';
import '../../app_routes.dart';

/// Regulate tab landing screen with calming techniques
class RegulateLandingScreen extends StatelessWidget {
  const RegulateLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.blocksGridEnabled) {
      final items = <MtdsBlock>[
        MtdsBlock(
          icon: Icons.air,
          title: 'Calm Breath',
          subtitle: '1 minute',
          badge: '1m',
          onTap: () => R.go(context, '/tools/calm-breath'),
        ),
        MtdsBlock(
          icon: Icons.wind_power,
          title: 'Physiological Sigh',
          subtitle: '1–2 minutes',
          onTap: () => R.go(context, '/tools/phys-sigh'),
        ),
        MtdsBlock(
          icon: Icons.psychology,
          title: '5-4-3-2-1 Grounding',
          subtitle: '3 minutes',
          badge: '3m',
          onTap: () => R.go(context, '/tools/grounding-54321'),
        ),
        MtdsBlock(
          icon: Icons.accessibility_new,
          title: 'Body Unclench',
          subtitle: '4 minutes',
          badge: '4m',
          onTap: () => R.go(context, '/tools/body-unclench'),
        ),
      ];
      return _BlockGrid(items: items);
    }

    final textScaler = A11y.getClampedTextScale(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (FeatureFlags.mtdsComponentsEnabled) ...[
          // Use MTDS components
          const MtdsStackCard(
            title: 'Calm Breath',
            subtitle: '1 minute',
            leadingIcon: Icons.air,
            trailing: MtdsTimeBadge(minutes: 1),
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Physiological Sigh',
            subtitle: '1–2 minutes',
            leadingIcon: Icons.wind_power,
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: '5-4-3-2-1 Grounding',
            subtitle: '3 minutes',
            leadingIcon: Icons.psychology,
            trailing: MtdsTimeBadge(minutes: 3),
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Body Unclench',
            subtitle: '4 minutes',
            leadingIcon: Icons.accessibility_new,
            trailing: MtdsTimeBadge(minutes: 4),
          ),
        ] else ...[
          // Fallback implementation
          _buildFallbackCard(
            context,
            title: 'Calm Breath',
            subtitle: '1 minute',
            icon: Icons.air,
            onTap: () => _navigateToCalmBreath(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Physiological Sigh',
            subtitle: '1–2 minutes',
            icon: Icons.wind_power,
            onTap: () => _navigateToPhysiologicalSigh(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: '5-4-3-2-1 Grounding',
            subtitle: '3 minutes',
            icon: Icons.psychology,
            onTap: () => _navigateToGrounding(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Body Unclench',
            subtitle: '4 minutes',
            icon: Icons.accessibility_new,
            onTap: () => _navigateToBodyUnclench(context),
            textScaler: textScaler,
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required double textScaler,
  }) {
    return A11y.ensureMinTouchTarget(
      Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 * textScaler,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14 * textScaler,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation methods (stubs for now)
  void _navigateToCalmBreath(BuildContext context) {
    Navigator.pushNamed(context, '/regulate/calm-breath');
  }

  void _navigateToPhysiologicalSigh(BuildContext context) {
    Navigator.pushNamed(context, '/regulate/physiological-sigh');
  }

  void _navigateToGrounding(BuildContext context) {
    Navigator.pushNamed(context, '/regulate/grounding');
  }

  void _navigateToBodyUnclench(BuildContext context) {
    Navigator.pushNamed(context, '/regulate/body-unclench');
  }
}

/// Shared block grid widget for responsive layout
class _BlockGrid extends StatelessWidget {
  const _BlockGrid({required this.items});

  final List<MtdsBlock> items;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cols = screenWidth >= 900 ? 3 : 2;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}