import 'package:flutter/material.dart';
import '../../core/feature_flags.dart';
import '../../ui/mtds/components/mtds_stack_card.dart';
import '../../ui/mtds/components/mtds_time_badge.dart';
import '../../ui/mtds/components/mtds_block.dart';
import '../../a11y/a11y.dart';
import '../../app_routes.dart';

/// Rest tab landing screen with wind-down and sleep tools
class RestLandingScreen extends StatelessWidget {
  const RestLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.blocksGridEnabled) {
      final items = <MtdsBlock>[
        MtdsBlock(
          icon: Icons.bedtime_outlined,
          title: 'Wind-Down',
          subtitle: '10–20 minutes',
          onTap: () => R.go(context, '/tools/wind-down'),
        ),
        MtdsBlock(
          icon: Icons.note_add_outlined,
          title: 'Brain Dump → Park It',
          subtitle: '3–5 minutes',
          onTap: () => R.go(context, '/tools/brain-dump'),
        ),
        MtdsBlock(
          icon: Icons.accessibility_new_outlined,
          title: 'Body Scan',
          subtitle: 'long',
          badge: 'Pro',
          onTap: () => R.go(context, '/sleep/body-scan'),
        ),
        MtdsBlock(
          icon: Icons.music_note_outlined,
          title: 'Looping Sounds',
          subtitle: 'offline packs',
          badge: 'Pro',
          onTap: () => R.go(context, '/sleep/sounds'),
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
            title: 'Wind-Down',
            subtitle: '10–20 minutes',
            leadingIcon: Icons.bedtime_outlined,
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Brain Dump → Park It',
            subtitle: '3–5 minutes',
            leadingIcon: Icons.note_add_outlined,
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Body Scan (Pro)',
            subtitle: 'long',
            leadingIcon: Icons.accessibility_new_outlined,
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Looping Sounds (Pro)',
            subtitle: 'offline packs',
            leadingIcon: Icons.music_note_outlined,
          ),
        ] else ...[
          // Fallback implementation
          _buildFallbackCard(
            context,
            title: 'Wind-Down',
            subtitle: '10–20 minutes',
            icon: Icons.bedtime_outlined,
            onTap: () => _navigateToWindDown(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Brain Dump → Park It',
            subtitle: '3–5 minutes',
            icon: Icons.note_add_outlined,
            onTap: () => _navigateToBrainDump(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Body Scan (Pro)',
            subtitle: 'long',
            icon: Icons.accessibility_new_outlined,
            onTap: () => _navigateToBodyScan(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Looping Sounds (Pro)',
            subtitle: 'offline packs',
            icon: Icons.music_note_outlined,
            onTap: () => _navigateToLoopingSounds(context),
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
  void _navigateToWindDown(BuildContext context) {
    Navigator.pushNamed(context, '/rest/wind-down');
  }

  void _navigateToBrainDump(BuildContext context) {
    Navigator.pushNamed(context, '/rest/brain-dump');
  }

  void _navigateToBodyScan(BuildContext context) {
    Navigator.pushNamed(context, '/rest/body-scan');
  }

  void _navigateToLoopingSounds(BuildContext context) {
    Navigator.pushNamed(context, '/rest/looping-sounds');
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