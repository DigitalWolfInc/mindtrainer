import 'package:flutter/material.dart';
import '../../core/feature_flags.dart';
import '../../ui/mtds/components/mtds_stack_card.dart';
import '../../ui/mtds/components/mtds_time_badge.dart';
import '../../ui/mtds/components/mtds_block.dart';
import '../../a11y/a11y.dart';
import '../../app_routes.dart';

/// Think tab landing screen with cognitive techniques
class ThinkLandingScreen extends StatelessWidget {
  const ThinkLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.blocksGridEnabled) {
      final items = <MtdsBlock>[
        MtdsBlock(
          icon: Icons.lightbulb_outline,
          title: 'Name the Thought',
          subtitle: '2 minutes',
          badge: '2m',
          onTap: () => R.go(context, '/tools/name-thought'),
        ),
        MtdsBlock(
          icon: Icons.fact_check_outlined,
          title: 'Evidence Check',
          subtitle: '5 minutes',
          badge: '5m',
          onTap: () => R.go(context, '/tools/evidence-check'),
        ),
        MtdsBlock(
          icon: Icons.flip_camera_android_outlined,
          title: 'Perspective Flip',
          subtitle: '3–5 minutes',
          onTap: () => R.go(context, '/tools/perspective-flip'),
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
            title: 'Name the Thought',
            subtitle: '2 minutes',
            leadingIcon: Icons.lightbulb_outline,
            trailing: MtdsTimeBadge(minutes: 2),
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Evidence Check',
            subtitle: '5 minutes',
            leadingIcon: Icons.fact_check_outlined,
            trailing: MtdsTimeBadge(minutes: 5),
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Perspective Flip',
            subtitle: '3–5 minutes',
            leadingIcon: Icons.flip_camera_android_outlined,
          ),
        ] else ...[
          // Fallback implementation
          _buildFallbackCard(
            context,
            title: 'Name the Thought',
            subtitle: '2 minutes',
            icon: Icons.lightbulb_outline,
            onTap: () => _navigateToNameThought(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Evidence Check',
            subtitle: '5 minutes',
            icon: Icons.fact_check_outlined,
            onTap: () => _navigateToEvidenceCheck(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Perspective Flip',
            subtitle: '3–5 minutes',
            icon: Icons.flip_camera_android_outlined,
            onTap: () => _navigateToPerspectiveFlip(context),
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
  void _navigateToNameThought(BuildContext context) {
    Navigator.pushNamed(context, '/think/name-thought');
  }

  void _navigateToEvidenceCheck(BuildContext context) {
    Navigator.pushNamed(context, '/think/evidence-check');
  }

  void _navigateToPerspectiveFlip(BuildContext context) {
    Navigator.pushNamed(context, '/think/perspective-flip');
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