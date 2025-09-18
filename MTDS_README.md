# MindTrainer Design System (MTDS) v1

The MindTrainer Design System provides a cohesive visual language and component library for the MindTrainer Flutter app. All components follow accessibility standards and support the "Midnight Calm" design theme.

## 🎯 Feature Flags

MTDS is controlled by feature flags for safe rollout:

```dart
// Enable/disable via environment variables or toggle programmatically
ff_mtds_theme_midnight_calm      // Core theme (OFF by default for release safety)
ff_mtds_components_v1           // Component library 
ff_mtds_restyle_primary_screens // Screen restyling
ff_mtds_showcase_debug          // Debug showcase (debug-only)
```

### Toggle Feature Flags

**For testing in development:**
```bash
flutter run --dart-define=ff_mtds_theme_midnight_calm=true
```

**In code (debug builds only):**
```dart
import 'core/feature_flags.dart';

if (FeatureFlags.mtdsThemeEnabled) {
  // MTDS theme is active
}
```

## 🎨 Design Tokens

### Colors (Midnight Calm Palette)
```dart
MtdsColors.bgTop          // #0D1B2A - Background gradient top
MtdsColors.bgBottom       // #0A1622 - Background gradient bottom  
MtdsColors.surface        // #0F2436 - Card/surface color
MtdsColors.textPrimary    // #F2F5F7 - Primary text
MtdsColors.textSecondary  // #C7D1DD - Secondary text
MtdsColors.accent         // #6EA8FF - Primary accent
MtdsColors.success        // #7ED3B2 - Success state
MtdsColors.warning        // #FFD084 - Warning state
```

### Typography Scale
```dart
MtdsTypography.display    // 32/38 SemiBold - Page headers
MtdsTypography.title      // 24/30 SemiBold - Section titles  
MtdsTypography.body       // 16/24 Regular - Body text
MtdsTypography.button     // 17/22 SemiBold - Button text
MtdsTypography.overline   // 12/16 SemiBold - Small labels
```

### Spacing & Layout
```dart
MtdsSpacing.xs    // 4px
MtdsSpacing.sm    // 8px  
MtdsSpacing.lg    // 16px
MtdsSpacing.xl    // 24px
MtdsSpacing.xxl   // 32px

MtdsRadius.card   // 20px - Cards
MtdsRadius.chip   // 12px - Chips
MtdsRadius.pill   // 28px - Buttons

MtdsSizes.minTouchTarget  // 48px - Minimum tap target
MtdsSizes.pillButtonHeight // 56px - Primary buttons
```

## 📚 Component Library

### Layout Components

**MtdsScaffold** - Gradient background scaffold
```dart
MtdsScaffold(
  body: YourContent(),
  appBar: AppBar(title: Text('Title')),
)
```

**MtdsHeader** - Page headers with subtitles
```dart
MtdsHeader(
  title: 'Page Title',
  subtitle: 'Optional description',
)
```

### Interactive Components

**MtdsStackCard** - Primary list card
```dart
MtdsStackCard(
  title: 'Card Title',
  subtitle: 'Description',
  leadingIcon: Icons.star,
  trailing: MtdsTimeBadge(minutes: 5),
  onTap: () => {},
)
```

**MtdsPrimaryPillButton** - Main CTA button
```dart
MtdsPrimaryPillButton(
  text: 'Button Text',
  icon: Icons.star,  // Optional
  onPressed: () => {},
)
```

**MtdsChip** - Selectable chips
```dart
MtdsChip.selectable(
  text: 'Chip Label',
  selected: isSelected,
  onTap: () => toggleSelection(),
)
```

### Pro Features

**MtdsProLock** - Soft lock overlay for Pro features
```dart
MtdsProLock(
  onUpgradeTap: () => showUpgradeDialog(),
  child: YourProFeature(),
)
```

### Accessibility Features

- **Minimum 48px touch targets** - All interactive elements
- **AA contrast ratios** - Text against all backgrounds  
- **Large text support** - Up to 140% scaling without overflow
- **Reduced motion** - Respects system preferences
- **Semantic labels** - Screen reader support

## 🧪 Testing & QA

### Visual Showcase (Debug Only)

Access the component gallery in debug builds:
```dart
Navigator.pushNamed(context, '/mtds-showcase');
```

**Prerequisites:**
- Debug build (`flutter run`)
- Feature flag enabled: `ff_mtds_showcase_debug=true`

### Golden Tests

Generate/update visual regression baselines:
```bash
flutter test test/goldens/mtds_components_golden_test.dart --update-goldens
```

Run golden tests (CI/validation):
```bash
flutter test test/goldens/
```

### Large Text Testing

Test components at 140% text scale:
```bash
flutter run --dart-define=flutter.test.fonts=true
# Then adjust system text size to maximum
```

## 🚀 Migration Guide

### Applying MTDS to Existing Screens

1. **Wrap with MtdsScaffold:**
```dart
// Before
Scaffold(body: MyContent())

// After  
MtdsScaffold(body: MyContent())
```

2. **Replace ad-hoc cards with MtdsStackCard:**
```dart
// Before
Card(child: ListTile(...))

// After
MtdsStackCard(title: '...', onTap: ...)
```

3. **Update buttons:**
```dart
// Before
ElevatedButton(child: Text('Action'), onPressed: ...)

// After
MtdsPrimaryPillButton(text: 'Action', onPressed: ...)
```

### Screen-Specific Integration

Components are designed to wrap existing functionality without breaking logic:

```dart
// Example: Existing journal screen
class JournalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FeatureFlags.mtdsRestyleEnabled
        ? _buildMtdsVersion()
        : _buildLegacyVersion();
  }
  
  Widget _buildMtdsVersion() {
    return MtdsScaffold(
      body: Column(children: [
        MtdsHeader(title: 'Journal', subtitle: 'Capture your thoughts'),
        // Existing journal logic wrapped in MTDS components
      ]),
    );
  }
}
```

## 🎯 Production Rollout

1. **Enable theme:** `ff_mtds_theme_midnight_calm=true`
2. **Enable components:** `ff_mtds_components_v1=true`  
3. **Enable screen restyling:** `ff_mtds_restyle_primary_screens=true`
4. **Monitor:** Check analytics for any usability regressions
5. **Iterate:** Adjust based on user feedback

**Rollback:** Set feature flags to `false` to revert instantly.

---

*MTDS v1 implements the "Midnight Calm" design language with surgical, feature-flagged rollout for zero risk deployment.*