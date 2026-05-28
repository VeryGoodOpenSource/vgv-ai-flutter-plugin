# Component Themes

Material components use `colorScheme` and `textTheme` by default, but each widget has a customizable theme. Define component themes centrally in `ThemeData` instead of styling individual widget instances.

## FilledButton

```dart
ThemeData(
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(72, 48),
      textStyle: AppTextStyle.labelLarge,
    ),
  ),
)
```

## InputDecoration

```dart
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

## AppBar

```dart
ThemeData(
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    titleTextStyle: AppTextStyle.titleLarge,
  ),
)
```

## Complete Theme Example

```dart
class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      error: AppColors.errorColor,
      surface: AppColors.surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: Colors.black,
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: AppTextStyle.displayLarge,
        headlineMedium: AppTextStyle.headlineMedium,
        titleLarge: AppTextStyle.titleLarge,
        bodyLarge: AppTextStyle.bodyLarge,
        labelLarge: AppTextStyle.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, 48),
          textStyle: AppTextStyle.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        titleTextStyle: AppTextStyle.titleLarge,
      ),
    );
  }
}
```

## Using the Theme

```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: const HomePage(),
)
```

## Accessing Theme Properties in Widgets

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return ColoredBox(
    color: colorScheme.surface,
    child: Text('Good', style: textTheme.bodyLarge),
  );
}
```
