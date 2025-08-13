/// MTDS Showcase - Debug-only component gallery for visual QA
/// Only available when ff_mtds_showcase_debug is enabled
library mtds_showcase;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../mtds.dart';
import '../../../core/feature_flags.dart';

/// Main showcase screen - only available in debug mode
class MtdsShowcase extends StatefulWidget {
  const MtdsShowcase({super.key});

  /// Check if showcase should be available
  static bool get isAvailable => kDebugMode && FeatureFlags.mtdsShowcaseEnabled;

  @override
  State<MtdsShowcase> createState() => _MtdsShowcaseState();
}

class _MtdsShowcaseState extends State<MtdsShowcase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _chipSelected = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MtdsShowcase.isAvailable) {
      return const Scaffold(
        body: Center(
          child: Text('Showcase only available in debug with flag enabled'),
        ),
      );
    }

    return MtdsScaffold(
      appBar: AppBar(
        title: const Text('MTDS Showcase'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Components'),
            Tab(text: 'Typography'),
            Tab(text: 'Colors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComponentsTab(),
          _buildTypographyTab(),
          _buildColorsTab(),
        ],
      ),
    );
  }

  Widget _buildComponentsTab() {
    return ListView(
      padding: const EdgeInsets.all(MtdsSpacing.lg),
      children: [
        const MtdsHeader(
          title: 'MTDS Components',
          subtitle: 'All components in the design system',
        ),
        
        // Stack Cards
        const MtdsSectionHeader(text: 'Stack Cards'),
        MtdsStackCard(
          title: 'Journal Entry',
          subtitle: 'Capture thoughts and moments',
          leadingIcon: Icons.edit_outlined,
          onTap: () {},
          trailing: const MtdsTimeBadge(minutes: 5),
        ),
        const SizedBox(height: MtdsSpacing.md),
        MtdsStackCard(
          title: 'Talk to Coach',
          subtitle: 'Get guidance when you need it',
          leadingIcon: Icons.psychology_outlined,
          onTap: () {},
        ),
        const SizedBox(height: MtdsSpacing.md),
        MtdsStackCard(
          title: 'Disabled Card',
          subtitle: 'This card is disabled',
          leadingIcon: Icons.block,
          enabled: false,
        ),
        
        // Buttons
        const MtdsSectionHeader(text: 'Buttons'),
        MtdsPrimaryPillButton(
          text: 'Primary Action',
          onPressed: () {},
        ),
        const SizedBox(height: MtdsSpacing.md),
        MtdsPrimaryPillButton(
          text: 'With Icon',
          icon: Icons.star,
          onPressed: () {},
        ),
        const SizedBox(height: MtdsSpacing.md),
        const MtdsPrimaryPillButton(
          text: 'Disabled',
          state: MtdsButtonState.disabled,
        ),
        
        // Chips  
        const MtdsSectionHeader(text: 'Chips'),
        Row(
          children: [
            MtdsChip.selectable(
              text: 'Wired',
              selected: _chipSelected,
              onTap: () => setState(() => _chipSelected = !_chipSelected),
            ),
            const SizedBox(width: MtdsSpacing.sm),
            MtdsChip.selectable(
              text: 'Stuck',
              selected: false,
              onTap: () {},
            ),
            const SizedBox(width: MtdsSpacing.sm),
            MtdsChip.enabled(
              text: 'Disabled',
              selected: false,
              enabled: false,
            ),
          ],
        ),
        
        // Time Badges
        const MtdsSectionHeader(text: 'Time Badges'),
        const Row(
          children: [
            MtdsTimeBadgeRow(durations: [1, 3, 5, 10]),
          ],
        ),
        
        // List Tiles
        const MtdsSectionHeader(text: 'List Tiles'),
        MtdsListTile(
          title: 'Setting Item',
          subtitle: 'With description',
          leading: const Icon(Icons.settings),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        MtdsListTile(
          title: 'Disabled Item',
          leading: Icon(Icons.block),
          enabled: false,
        ),
        
        // Pro Lock
        const MtdsSectionHeader(text: 'Pro Lock'),
        MtdsProLock(
          onUpgradeTap: () {},
          child: const MtdsStackCard(
            title: 'Pro Feature',
            subtitle: 'This requires upgrade',
            leadingIcon: Icons.star,
          ),
        ),
        
        // Special Components
        const MtdsSectionHeader(text: 'Special Components'),
        Row(
          children: [
            MtdsBrainMicFab(
              onTap: () {},
              onTapHold: () {},
            ),
            const SizedBox(width: MtdsSpacing.lg),
          ],
        ),
        const SizedBox(height: MtdsSpacing.lg),
        MtdsSosRibbon(onTap: () {}),
      ],
    );
  }

  Widget _buildTypographyTab() {
    return ListView(
      padding: const EdgeInsets.all(MtdsSpacing.lg),
      children: [
        const MtdsHeader(title: 'Typography Scale'),
        
        _buildTypographyExample('Display', MtdsTypography.display),
        _buildTypographyExample('Title', MtdsTypography.title),
        _buildTypographyExample('Body', MtdsTypography.body),
        _buildTypographyExample('Button', MtdsTypography.button),
        _buildTypographyExample('Overline', MtdsTypography.overline),
      ],
    );
  }
  
  Widget _buildTypographyExample(String name, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MtdsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: MtdsTypography.overline.copyWith(
              color: MtdsColors.textSecondary,
            ),
          ),
          const SizedBox(height: MtdsSpacing.sm),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: style.copyWith(color: MtdsColors.textPrimary),
          ),
          const SizedBox(height: MtdsSpacing.xs),
          Text(
            'Size: ${style.fontSize}px, Weight: ${style.fontWeight}',
            style: MtdsTypography.body.copyWith(
              color: MtdsColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorsTab() {
    return ListView(
      padding: const EdgeInsets.all(MtdsSpacing.lg),
      children: [
        const MtdsHeader(title: 'Color Palette'),
        
        const MtdsSectionHeader(text: 'Background Colors'),
        _buildColorRow([
          ('bgTop', MtdsColors.bgTop),
          ('bgBottom', MtdsColors.bgBottom),
        ]),
        
        const MtdsSectionHeader(text: 'Surface Colors'),
        _buildColorRow([
          ('surface', MtdsColors.surface),
          ('outline', MtdsColors.outline),
        ]),
        
        const MtdsSectionHeader(text: 'Text Colors'),
        _buildColorRow([
          ('textPrimary', MtdsColors.textPrimary),
          ('textSecondary', MtdsColors.textSecondary),
        ]),
        
        const MtdsSectionHeader(text: 'Accent Colors'),
        _buildColorRow([
          ('accent', MtdsColors.accent),
          ('accentPressed', MtdsColors.accentPressed),
          ('accentDisabled', MtdsColors.accentDisabled),
        ]),
        
        const MtdsSectionHeader(text: 'Status Colors'),
        _buildColorRow([
          ('success', MtdsColors.success),
          ('warning', MtdsColors.warning),
        ]),
      ],
    );
  }
  
  Widget _buildColorRow(List<(String, Color)> colors) {
    return Wrap(
      spacing: MtdsSpacing.md,
      runSpacing: MtdsSpacing.md,
      children: colors.map((colorData) {
        final (name, color) = colorData;
        return _buildColorSwatch(name, color);
      }).toList(),
    );
  }
  
  Widget _buildColorSwatch(String name, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(MtdsRadius.card),
            border: Border.all(color: MtdsColors.outline),
          ),
        ),
        const SizedBox(height: MtdsSpacing.xs),
        Text(
          name,
          style: MtdsTypography.body.copyWith(
            color: MtdsColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          style: MtdsTypography.body.copyWith(
            color: MtdsColors.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}