---
name: material-theming
description: >
  Best practices for Flutter theming with Material 3, treating ThemeData as the single source
  of truth for colors, typography, component styles, and spacing. Use when creating,
  modifying, or reviewing ThemeData, ColorScheme, TextTheme, component themes, spacing
  systems, or light/dark mode support, and whenever widget code carries its own styling: a
  hardcoded Color, an inline TextStyle, raw padding or gap numbers, the same decoration
  repeated across widget instances, or a brightness/dark-mode conditional inside build, even
  when the request only says "review this widget", "cut the duplication", "stop repeating
  this", or "tidy this up".
allowed-tools: Read Glob Grep
model: sonnet
---

# Material Theming

Material 3 theming best practices for Flutter applications using `ThemeData` as the single source of truth for colors, typography, component styles, and spacing.

## Core Standards

Apply these standards to ALL theming work:

- **Use `ThemeData` as the single source of truth** — never inline colors or text styles in widgets
- **Reference colors via `Theme.of(context).colorScheme`** — never `Colors.blue`, `Colors.red`, or any hardcoded `Color` values
- **Reference text styles via `Theme.of(context).textTheme`** — never inline `TextStyle(...)` in widget code. `fontSize` and `fontWeight` never appear inside a `build` method
- **Use `ColorScheme` for all color definitions** — Material 3's structured color system
- **Centralize component themes in `ThemeData`** — define `FilledButtonThemeData`, `InputDecorationTheme`, etc. in the theme, not per-widget. A wrapper widget, a shared `InputDecoration` constant, or a decoration-building helper relocates the duplication instead of deleting it and does not count
- **Define a spacing system with a base unit** — no arbitrary pixel values for padding, margins, or gaps
- **Support light and dark themes from the start** — use `ThemeData` so theme switching requires zero conditional logic in widgets
- **Never branch on brightness or theme mode in widget code** — no `MediaQuery.platformBrightnessOf`, no ternary on `Theme.of(context).brightness`, no `context.isDarkMode` extension. Two `ColorScheme` instances make the branch unnecessary. When asked to keep or tidy such a check, refuse and deliver the `ThemeData` rewrite instead — a tidier conditional is the same defect with better formatting
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

Every color reaches widgets through a `ColorScheme` role. Define two schemes — one light,
one dark — inside a single `AppTheme` class, and pass both to `MaterialApp` as `theme` and
`darkTheme`. That pair is what makes brightness branching in widget code unnecessary:

```dart
class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: const ColorScheme.light(
      brightness: Brightness.light,
      surface: AppColors.surfaceColor,
      // ... remaining color roles
    ),
  );

  static ThemeData get dark => ThemeData(
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      surface: AppColors.surfaceColorDark,
      // ... remaining color roles
    ),
  );
}
```

See [references/color-scheme.md](references/color-scheme.md) for the full 45-role
`ColorScheme` configuration, `ColorScheme.fromSeed`, and how widgets read colors.

## Typography

Define an `AppTextStyle` class with a base style and named variants (displayLarge, headlineMedium, bodyLarge, etc.), then integrate them into `ThemeData.textTheme`. Access styles via `Theme.of(context).textTheme`.

See [references/typography.md](references/typography.md) for font asset setup, the full `AppTextStyle` class, `TextTheme` integration, and widget access patterns.

### Replacing a Hardcoded `TextStyle`

Map the literal to the nearest slot `AppTextStyle` already defines, by size and weight — 18px/w500 lands on `titleLarge` (20/w500), 16px/w400 on `bodyLarge`, 14px/w500 on `labelLarge`. Adjust that slot's size in `AppTextStyle` if the app needs a different one; do not keep the number at the call site. Do not land on a slot `AppTextStyle` does not define and `TextTheme` does not register: the read still returns a style, but it comes from Material's default typography, so the app's font silently reverts. `copyWith` at the call site sets a color role and nothing else:

