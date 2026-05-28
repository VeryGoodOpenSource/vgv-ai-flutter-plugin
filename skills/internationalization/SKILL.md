---
name: vgv-internationalization
description: Best practices for internationalization (i18n) and localization (l10n) in Flutter.
when_to_use: Use when adding, modifying, or reviewing ARB translations, locale setup, BuildContext l10n extensions, or RTL/directional layout support.
allowed-tools: Read Glob Grep
model: sonnet
---

# Internationalization

Internationalization (i18n) and localization (l10n) best practices for Flutter applications using Flutter's built-in localization system with ARB files as the single source of truth.

## Core Standards

Apply these standards to ALL internationalization work:

- **Never hardcode user-facing strings** — all text must go through the l10n system
- **Use Flutter's built-in localization system** — `flutter_localizations` + `intl`, never third-party i18n libraries
- **ARB files are the single source of truth** for all translations
- **`BuildContext` extension for cleaner l10n access** — use `context.l10n` instead of `AppLocalizations.of(context)`
- **Pass localized strings as parameters to reusable widgets** — never couple shared widgets directly to `AppLocalizations`
- **Use `EdgeInsetsDirectional` (start/end) instead of `EdgeInsets` (left/right)** — ensures correct layout in RTL languages
- **Handle RTL layout properly** — use directional widgets for padding, positioning, and alignment
- **Implement i18n early** — even if only one language is planned initially, the overhead is small and the long-term benefit is significant

## Key Definitions

| Term                            | Definition                                                                                            |
| ------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Locale**                      | Set of properties defining user region, language, and preferences (currency, time, numbers)           |
| **Localization (l10n)**         | Process of adapting software for a specific language by translating text and adding regional layouts  |
| **Internationalization (i18n)** | Process of designing software so it can be adapted to different languages without engineering changes |

## Setup Pipeline and ARB File Format

Add `flutter_localizations` and `intl` as dependencies, enable `generate: true` in `pubspec.yaml`, configure `l10n.yaml`, create ARB files in `lib/l10n/arb/`, run `flutter gen-l10n`, and wire up `MaterialApp` with `localizationsDelegates` and `supportedLocales`. ARB files support simple strings, placeholders, and ICU plural syntax.

See [references/setup.md](references/setup.md) for the full step-by-step setup pipeline and ARB file format examples.

## BuildContext Extension

Create an extension for ergonomic l10n access throughout the codebase:

```dart
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

Usage:

```dart
// Preferred
Text(context.l10n.helloWorld);

// Avoid
Text(AppLocalizations.of(context).helloWorld);
```

## Reusable Widget Strategy

Shared widgets that live in separate packages should not depend on `AppLocalizations` directly. Instead, pass localized strings as constructor parameters:

```dart
// Shared widget — no l10n dependency
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(cancelLabel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
      ],
    );
  }
}

// App-level usage — passes localized strings
showDialog<bool>(
  context: context,
  builder: (_) => ConfirmDialog(
    title: context.l10n.deleteTitle,
    message: context.l10n.deleteMessage,
    confirmLabel: context.l10n.confirm,
    cancelLabel: context.l10n.cancel,
  ),
);
```

## Text Directionality

Use `EdgeInsetsDirectional` (start/end) instead of `EdgeInsets` (left/right) for all padding and margins. Use directional widget variants (`PositionedDirectional`, `AlignDirectional`, `BorderDirectional`) for RTL-aware layouts. Icons mirror automatically in RTL; images require `matchTextDirection: true`.

See [references/directionality.md](references/directionality.md) for the full directionality guide including visual vs directional widgets, icon/image mirroring rules, and Material Design bidirectionality standards.

## Backend Considerations

Store backend content with per-locale translations and require clients to transmit the user's locale. For error messages, map HTTP status codes or custom backend error constants to l10n keys on the frontend.

See [references/backend.md](references/backend.md) for multi-language content storage patterns and error message localization approaches.

## Common Patterns

### Adding a New Locale

1. Create `app_<locale>.arb` in `lib/l10n/arb/` (e.g., `app_fr.arb`)
2. Add translations for all keys from the template ARB file
3. Run `flutter gen-l10n`
4. The new locale is automatically available through `AppLocalizations.supportedLocales`

### Adding a New String

1. Add the key-value pair to the template ARB file (`app_en.arb`)
2. Add the `@key` metadata with description and placeholders if needed
3. Add translations in all other ARB files
4. Run `flutter gen-l10n`
5. Use via `context.l10n.newKey`

### Pluralization

1. Define the plural string in the template ARB file using ICU message syntax
2. Provide placeholder metadata with `"type": "int"`
3. Add plural forms in all locale ARB files
4. Use via `context.l10n.itemCount(items.length)`

## Quick Reference

| Package                 | Purpose                                 |
| ----------------------- | --------------------------------------- |
| `flutter_localizations` | Flutter's built-in localization support |
| `intl`                  | Internationalization utilities          |

| Command            | Purpose                                      |
| ------------------ | -------------------------------------------- |
| `flutter gen-l10n` | Generate localization classes from ARB files |

| File               | Purpose                                            |
| ------------------ | -------------------------------------------------- |
| `l10n.yaml`        | Localization configuration (ARB dir, output, etc.) |
| `app_en.arb`       | Template ARB file (source of truth)                |
| `app_<locale>.arb` | Translated ARB file for each locale                |
