# Typography

## Font Asset Organization

Store fonts in `assets/fonts/` and declare them in `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

Use `flutter_gen` to generate type-safe font family constants:

```dart
class FontFamily {
  static const String inter = 'Inter';
}
```

## Custom Text Styles Class

Centralize text style definitions for consistent updates:

```dart
abstract class AppTextStyle {
  static const _baseStyle = TextStyle(
    fontFamily: FontFamily.inter,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle displayLarge = _baseStyle.copyWith(
    fontSize: 57,
    height: 1.12,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle headlineMedium = _baseStyle.copyWith(
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle titleLarge = _baseStyle.copyWith(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle bodyLarge = _baseStyle.copyWith(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle labelLarge = _baseStyle.copyWith(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
  );
}
```

## `TextTheme` Integration

Integrate custom styles into `ThemeData.textTheme`:

```dart
ThemeData(
  textTheme: TextTheme(
    displayLarge: AppTextStyle.displayLarge,
    headlineMedium: AppTextStyle.headlineMedium,
    titleLarge: AppTextStyle.titleLarge,
    bodyLarge: AppTextStyle.bodyLarge,
    labelLarge: AppTextStyle.labelLarge,
  ),
)
```

## Accessing Text Styles

```dart
@override
Widget build(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

  return Text(
    'Hello',
    style: textTheme.headlineMedium,
  );
}
```