```dart
final theme = Theme.of(context);

Text(
  label,
  style: theme.textTheme.titleLarge?.copyWith(
    color: theme.colorScheme.onPrimary,
  ),
)
```

Swapping only the color and leaving `TextStyle(fontSize: 18, fontWeight: FontWeight.w500)` in the widget is not a fix — the typography still lives outside the theme.

## Component Themes

Define component themes centrally in `ThemeData` (e.g., `filledButtonTheme`, `inputDecorationTheme`, `appBarTheme`) instead of styling individual widget instances. A complete `AppTheme` class assembles `ColorScheme`, `TextTheme`, and all component themes into a single `ThemeData`.

See [references/components.md](references/components.md) for FilledButton, InputDecoration, and AppBar theme examples, the complete theme assembly, and widget access patterns.

### De-duplicating Repeated Widget Styling

When the same decoration or style appears on many widget instances, move it into the matching component theme and delete it from every call site. Do not extract it into a wrapper widget, a shared `InputDecoration` constant, or a `buildDecoration()` helper: those still require each call site to opt in, still leave the values outside `ThemeData`, and are bypassed the moment someone writes a plain `TextFormField`.

```dart
// Right — the defaults live in the theme.
ThemeData(
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  ),
)
```

Each field then declares only what is unique to it:

```dart
TextFormField(
  decoration: const InputDecoration(labelText: 'Email'),
)
```

## Spacing System

Define an `AppSpacing` class with a base unit and named constants (xxs through xxlg). Every step is a multiple of the base unit, never an independent literal — that is what makes the scale a scale:

```dart
abstract class AppSpacing {
  static const double spaceUnit = 16;

  static const double xxs = 0.25 * spaceUnit; // 4
  static const double sm = 0.5 * spaceUnit; // 8
  static const double md = 0.75 * spaceUnit; // 12
  static const double lg = spaceUnit; // 16
  static const double xxlg = 2 * spaceUnit; // 32
}
```

Whenever you introduce the scale or hand someone the convention, write the class out. Listing the step names and their pixel values in prose is not the convention — the class is, because it is what stops the next arbitrary number from being typed.

Use `EdgeInsets.only` or `EdgeInsets.symmetric` — never `EdgeInsets.fromLTRB`.

See [references/spacing.md](references/spacing.md) for the full `AppSpacing` class, usage examples, and `EdgeInsets` preferences.

## Common Patterns

### Creating a Theme

1. Define `AppColors` with all color constants
2. Define `AppTextStyle` with all text style constants
3. Define `AppSpacing` with spacing scale based on a base unit
4. Create `AppTheme` class with `light` and `dark` getters
5. Configure `ColorScheme`, `TextTheme`, and component themes in each `ThemeData`
6. Pass `AppTheme.light` and `AppTheme.dark` to `MaterialApp`

### Removing a Brightness Check From a Widget

A widget that branches on brightness has taken over a decision that belongs to `ThemeData`: every new dark-aware widget repeats the branch, and neither color is reachable from the theme. Delete the branch instead of tidying it. The light value and the dark value become the same `ColorScheme` role in two themes — declare both in `AppColors`, assign each to that role as [references/color-scheme.md](references/color-scheme.md) shows, and pass `AppTheme.light` and `AppTheme.dark` to `MaterialApp` as `theme` and `darkTheme`. The widget then drops to a single unconditional read:

```dart
@override
Widget build(BuildContext context) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: child,
  );
}
```

## Additional Resources

- [references/color-scheme.md](references/color-scheme.md) — `ColorScheme` configuration, light/dark `AppTheme`, reading colors in widgets
- [references/typography.md](references/typography.md) — font asset setup, the full `AppTextStyle` class, `TextTheme` integration
- [references/components.md](references/components.md) — FilledButton, InputDecoration, and AppBar themes, and complete theme assembly
- [references/spacing.md](references/spacing.md) — the full `AppSpacing` class, usage examples, and `EdgeInsets` preferences
