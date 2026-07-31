# Text Directionality

## The `Directionality` Widget

Flutter provides a global `Directionality` widget determined by the user's locale. You can override it explicitly:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: Row(
    children: [
      // Children laid out right-to-left
    ],
  ),
)
```

Retrieve the current direction: `Directionality.of(context)`

## Visual vs Directional Widgets

| Widget Type     | Direction Terms            | Use Case                                  |
| --------------- | -------------------------- | ----------------------------------------- |
| **Visual**      | top, left, right, bottom   | Absolute positioning that never changes   |
| **Directional** | top, start, end, bottom    | Relative to text direction (respects RTL) |

## `EdgeInsetsDirectional` vs `EdgeInsets`

Always use `EdgeInsetsDirectional` for padding and margins that should respect text direction:

```dart
// Preferred -- respects RTL
Padding(
  padding: EdgeInsetsDirectional.only(start: 12),
  child: Text('Padding at text start regardless of direction'),
)

// Only for absolute positioning that must not change
Padding(
  padding: EdgeInsets.only(left: 10),
  child: Text('Always 10px from left edge'),
)
```

Many widgets offer `Directional` variants: `PositionedDirectional`, `AlignDirectional`, `BorderDirectional`, etc.

## Icon and Image Mirroring

- **Icons** mirror automatically in RTL contexts by default. Directional Material icons (`Icons.arrow_forward`, `Icons.chevron_left`, and so on) carry `matchTextDirection: true` inside their `IconData`, so leave the `Icon` widget alone. To prevent mirroring, set the `Icon`'s `textDirection` property explicitly.
- **Images** do not mirror by default. Set `matchTextDirection: true` to mirror images in RTL.

`matchTextDirection` is a field of `IconData` and a parameter of `Image`. The `Icon` widget does not take it — `Icon(Icons.arrow_forward, matchTextDirection: true)` does not compile.

```dart
// Preferred -- the directional IconData mirrors itself; the asset needs telling
Row(
  children: [
    const Icon(Icons.arrow_forward),
    const Image(
      image: AssetImage('assets/swipe_hint.png'),
      matchTextDirection: true,
    ),
  ],
)
```

## Material Design Bidirectionality Standards

Follow Material Design conventions:

- **Mirror**: Forward/future directional indicators (arrows, chevrons)
- **Do not mirror**: Media progress indicators, negation symbols, physical objects (clocks, tools)
