import 'package:flutter/material.dart';
import '../../core/feature_flags.dart';
import '../../ui/mtds/components/mtds_stack_card.dart';
import '../../ui/mtds/components/mtds_time_badge.dart';
import '../../ui/mtds/components/mtds_chip.dart';
import '../../ui/mtds/components/mtds_block.dart';
import '../../a11y/a11y.dart';
import '../focus_session/services/focus_timer_prefs.dart';
import '../../app_routes.dart';

/// Do tab landing screen with action-oriented tools
class DoLandingScreen extends StatefulWidget {
  const DoLandingScreen({super.key});

  @override
  State<DoLandingScreen> createState() => _DoLandingScreenState();
}

class _DoLandingScreenState extends State<DoLandingScreen> {
  int? _lastUsedMinutes;

  @override
  void initState() {
    super.initState();
    _loadLastUsedDuration();
  }

  Future<void> _loadLastUsedDuration() async {
    final duration = await FocusTimerPrefs.instance.getLastDuration();
    if (mounted) {
      setState(() {
        _lastUsedMinutes = duration.inMinutes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.blocksGridEnabled) {
      final items = <MtdsBlock>[
        MtdsBlock(
          icon: Icons.directions_walk,
          title: 'Tiny Next Step',
          subtitle: '1 minute',
          badge: '1m',
          onTap: () => R.go(context, '/tools/tiny-next-step'),
        ),
        MtdsBlock(
          icon: Icons.map_outlined,
          title: 'Energy Map → Pick 1',
          subtitle: '3–5 minutes',
          onTap: () => R.go(context, '/tools/energy-map'),
        ),
        MtdsBlock(
          icon: Icons.timelapse_outlined,
          title: 'Focus Timer',
          subtitle: '5 / 10 / 20 / 25 / Last used',
          onTap: () => R.go(context, '/focus'),
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
            title: 'Tiny Next Step',
            subtitle: '1 minute',
            leadingIcon: Icons.directions_walk,
            trailing: MtdsTimeBadge(minutes: 1),
          ),
          const SizedBox(height: 12),
          const MtdsStackCard(
            title: 'Energy Map → Pick 1',
            subtitle: '3–5 minutes',
            leadingIcon: Icons.map_outlined,
          ),
          const SizedBox(height: 12),
          
          // Focus Timer with chips
          _buildFocusTimerSection(context),
          
        ] else ...[
          // Fallback implementation
          _buildFallbackCard(
            context,
            title: 'Tiny Next Step',
            subtitle: '1 minute',
            icon: Icons.directions_walk,
            onTap: () => _navigateToTinyStep(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFallbackCard(
            context,
            title: 'Energy Map → Pick 1',
            subtitle: '3–5 minutes',
            icon: Icons.map_outlined,
            onTap: () => _navigateToEnergyMap(context),
            textScaler: textScaler,
          ),
          const SizedBox(height: 12),
          _buildFocusTimerFallback(context, textScaler),
        ],
      ],
    );
  }

  Widget _buildFocusTimerSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timelapse_outlined,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus Timer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your focus session length',
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
                    text: '5m',
                    selected: false,
                    onTap: () => _startFocusSession(context, 5),
                  ),
                  MtdsChip.selectable(
                    text: '10m',
                    selected: false,
                    onTap: () => _startFocusSession(context, 10),
                  ),
                  MtdsChip.selectable(
                    text: '20m',
                    selected: false,
                    onTap: () => _startFocusSession(context, 20),
                  ),
                  MtdsChip.selectable(
                    text: '25m',
                    selected: false,
                    onTap: () => _startFocusSession(context, 25),
                  ),
                  if (_lastUsedMinutes != null && ![5, 10, 20, 25].contains(_lastUsedMinutes))
                    MtdsChip.selectable(
                      text: 'Last (${_lastUsedMinutes}m)',
                      selected: false,
                      onTap: () => _startFocusSession(context, _lastUsedMinutes!),
                    ),
                ] else ...[
                  _buildFocusChip(context, '5m', 5),
                  _buildFocusChip(context, '10m', 10),
                  _buildFocusChip(context, '20m', 20),
                  _buildFocusChip(context, '25m', 25),
                  if (_lastUsedMinutes != null && ![5, 10, 20, 25].contains(_lastUsedMinutes))
                    _buildFocusChip(context, 'Last (${_lastUsedMinutes}m)', _lastUsedMinutes!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusChip(BuildContext context, String label, int minutes) {
    return A11y.ensureMinTouchTarget(
      ActionChip(
        label: Text(label),
        onPressed: () => _startFocusSession(context, minutes),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildFocusTimerFallback(BuildContext context, double textScaler) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timelapse_outlined,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus Timer',
                        style: TextStyle(
                          fontSize: 16 * textScaler,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5 / 10 / 20 / 25 / Last used',
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

  // Navigation methods
  void _navigateToTinyStep(BuildContext context) {
    Navigator.pushNamed(context, '/do/tiny-step');
  }

  void _navigateToEnergyMap(BuildContext context) {
    Navigator.pushNamed(context, '/do/energy-map');
  }

  void _startFocusSession(BuildContext context, int minutes) {
    // Save as last used duration
    FocusTimerPrefs.instance.setLastDuration(Duration(minutes: minutes));
    Navigator.pushNamed(context, '/focus', arguments: {'duration': minutes});
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