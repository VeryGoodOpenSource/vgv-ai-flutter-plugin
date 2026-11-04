# Spacing System

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
