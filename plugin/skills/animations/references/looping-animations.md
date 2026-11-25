# Repeating and Looping Animations

On Flutter 3.41+, use `RepeatingAnimationBuilder` for a loop that only repeats. It owns its
own ticker, so there is no `StatefulWidget`, no controller, and no `dispose`.

## Continuous Rotation (Loading Indicator)

```dart
import 'dart:math';

import 'package:material_ui/material_ui.dart';

class const Spinner({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepeatingAnimationBuilder<double>(
      animatable: Tween<double>(begin: 0, end: 2 * pi),
      duration: Durations.extralong4,
      builder: (context, angle, child) {
        return Transform.rotate(angle: angle, child: child);
      },
      child: const Icon(Icons.refresh),
    );
  }
}
```

`repeatMode` defaults to `RepeatMode.restart`, which suits a rotation.

## Pulse Animation (Repeat with Reverse)

```dart
class const Pulse({required final Widget child, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepeatingAnimationBuilder<double>(
      animatable: Tween<double>(begin: 1.0, end: 1.05),
      duration: Durations.long2,
      curve: Easing.standard,
      repeatMode: RepeatMode.reverse,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }
}
```

Pass the static subtree through `child` so it is built once, not every frame.

## Pausing a Loop

Set `paused: true` to hold a loop, for example when the widget is off screen. A pulse is scale
motion, so also hold it when `MediaQuery.disableAnimationsOf(context)` or, on Flutter 3.50+,
`MediaQuery.reduceMotionOf(context)` is `true`:

```dart
RepeatingAnimationBuilder<double>(
  animatable: Tween<double>(begin: 1.0, end: 1.05),
  duration: Durations.long2,
  curve: Easing.standard,
  repeatMode: RepeatMode.reverse,
  paused: MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.reduceMotionOf(context),
  builder: (context, scale, child) {
    return Transform.scale(scale: scale, child: child);
  },
  child: child,
)
```

## Controller Fallback

Use an `AnimationController` only when the loop must reverse in response to state changes, or
when you listen to its status. Starting and stopping a loop needs only `paused`. See the `didUpdateWidget` pattern in
[explicit-animations.md](explicit-animations.md).

```dart
@override
void initState() {
  super.initState();
  _controller = AnimationController(
    duration: Durations.long2,
    vsync: this,
  )..repeat(reverse: true);

  _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Easing.standard,
    ),
  );
}
```
