# ColorScheme Configuration

`ColorScheme` carries 45 color roles based on the Material 3 specification. Configure it
inside `ThemeData`:

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

## Accessing Colors in Widgets

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
