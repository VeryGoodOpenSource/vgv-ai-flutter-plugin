# ColorScheme Configuration

For quick prototyping, use `ColorScheme.fromSeed()`:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
  ),
)
```

Since Flutter 3.41, `ColorScheme.fromSeed`, `ColorScheme.fromImageProvider`, and
`ThemeData(colorSchemeSeed: ...)` generate `onPrimaryContainer`,
`onSecondaryContainer`, `onTertiaryContainer`, and `onErrorContainer` differently. To keep the
old colors, set those roles explicitly with `copyWith` after generation, then update goldens.

## Light and Dark Theme Variants

Two `ColorScheme` instances, one `AppTheme` class. This is what makes brightness branching
in widget code unnecessary.

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

Pass both to `MaterialApp` as `theme` and `darkTheme`.
