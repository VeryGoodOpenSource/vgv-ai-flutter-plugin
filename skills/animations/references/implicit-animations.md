# Implicit Animation Patterns

The default choice. The widget rebuilds with a new target value and the framework
interpolates. No `StatefulWidget`, no controller, no ticker, no `dispose`.

## Built-in AnimatedFoo Widgets

Flutter ships an `AnimatedFoo` widget for most animatable properties —
`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSlide`, `AnimatedAlign`,
`AnimatedPadding`, `AnimatedPositioned`, `AnimatedSwitcher`, and others. Use the one that
matches the property being animated.

## Composing Several Properties

Compose one `AnimatedFoo` per property when several move together. This is the
entry-animation shape — a widget hidden until its data arrives, then fading in and sliding
into place:

```dart
class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.summary, super.key});

  final Summary? summary;

  @override
  Widget build(BuildContext context) {
    final hasData = summary != null;

    return AnimatedOpacity(
      opacity: hasData ? 1 : 0,
      duration: Durations.medium2,
      curve: Easing.standard,
      child: AnimatedSlide(
        offset: hasData ? Offset.zero : const Offset(0, 0.1),
        duration: Durations.medium2,
        curve: Easing.emphasizedDecelerate,
        child: Card(child: _SummaryContents(summary: summary)),
      ),
    );
  }
}
```

Both properties animate off the same rebuild.

## TweenAnimationBuilder

Use `TweenAnimationBuilder` when no built-in `AnimatedFoo` widget exists for the property,
but you still want implicit-style "set and forget" animation.

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: isActive ? 1.0 : 0.0),
  duration: Durations.medium2,
  curve: Easing.standard,
  builder: (context, value, child) {
    return Transform.scale(
      scale: 0.8 + (0.2 * value),
      child: Opacity(
        opacity: value,
        child: child,
      ),
    );
  },
  child: child, // child is not rebuilt — optimization
)
```

The `child` parameter is critical: pass widgets that do not depend on the animated value so
they are built once instead of every frame.
