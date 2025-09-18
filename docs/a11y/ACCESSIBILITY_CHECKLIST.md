# Accessibility Checklist for MindTrainer

This checklist ensures that all features in MindTrainer meet WCAG guidelines and provide an excellent experience for users with disabilities.

## Touch Targets

- [ ] All interactive elements are at least 44×44 dp
- [ ] Buttons use `A11y.ensureMinTouchTarget()` wrapper
- [ ] Icon buttons have sufficient padding
- [ ] Touch targets don't overlap

**Implementation:**
```dart
// Good
A11y.accessibleButton(
  label: strings.startFocus,
  hint: strings.a11yStartButton,
  onPressed: _onStart,
  child: Text('Start'),
)

// Or use extension
ElevatedButton(
  onPressed: _onStart,
  child: Text('Start'),
).minTouchTarget()
```

## Semantic Labels & Hints

- [ ] All interactive widgets have descriptive labels
- [ ] Complex interactions include helpful hints
- [ ] Labels describe the element's purpose, not appearance
- [ ] Hints explain the action or result

**Implementation:**
```dart
// Timer with live region
A11y.accessibleTimer(
  timeText: '25:00',
  context: context,
)

// Pro feature lock
A11y.proLockIndicator(
  context: context,
  onTap: _showUpgrade,
)
```

## Focus Order

- [ ] Logical tab order follows visual layout
- [ ] Focus traversal is set for complex screens
- [ ] Focus indicators are visible
- [ ] Skip links provided where appropriate

**Implementation:**
```dart
FocusTraversalGroup(
  child: Column(
    children: [
      widget1.focusOrder(1.0),
      widget2.focusOrder(2.0),
      widget3.focusOrder(3.0),
    ],
  ),
)
```

## Dynamic Type

- [ ] Text scales with system text size settings
- [ ] Scale factor is clamped to reasonable bounds (0.8 - 2.0)
- [ ] Layout adapts to larger text sizes
- [ ] No text truncation at maximum scale

**Implementation:**
```dart
final textScaler = A11y.getClampedTextScale(context);

Text(
  'Focus Session',
  style: TextStyle(
    fontSize: 24 * textScaler,
    fontWeight: FontWeight.bold,
  ),
)
```

## High Contrast Mode

- [ ] Colors have sufficient contrast ratios
- [ ] High contrast mode available in settings
- [ ] Borders and outlines enhanced in high contrast
- [ ] Text remains readable in all contrast modes

**Implementation:**
```dart
final theme = A11yTheme.adjustForHighContrast(baseTheme, highContrast);

// Or manually adjust colors
final color = A11y.contrastOn(Colors.blue, highContrast);
final textColor = A11y.textColorForBackground(backgroundColor, highContrast);
```

## Screen Reader Support

- [ ] All content is accessible to screen readers
- [ ] Images have appropriate semantic labels
- [ ] Decorative images are marked as decorative
- [ ] Live regions update screen readers
- [ ] Headers are properly marked

**Implementation:**
```dart
// Header
Semantics(
  header: true,
  label: strings.settingsTitle,
  child: Text(strings.settingsTitle),
)

// Live region for dynamic content
Semantics(
  liveRegion: true,
  label: 'Session timer: $timeRemaining',
  child: TimerWidget(),
)

// Decorative image
Semantics(
  excludeSemantics: true,
  child: Image.asset('decorative_image.png'),
)
```

## Reduced Motion

- [ ] Animations respect system reduced motion preference
- [ ] Essential animations can be disabled
- [ ] Alternative feedback provided when animations disabled

**Implementation:**
```dart
final reduceMotion = A11y.prefersReducedMotion(context);

AnimatedContainer(
  duration: reduceMotion ? Duration.zero : Duration(milliseconds: 300),
  // ...
)
```

## Testing Procedures

### Automated Testing

```bash
# Run accessibility tests
flutter test test/a11y/

# Check for semantic nodes
flutter test --coverage test/a11y/a11y_basic_test.dart
```

### Manual Testing

1. **Screen Reader Testing**
   - Enable TalkBack (Android) or VoiceOver (iOS)
   - Navigate entire app using only screen reader
   - Verify all content is announced correctly
   - Test live regions update properly

2. **High Contrast Testing**
   - Enable high contrast mode in accessibility settings
   - Verify all text is readable
   - Check that interactive elements are clearly defined

3. **Large Text Testing**
   - Set system text size to maximum
   - Verify no text is truncated
   - Check that layouts adapt appropriately

4. **Touch Target Testing**
   - Use device with smaller screen
   - Verify all buttons are easily tappable
   - Test with external stylus or assistive devices

5. **Focus Testing**
   - Connect external keyboard
   - Navigate using Tab key
   - Verify focus order is logical
   - Check focus indicators are visible

### Real Device Testing

Test on actual devices with users who:
- Use screen readers regularly
- Have motor impairments
- Have visual impairments
- Use assistive technologies

## Common Issues & Solutions

### Issue: Button too small
```dart
// Bad
IconButton(icon: Icon(Icons.settings), onPressed: _onSettings)

// Good
A11y.accessibleIconButton(
  icon: Icons.settings,
  label: strings.a11ySettingsButton,
  onPressed: _onSettings,
)
```

### Issue: Missing semantic information
```dart
// Bad
GestureDetector(
  onTap: _onTap,
  child: Container(child: Icon(Icons.star)),
)

// Good
Semantics(
  label: 'Add to favorites',
  button: true,
  child: GestureDetector(
    onTap: _onTap,
    child: Container(child: Icon(Icons.star)),
  ),
)
```

### Issue: Poor contrast
```dart
// Bad
Text(
  'Welcome',
  style: TextStyle(color: Colors.grey[400]),
)

// Good
final textColor = A11y.textColorForBackground(
  Theme.of(context).scaffoldBackgroundColor,
  A11ySettings.isHighContrastEnabled(context),
);
Text(
  'Welcome',
  style: TextStyle(color: textColor),
)
```

## Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

## Maintenance

- Review this checklist before each release
- Update as new accessibility features are added
- Test with real users regularly
- Monitor accessibility feedback from users
