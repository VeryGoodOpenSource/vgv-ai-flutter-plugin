# Text Directionality

## Icon and Image Mirroring

- **Icons** mirror automatically in RTL contexts by default. Directional Material icons (`Icons.arrow_forward`, `Icons.chevron_left`, and so on) carry `matchTextDirection: true` inside their `IconData`, so leave the `Icon` widget alone. To prevent mirroring, set the `Icon`'s `textDirection` property explicitly.

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

## `WidgetSpan` in RTL Text

Since Flutter 3.50, `WidgetSpan` placeholders in RTL and mixed-direction text follow Unicode
bidi visual order. Keep spans in the logical order of the content. Do not reverse span order,
offset inline widgets with `Transform.translate`, or mirror placeholder x-coordinates; remove
any such workaround and update RTL goldens.
