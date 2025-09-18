# Internationalization (i18n) System

MindTrainer uses a CSV-based i18n system that generates type-safe Dart code for multiple locales.

## Supported Locales

- **English (en)** - Primary language
- **Spanish (es)** - Secondary language

## File Structure

```
assets/i18n/
├── en.csv    # Combined CSV with all locales
└── es.csv    # (Legacy - not used)

lib/i18n/
├── i18n.dart        # Helper classes and extensions
└── strings.g.dart   # Generated code (DO NOT EDIT)

tool/i18n/
└── build_i18n.dart  # Code generation script
```

## CSV Format

The main CSV file (`assets/i18n/en.csv`) contains all locales:

```csv
key,en,es
app_name,MindTrainer,MindTrainer
app_subtitle,Transform your mind...,Transforma tu mente...
settings_title,Settings,Configuración
```

### CSV Rules

1. **Header row**: `key,en,es` (must be first line)
2. **Comments**: Lines starting with `#` are ignored
3. **Empty lines**: Ignored for organization
4. **Keys**: Use snake_case, must be valid Dart identifiers
5. **Values**: No commas allowed unless quoted with `"value,with,comma"`
6. **Escaping**: Use `""` for quotes in values

### Key Naming Conventions

- **Screen/section prefix**: `settings_`, `home_`, `pro_`
- **Component type**: `_title`, `_button`, `_hint`, `_error`
- **Action verbs**: `start_`, `cancel_`, `confirm_`
- **Accessibility**: `a11y_` prefix for screen reader labels

Examples:
```csv
# Screen titles
home_title,Focus Session,Sesión de Concentración
settings_title,Settings,Configuración

# Buttons
action_start,Start,Iniciar
action_cancel,Cancel,Cancelar

# Accessibility
a11y_start_button,Start focus session,Iniciar sesión de concentración
a11y_back_button,Go back,Volver
```

## Adding New Strings

1. **Edit the CSV file**: Add new rows to `assets/i18n/en.csv`
2. **Generate code**: Run the build script
3. **Use in code**: Access via `context.strings.keyName`

### Step-by-step Example

1. Add to CSV:
```csv
welcome_message,Welcome to MindTrainer!,¡Bienvenido a MindTrainer!
```

2. Generate code:
```bash
dart run tool/i18n/build_i18n.dart
```

3. Use in Flutter:
```dart
Widget build(BuildContext context) {
  final strings = context.strings;
  return Text(strings.welcomeMessage);
}
```

## Build Script Usage

### Running the Generator

```bash
# From project root
dart run tool/i18n/build_i18n.dart
```

### Generated Output

The script generates `lib/i18n/strings.g.dart` with:
- Abstract base class `AppStrings`
- Concrete classes for each locale (`AppStringsEN`, `AppStringsES`)
- Factory function `getStrings(localeCode)`
- BuildContext extension for easy access

## Usage in Flutter Code

### Basic Usage

```dart
import 'package:mindtrainer/i18n/i18n.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    
    return Column(
      children: [
        Text(strings.appName),
        Text(strings.appSubtitle),
        ElevatedButton(
          onPressed: () {},
          child: Text(strings.actionStart),
        ),
      ],
    );
  }
}
```

### Safe Access (Error Handling)

```dart
// Use safeStrings for error-resistant access
final strings = context.safeStrings;
```

### Parameter Substitution

```dart
// In CSV
save_percent,Save {percent}% vs monthly,Ahorra {percent}% vs mensual

// In code
final message = strings.replace(
  strings.savePercent,
  {'percent': 20},
);
// Result: "Save 20% vs monthly"
```

### Pluralization

```dart
// Simple plural helper
final sessionText = I18nHelpers.plural(
  'session',   // singular
  'sessions',  // plural
  sessionCount,
);
```

## App Integration

### MaterialApp Setup

```dart
MaterialApp(
  localizationsDelegates: const [
    AppLocalizationDelegate(),
    // Other delegates...
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('es'),
  ],
  home: MyHomePage(),
)
```

### Locale Selection

```dart
// Get available locales
final locales = AppLocales.supported;

// Check if locale is supported
if (AppLocales.isSupported('fr')) {
  // French is supported
}

// Resolve locale preference
final effectiveLocale = I18nConfig.resolveLocale(
  userPreference, // 'system', 'en', 'es'
  context,
);
```

## Review Checklist

Before merging changes that add/modify strings:

- [ ] All new keys follow naming conventions
- [ ] Translations provided for all supported locales
- [ ] No grammar/spelling errors in any language
- [ ] Parameter substitutions work correctly
- [ ] Generated code compiles without errors
- [ ] UI layouts work with longer translations
- [ ] Accessibility strings are descriptive
- [ ] Context is clear for translators

## Translation Guidelines

### For Translators

1. **Maintain tone**: Keep the app's calm, supportive tone
2. **Context matters**: Consider where the text appears
3. **Length constraints**: Some UI elements have space limits
4. **Cultural adaptation**: Adapt metaphors and examples
5. **Accessibility**: Screen reader text should be natural

### Common Translation Patterns

| English Pattern | Spanish Pattern | Notes |
|---|---|---|
| "Start Session" | "Iniciar Sesión" | Action buttons |
| "Focus Session" | "Sesión de Concentración" | Noun phrases |
| "Settings" | "Configuración" | Screen titles |
| "Pro Feature" | "Función Pro" | Feature names |

## Testing Translations

### Manual Testing

1. Switch device language to each supported locale
2. Navigate through entire app
3. Check for:
   - Text overflow/truncation
   - Misaligned layouts
   - Untranslated strings
   - Context-inappropriate translations

### Automated Testing

```dart
// Test string generation
testWidgets('should load Spanish strings', (tester) async {
  final strings = getStrings('es');
  expect(strings.appName, equals('MindTrainer'));
  expect(strings.settingsTitle, equals('Configuración'));
});
```

## Troubleshooting

### Common Issues

**Issue**: "No strings found"
- Check CSV file syntax
- Verify header row format
- Run build script

**Issue**: "Missing translation"
- Add missing values to CSV
- Regenerate code
- Check for typos in locale codes

**Issue**: "Text doesn't update"
- Hot reload/restart app
- Check locale resolution logic
- Verify MaterialApp setup

### Debug Information

```dart
// Log current locale
debugPrint('Current locale: ${Localizations.localeOf(context)}');

// Check string resolution
final strings = context.strings;
debugPrint('Using strings: ${strings.runtimeType}');
```

## Future Enhancements

- **Additional locales**: French, German, Portuguese
- **RTL support**: Arabic, Hebrew layouts
- **Context-aware translations**: Formal/informal modes
- **Pluralization rules**: Language-specific plural forms
- **Date/time formatting**: Locale-appropriate formats

## Maintenance

- Review translations quarterly
- Update when new features are added
- Monitor user feedback for translation issues
- Keep CSV files in version control
- Document translation decisions
