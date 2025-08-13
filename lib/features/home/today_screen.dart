import 'package:flutter/material.dart';
import '../../core/feature_flags.dart';
import '../../ui/mtds/components/mtds_stack_card.dart';
import '../../ui/mtds/components/mtds_time_badge.dart';
import '../../ui/mtds/components/mtds_header.dart';
import '../../a11y/a11y.dart';
import '../focus_session/presentation/home_screen.dart' as legacy;

/// Today screen - primary entry point with Journal, Coach, Focus cards
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    // If home cards feature is disabled, fallback to legacy
    if (!FeatureFlags.ff_home_cards_journal_coach) {
      return const legacy.HomeScreen();
    }
    
    return Scaffold(
      backgroundColor: FeatureFlags.mtdsThemeEnabled ? null : Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // App header
            if (FeatureFlags.mtdsComponentsEnabled)
              const MtdsHeader(
                title: 'MindTrainer', 
                subtitle: 'A calm mind isn\'t out of reach.',
              )
            else
              _buildFallbackHeader(context, textScaler),
            
            const SizedBox(height: 24),
            
            // Three primary cards
            _buildPrimaryCard(
              context,
              title: 'Journal',
              subtitle: 'Capture what matters. Even offline.',
              icon: Icons.edit_outlined,
              onTap: () => _navigateToJournal(context),
              textScaler: textScaler,
            ),
            
            const SizedBox(height: 12),
            
            _buildPrimaryCard(
              context,
              title: 'Talk to Coach',
              subtitle: 'Talk it out. I\'ll guide the next step.',
              icon: Icons.chat_bubble_outline,
              onTap: () => _navigateToCoach(context),
              textScaler: textScaler,
            ),
            
            const SizedBox(height: 12),
            
            // Focus card - only show if feature flag is enabled
            if (FeatureFlags.homeFocusCardEnabled) ...[
              _buildPrimaryCard(
                context,
                title: 'Start Focus Session',
                subtitle: 'Settle in for a block. • 25m',
                icon: Icons.timelapse_outlined,
                onTap: () => _navigateToFocus(context),
                textScaler: textScaler,
                trailing: FeatureFlags.mtdsComponentsEnabled 
                    ? const MtdsTimeBadge(minutes: 25)
                    : _buildTimeBadge(25),
              ),
              const SizedBox(height: 12),
            ],
            
            const SizedBox(height: 20),
            
            // Quick access to legacy tools (behind flag)
            if (!FeatureFlags.ff_mtds_restyle_primary_screens)
              _buildLegacyToolsSection(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFallbackHeader(BuildContext context, double textScaler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MindTrainer',
          style: TextStyle(
            fontSize: 28 * textScaler,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A calm mind isn\'t out of reach.',
          style: TextStyle(
            fontSize: 16 * textScaler,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPrimaryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required double textScaler,
    Widget? trailing,
  }) {
    if (FeatureFlags.mtdsComponentsEnabled) {
      return MtdsStackCard(
        title: title,
        subtitle: subtitle,
        leadingIcon: icon,
        onTap: onTap,
        trailing: trailing,
      );
    }
    
    // Fallback implementation
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
                          fontSize: 18 * textScaler,
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
                if (trailing != null) trailing,
                const SizedBox(width: 8),
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
  
  Widget _buildTimeBadge(int minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${minutes}m',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }
  
  Widget _buildLegacyToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Tools',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _navigateToLegacyHome(context),
          icon: const Icon(Icons.grid_view),
          label: const Text('View All Tools'),
        ),
      ],
    );
  }
  
  void _navigateToJournal(BuildContext context) {
    Navigator.pushNamed(context, '/journal');
  }
  
  void _navigateToCoach(BuildContext context) {
    Navigator.pushNamed(context, '/coach');
  }
  
  void _navigateToFocus(BuildContext context) {
    Navigator.pushNamed(context, '/focus');
  }
  
  void _navigateToLegacyHome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const legacy.HomeScreen()),
    );
  }
}