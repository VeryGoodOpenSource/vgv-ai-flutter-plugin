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
