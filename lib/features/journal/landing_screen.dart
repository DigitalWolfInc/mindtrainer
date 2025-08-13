import 'package:flutter/material.dart';
import '../../core/feature_flags.dart';
import '../../ui/mtds/components/mtds_stack_card.dart';
import '../../ui/mtds/components/mtds_time_badge.dart';
import '../../ui/mtds/components/mtds_block.dart';
import '../../a11y/a11y.dart';
import '../../app_routes.dart';

/// Journal tab landing screen with entry options
class JournalLandingScreen extends StatelessWidget {
  const JournalLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (FeatureFlags.blocksGridEnabled) {
      final items = <MtdsBlock>[
        MtdsBlock(
          icon: Icons.edit_outlined,
          title: 'New Entry (Text)',
          subtitle: 'Capture what matters.',
          onTap: () => R.go(context, '/journal/newText'),
        ),
        MtdsBlock(
          icon: Icons.mic_outlined,
          title: 'Voice Note',
          subtitle: 'On-device when available',
          badge: '1m',
          onTap: () => R.go(context, '/journal/newVoice'),
        ),
        MtdsBlock(
          icon: Icons.photo_camera_outlined,
          title: 'Photo Note',
          subtitle: 'Save and tag',
          onTap: () => R.go(context, '/journal/newPhoto'),
        ),
        MtdsBlock(
          icon: Icons.search_outlined,
          title: 'Tags & Search',
          subtitle: 'Find past entries',
          onTap: () => R.go(context, '/journal/search'),
        ),
        MtdsBlock(
          icon: Icons.download_outlined,
          title: 'Exports (ZIP)',
          subtitle: 'Download your data',
          onTap: () => R.go(context, '/journal/exports'),
        ),
        MtdsBlock(
          icon: Icons.lock_outlined,
          title: 'Private Sub-Journal',
          subtitle: 'Extra secure space',
          badge: 'Pro',
          onTap: () => R.go(context, '/journal/private'),
        ),
        MtdsBlock(
          icon: Icons.pets_outlined,
          title: 'Animal Badges',
          subtitle: 'Earn by checking in',
          onTap: () => R.go(context, '/achievements/animals'),
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
          title: 'New Entry (Text)',
          subtitle: 'Capture what matters.',
          icon: Icons.edit_outlined,
          onTap: () => _navigateToNewEntry(context),
          textScaler: textScaler,
        ),
        const SizedBox(height: 12),
        _buildFallbackCard(
          context,
          title: 'Voice Note',
          subtitle: 'On-device when available • 1m',
          icon: Icons.mic_outlined,
          onTap: () => _navigateToVoiceNote(context),
          textScaler: textScaler,
        ),
        const SizedBox(height: 12),
        _buildFallbackCard(
          context,
          title: 'Photo Note',
          subtitle: 'Save and tag',
          icon: Icons.photo_camera_outlined,
          onTap: () => _navigateToPhotoNote(context),
          textScaler: textScaler,
        ),
        const SizedBox(height: 12),
        _buildFallbackCard(
          context,
          title: 'Tags & Search',
          subtitle: 'Find past entries',
          icon: Icons.search_outlined,
          onTap: () => _navigateToSearch(context),
          textScaler: textScaler,
        ),
        const SizedBox(height: 12),
        _buildFallbackCard(
          context,
          title: 'Exports (ZIP)',
          subtitle: 'Download your data',
          icon: Icons.download_outlined,
          onTap: () => _navigateToExports(context),
          textScaler: textScaler,
        ),
        const SizedBox(height: 12),
        _buildFallbackCard(
          context,
          title: 'Private Sub-Journal (Pro)',
          subtitle: 'Extra secure space',
          icon: Icons.lock_outlined,
          onTap: () => _navigateToPrivateJournal(context),
          textScaler: textScaler,
        ),
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
  void _navigateToNewEntry(BuildContext context) {
    Navigator.pushNamed(context, '/journal/new');
  }

  void _navigateToVoiceNote(BuildContext context) {
    Navigator.pushNamed(context, '/journal/voice');
  }

  void _navigateToPhotoNote(BuildContext context) {
    Navigator.pushNamed(context, '/journal/photo');
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, '/journal/search');
  }

  void _navigateToExports(BuildContext context) {
    Navigator.pushNamed(context, '/journal/exports');
  }

  void _navigateToPrivateJournal(BuildContext context) {
    Navigator.pushNamed(context, '/journal/private');
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