---
name: vgv-material-theming
description: Best practices for Flutter theming using Material 3.
when_to_use: Use when creating, modifying, or reviewing ThemeData, ColorScheme, TextTheme, component themes, spacing systems, or light/dark mode support.
allowed-tools: Read Glob Grep
model: sonnet
---

# Theming

Material 3 theming best practices for Flutter applications using `ThemeData` as the single source of truth for colors, typography, component styles, and spacing.

## Core Standards

Apply these standards to ALL theming work:

- **Use `ThemeData` as the single source of truth** — never inline colors or text styles in widgets
- **Reference colors via `Theme.of(context).colorScheme`** — never `Colors.blue`, `Colors.red`, or any hardcoded `Color` values
- **Reference text styles via `Theme.of(context).textTheme`** — never inline `TextStyle(...)` in widget code
- **Use `ColorScheme` for all color definitions** — Material 3's structured color system
- **Centralize component themes in `ThemeData`** — define `FilledButtonThemeData`, `InputDecorationTheme`, etc. in the theme, not per-widget
- **Define a spacing system with a base unit** — no arbitrary pixel values for padding, margins, or gaps
- **Support light and dark themes from the start** — use `ThemeData` so theme switching requires zero conditional logic in widgets
- **Avoid conditional logic for theming in UI** — never check brightness in widget code; let `ThemeData` handle it
- **Prefer `EdgeInsets.only` and `EdgeInsets.symmetric`** — never `EdgeInsets.fromLTRB` (positional arguments are error-prone)

## Color System

### Custom Colors Class

Centralize all color definitions in a dedicated class:

```dart
abstract class AppColors {
  static const primaryColor = Color(0xFF4F46E5);
  static const secondaryColor = Color(0xFF9C27B0);
  static const errorColor = Color(0xFFDC2626);
  static const surfaceColor = Color(0xFFFAFAFA);
}
```

### `ColorScheme` Configuration

The `ColorScheme` class includes 45 colors based on Material 3 specifications. Configure it within `ThemeData`:

```dart
ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryColor,
    secondary: AppColors.secondaryColor,
    error: AppColors.errorColor,
    surface: AppColors.surfaceColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onError: Colors.white,
    onSurface: Colors.black,
  ),
)
```

For quick prototyping, use `ColorScheme.fromSeed()`:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
  ),
)
```

### Light and Dark Theme Variants

```dart
class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryColor,
      surface: AppColors.surfaceColor,
      // ... remaining color roles
    ),
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryColorDark,
      surface: AppColors.surfaceColorDark,
      // ... remaining color roles
    ),
  );
}
```

### Accessing Colors

```dart
@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return ColoredBox(
    color: colorScheme.surface,
    child: Text(
      'Hello',
      style: TextStyle(color: colorScheme.onSurface),
    ),
  );
}
```

## Typography

Define an `AppTextStyle` class with a base style and named variants (displayLarge, headlineMedium, bodyLarge, etc.), then integrate them into `ThemeData.textTheme`. Access styles via `Theme.of(context).textTheme`.

See [references/typography.md](references/typography.md) for font asset setup, the full `AppTextStyle` class, `TextTheme` integration, and widget access patterns.

## Component Themes

Define component themes centrally in `ThemeData` (e.g., `filledButtonTheme`, `inputDecorationTheme`, `appBarTheme`) instead of styling individual widget instances. A complete `AppTheme` class assembles `ColorScheme`, `TextTheme`, and all component themes into a single `ThemeData`.

See [references/components.md](references/components.md) for FilledButton, InputDecoration, and AppBar theme examples, the complete theme assembly, and widget access patterns.

## Spacing System

Define an `AppSpacing` class with a base unit (e.g., 16px) and named constants (xxs through xxlg). Use `EdgeInsets.only` or `EdgeInsets.symmetric` — never `EdgeInsets.fromLTRB`.

See [references/spacing.md](references/spacing.md) for the full `AppSpacing` class, usage examples, and `EdgeInsets` preferences.

## Common Patterns

### Creating a Theme

1. Define `AppColors` with all color constants
2. Define `AppTextStyle` with all text style constants
3. Define `AppSpacing` with spacing scale based on a base unit
4. Create `AppTheme` class with `light` and `dark` getters
5. Configure `ColorScheme`, `TextTheme`, and component themes in each `ThemeData`
6. Pass `AppTheme.light` and `AppTheme.dark` to `MaterialApp`

### Adding a New Color Token

1. Add the color constant to `AppColors`
2. Map it to the appropriate `ColorScheme` role (or create a theme extension for custom tokens)
3. Reference it via `Theme.of(context).colorScheme.<role>` in widgets

### Dark Mode Support

1. Create separate `ColorScheme` instances for light and dark
2. Use the same `TextTheme` and component themes (they adapt automatically via `colorScheme`)
3. Pass both themes to `MaterialApp` via `theme` and `darkTheme`
4. Never check `Brightness` in widget code — let `ThemeData` handle the switch

## Quick Reference

| ThemeData Property        | Purpose                                      |
| ------------------------- | -------------------------------------------- |
| `colorScheme`             | Material 3 color system (45 color roles)     |
| `textTheme`               | Typography scale (display, headline, body…)  |
| `filledButtonTheme`       | FilledButton default style                   |
| `inputDecorationTheme`    | TextField/TextFormField decoration defaults  |
| `appBarTheme`             | AppBar default styling                       |
| `cardTheme`               | Card default styling                         |
| `dialogTheme`             | Dialog default styling                       |

| Material 3 Color Role | Typical Use                           |
| --------------------- | ------------------------------------- |
| `primary`             | Key UI elements, FAB, active states   |
| `onPrimary`           | Text/icons on primary color           |
| `secondary`           | Less prominent UI elements            |
| `surface`             | Card, sheet, dialog backgrounds       |
| `onSurface`           | Text/icons on surface color           |
| `error`               | Error indicators, destructive actions |
| `outline`             | Borders, dividers                     |
