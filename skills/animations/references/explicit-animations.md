# Explicit Animation Patterns

Detailed patterns for `AnimationController`-based animations. See the main skill file for core setup and standards.

## Responding to Widget Updates

Use `didUpdateWidget` to start, stop, or reverse an animation when a property changes:

```dart
class _AnimatedGlowState extends State<AnimatedGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Durations.long2,
      vsync: this,
    );
    if (widget.isGlowing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlowing != oldWidget.isGlowing) {
      if (widget.isGlowing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ...
}
```

Do not start animations in `build()`. Use `initState` for initial playback and `didUpdateWidget` for subsequent state changes.

## Constructor Injection for Testable Controllers

Expose an optional controller parameter to allow tests to drive the animation directly:

```dart
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    required this.isActive,
    super.key,
    @visibleForTesting this.controller,
  });

  final bool isActive;

  @visibleForTesting
  final AnimationController? controller;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      _controller = AnimationController(
        duration: Durations.long2,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  // ...
}
```

Only dispose the controller if the widget created it. Tests that inject a controller are responsible for its lifecycle.

## Transition Widgets vs AnimatedBuilder

**Single property** — use the built-in transition widget directly. Less code, same performance:

```dart
// Good — single property, use the transition widget
FadeTransition(
  opacity: _fadeAnimation,
  child: child,
)
```

**Multiple properties combined** — use `AnimatedBuilder` to compose them in one builder:

```dart
// Good — multiple properties, use AnimatedBuilder
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Opacity(
      opacity: _fadeAnimation.value,
      child: SlideTransition(
        position: _slideAnimation,
        child: child,
      ),
    );
  },
  child: child,
)
```

| Scenario                                                  | Use                                                                          |
| --------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Animate one property (opacity, position, scale, rotation) | `FadeTransition`, `SlideTransition`, `ScaleTransition`, `RotationTransition` |
| Animate multiple properties together                      | `AnimatedBuilder` with manual composition                                    |

**Avoid subclassing `AnimatedWidget`** — couples the animation to a specific widget class, making reuse harder.
