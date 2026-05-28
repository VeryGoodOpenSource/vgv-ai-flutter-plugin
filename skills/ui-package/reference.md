# UI Package — Reference

Concrete examples and step-by-step workflows for the UI Package skill.

---

## ThemeExtension Key Classes

| Class | Purpose |
| ----- | ------- |
| `AppColors extends ThemeExtension<AppColors>` | Custom color tokens beyond `ColorScheme` (success, warning, info + on-variants) |
| `AppSpacing extends ThemeExtension<AppSpacing>` | Spacing scale (xxs through xxlg) with `copyWith` and `lerp` |
| `AppTheme` | Composes `ThemeData` with `ColorScheme.fromSeed` + custom extensions, for light and dark variants |
| `AppThemeBuildContext` extension | Shorthand `context.appColors` and `context.appSpacing` |

Every `ThemeExtension` must implement `copyWith` and `lerp` for theme animation support.

## Test Helper

```dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
  }) {
    return pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: widget),
      ),
    );
  }
}
```

## Barrel File Example

```dart
/// My UI — a custom Flutter widget library built on Material.
library;

export 'package:flutter/material.dart';

export 'src/extensions/build_context_extensions.dart';
export 'src/theme/app_colors.dart';
export 'src/theme/app_spacing.dart';
export 'src/theme/app_theme.dart';
export 'src/widgets/app_button.dart';
export 'src/widgets/app_card.dart';
export 'src/widgets/app_text_field.dart';
```

## Widgetbook Catalog

### Key Concepts

- **Use cases**: top-level functions annotated with `@widgetbook.UseCase(name:, type:)`, one file per widget in `use_cases/`
- **Use-case decorator**: a `UseCaseDecorator` widget that wraps every use case with a consistent background
- **Theme addon**: `ThemeAddon` wired to `AppTheme.light` and `AppTheme.dark` for switching themes in the catalog
- **Code generation**: Widgetbook uses `build_runner` to scan annotations and generate `widgetbook.directories.g.dart`

### Commands

| Command | Purpose |
| ------- | ------- |
| `cd widgetbook && dart run build_runner build --delete-conflicting-outputs` | Regenerate use-case directories after adding/modifying use cases |
| `cd widgetbook && flutter run -d chrome` | Run the catalog locally |

## Common Workflows

### Adding a New Widget

1. Create `lib/src/widgets/app_<name>.dart` with a `const` constructor and documentation
2. Compose Material widgets internally; read custom tokens via `context.appColors` / `context.appSpacing`
3. Export the file from the barrel file (`lib/my_ui.dart`)
4. Create `test/src/widgets/app_<name>_test.dart` with widget tests
5. Add use cases in `widgetbook/lib/widgetbook/use_cases/app_<name>.dart` covering all variants
6. Re-run `dart run build_runner build --delete-conflicting-outputs` in `widgetbook/`

### Adding a New Custom Token

1. Add the token to the appropriate `ThemeExtension` class (`AppColors` or `AppSpacing`)
2. Update `copyWith` and `lerp` methods
3. Update `AppTheme.light` and `AppTheme.dark` to include the new token value
4. Update existing tests that construct the extension directly
5. Use the new token in widgets via the `BuildContext` extension
