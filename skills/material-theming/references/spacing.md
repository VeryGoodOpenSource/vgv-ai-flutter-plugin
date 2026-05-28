# Spacing System

Define a spacing system using a base unit to ensure consistency and avoid hardcoded values.

## AppSpacing Class

```dart
abstract class AppSpacing {
  static const double spaceUnit = 16;

  /// 4px
  static const double xxs = 0.25 * spaceUnit;

  /// 6px
  static const double xs = 0.375 * spaceUnit;

  /// 8px
  static const double sm = 0.5 * spaceUnit;

  /// 12px
  static const double md = 0.75 * spaceUnit;

  /// 16px
  static const double lg = spaceUnit;

  /// 24px
  static const double xlg = 1.5 * spaceUnit;

  /// 32px
  static const double xxlg = 2 * spaceUnit;
}
```

## Applying Spacing

```dart
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  ),
  child: Column(
    spacing: AppSpacing.sm,
    children: [
      // widgets
    ],
  ),
)
```

## EdgeInsets Preferences

### Prefer `EdgeInsets.only` (Named Parameters)

```dart
// Preferred — clear which side each value applies to
EdgeInsets.only(top: 16, bottom: 8)
```

### Prefer `EdgeInsets.symmetric`

```dart
// Preferred — concise when horizontal or vertical values match
EdgeInsets.symmetric(horizontal: 16, vertical: 8)
```

### Avoid `EdgeInsets.fromLTRB`

```dart
// Avoid — positional arguments make it easy to mix up sides
EdgeInsets.fromLTRB(16, 8, 16, 8)
```
