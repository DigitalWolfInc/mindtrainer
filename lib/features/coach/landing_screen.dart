import 'package:flutter/material.dart';
import '../../core/feature_flags.dart';
import '../../ui/mtds/components/mtds_stack_card.dart';
import '../../ui/mtds/components/mtds_chip.dart';
import '../../ui/mtds/components/mtds_block.dart';
import '../../a11y/a11y.dart';
import '../../app_routes.dart';

/// Coach tab landing screen with chat and triage options
class CoachLandingScreen extends StatelessWidget {
  const CoachLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.blocksGridEnabled) {
      final items = <MtdsBlock>[
        MtdsBlock(
          icon: Icons.chat_bubble_outline,
          title: 'Talk to Coach',
          subtitle: 'I\'ll guide the next step.',
          onTap: () => R.go(context, '/coach'),
        ),
        MtdsBlock(
          icon: Icons.speed,
          title: 'Wired • Stuck • Low • Sleep',
          subtitle: 'Pick a state to start',
          onTap: () => R.go(context, '/coach/triage'),
        ),
        MtdsBlock(
          icon: Icons.sos,
          title: 'SOS (Crisis Call)',
          subtitle: 'Contact • Emergency • Support',
          onTap: () => R.go(context, '/sos'),
        ),
        MtdsBlock(
          icon: Icons.cloud_outlined,
          title: 'Cloud Coach',
          subtitle: 'Sync conversations across devices',
          badge: 'Pro',
          onTap: () => R.go(context, '/coach/pro'),
        ),
      ];
      return _BlockGrid(items: items);
    }

    // Fallback to legacy layout
    final textScaler = A11y.getClampedTextScale(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFallbackCard(
          context,
          title: 'Talk to Coach',
          subtitle: 'I\'ll guide the next step.',
          icon: Icons.chat_bubble_outline,
          onTap: () => _navigateToCoach(context),
          textScaler: textScaler,
        ),
        const SizedBox(height: 12),
        _buildTriageFallback(context, textScaler),
        const SizedBox(height: 12),
        _buildFallbackCard(
          context,
          title: 'SOS (Crisis Quick Call)',
          subtitle: 'Call contact • Emergency • Support line',
          icon: Icons.emergency,
          onTap: () => _navigateToSOS(context),
          textScaler: textScaler,
        ),
        const SizedBox(height: 12),
        _buildFallbackCard(
          context,
          title: 'Cloud Coach (Pro)',
          subtitle: 'Sync conversations across devices',
          icon: Icons.cloud_outlined,
          onTap: () => _navigateToCloudCoach(context),
          textScaler: textScaler,
        ),
      ],
    );
  }

  Widget _buildTriageSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mood,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a state to start',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap what feels closest right now',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (FeatureFlags.mtdsComponentsEnabled) ...[
                  MtdsChip.selectable(
                    text: 'Wired',
                    selected: false,
                    onTap: () => _handleTriageSelection(context, 'wired'),
                  ),
                  MtdsChip.selectable(
                    text: 'Stuck',
                    selected: false,
                    onTap: () => _handleTriageSelection(context, 'stuck'),
                  ),
                  MtdsChip.selectable(
                    text: 'Low',
                    selected: false,
                    onTap: () => _handleTriageSelection(context, 'low'),
                  ),
                  MtdsChip.selectable(
                    text: 'Can\'t sleep',
                    selected: false,
                    onTap: () => _handleTriageSelection(context, 'cant_sleep'),
                  ),
                ] else ...[
                  _buildTriageChip(context, 'Wired', 'wired'),
                  _buildTriageChip(context, 'Stuck', 'stuck'),
                  _buildTriageChip(context, 'Low', 'low'),
                  _buildTriageChip(context, 'Can\'t sleep', 'cant_sleep'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageChip(BuildContext context, String label, String state) {
    return A11y.ensureMinTouchTarget(
      ActionChip(
        label: Text(label),
        onPressed: () => _handleTriageSelection(context, state),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildTriageFallback(BuildContext context, double textScaler) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mood,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a state to start',
                        style: TextStyle(
                          fontSize: 16 * textScaler,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wired • Stuck • Low • Can\'t sleep',
                        style: TextStyle(
                          fontSize: 14 * textScaler,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
  void _navigateToCoach(BuildContext context) {
    Navigator.pushNamed(context, '/coach/chat');
  }

  void _handleTriageSelection(BuildContext context, String state) {
    Navigator.pushNamed(context, '/coach/triage/$state');
  }

  void _navigateToSOS(BuildContext context) {
    Navigator.pushNamed(context, '/coach/sos');
  }

  void _navigateToCloudCoach(BuildContext context) {
    Navigator.pushNamed(context, '/coach/cloud');
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