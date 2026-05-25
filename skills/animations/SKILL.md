---
name: vgv-animations
description: Best practices for Flutter animations using the built-in animation framework. Use when creating, modifying, or reviewing animations, transitions, motion, or animated widgets. Covers implicit animations, explicit animations, page transitions, and Material 3 motion tokens.
allowed-tools: Read,Glob,Grep
argument-hint: "[file-or-directory]"
---

# Animations

Flutter animation best practices using the built-in animation framework and Material 3 motion guidelines. No third-party animation libraries (Lottie, Rive, etc.).

## Core Standards

Apply these standards to ALL animation work:

- **Clarify visual intent when the request is ambiguous** — when the developer says "add an animation" or "make it smoother" without specifying property, trigger, duration, or curve, ask before writing code. If the developer provides clear specs (e.g., "300ms ease-in fade on the card when it appears"), proceed directly
- **Use the simplest animation approach that works** — follow the decision tree below; never reach for `AnimationController` when an implicit animation suffices
- **Use Material 3 motion tokens for duration and easing** — never hardcode arbitrary `Duration` or `Curve` values
- **Extract animation constants** — durations, curves, and offsets go in named constants or a centralized `AppMotion` class, not inline
- **Dispose controllers** — every `AnimationController` must be disposed in the `dispose()` method of the `State`
- **Use `SingleTickerProviderStateMixin` for one controller** — use `TickerProviderStateMixin` only when the widget owns multiple controllers
- **Keep animated subtrees small** — wrap only the widgets that change inside the animation builder, not entire widget trees
- **Never animate layout-triggering properties in a tight loop** — animating `width`/`height` on complex layouts causes expensive rebuilds; prefer `Transform` or `Opacity` which operate on the compositing layer

---

## Animation Decision Tree

Choose the simplest approach that meets the requirement:

```text
Does the widget rebuild when the value changes?
  |
  YES --> Does the framework provide an AnimatedFoo widget?
  |         |
  |         YES --> Use the implicit AnimatedFoo widget
  |         |       (AnimatedContainer, AnimatedOpacity, AnimatedAlign, etc.)
  |         |
  |         NO  --> Use TweenAnimationBuilder
  |
  NO  --> Do you need fine-grained control?
            (repeat, reverse, sequence, listen to status)
            |
            YES --> Use AnimationController + AnimatedBuilder
            |
            NO  --> Use TweenAnimationBuilder
```

**Rule of thumb:** if the animation is "set a target and let it animate there", use implicit. If the animation must play/pause/reverse/repeat on command, use explicit.

---

## Material 3 Motion Tokens

Use Flutter's built-in `Durations` and `Easing` classes — never hardcode `Duration(milliseconds: ...)` or use `Curves.*` for new code. The framework constants align with the Material 3 motion specification; refer to the Flutter `Durations` and `Easing` class documentation for the full token list.

### Centralized Motion Constants

Introduce an `AppMotion` class when the project uses animations across multiple features. For a single animation in the app, inline M3 tokens are sufficient.

```dart
abstract class AppMotion {
  // Standard transitions
  static const Duration standardDuration = Durations.medium2;
  static const Curve standardCurve = Easing.standard;

  // Page transitions
  static const Duration pageDuration = Durations.medium4;
  static const Curve pageEnterCurve = Easing.emphasizedDecelerate;
  static const Curve pageExitCurve = Easing.emphasizedAccelerate;

  // Fades
  static const Duration fadeDuration = Durations.short3;
  static const Curve fadeCurve = Easing.standard;
}
```

---

## Implicit Animations

Use implicit animations when the widget rebuilds with new target values. The framework interpolates automatically. Flutter provides built-in `AnimatedFoo` widgets (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSlide`, `AnimatedSwitcher`, etc.) — use the one that matches the property being animated. When no built-in widget exists, use `TweenAnimationBuilder`.

---

## TweenAnimationBuilder

Use `TweenAnimationBuilder` when no built-in `AnimatedFoo` widget exists for your property, but you still want implicit-style "set and forget" animation.

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

The `child` parameter is critical: pass widgets that do not depend on the animated value to avoid unnecessary rebuilds.

---

## Explicit Animations

Use explicit animations when you need control over playback: play, pause, reverse, repeat, or listen to animation status.

### AnimationController Setup

```dart
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Durations.medium2,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Easing.standard,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: child, // static child — not rebuilt each frame
    );
  }
}
```

See [references/explicit-animations.md](references/explicit-animations.md) for `didUpdateWidget` patterns, constructor injection for testable controllers, and transition widget vs `AnimatedBuilder` guidance.

### Chained Animations with Intervals

Use `Interval` inside `CurvedAnimation` to sequence animations on a single controller:

```dart
late final Animation<double> _fadeAnimation = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.0, 0.5, curve: Easing.standard),
);

late final Animation<Offset> _slideAnimation = Tween<Offset>(
  begin: const Offset(0, 0.25),
  end: Offset.zero,
).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.8, curve: Easing.emphasized),
  ),
);
```

See [references/staggered-animations.md](references/staggered-animations.md) for full staggered entry and staggered list examples. See [references/looping-animations.md](references/looping-animations.md) for repeating and pulse animation patterns.

---

## Page Transitions

Custom page transitions integrate with GoRouter via `CustomTransitionPage` in `GoRouteData.buildPage`.

```dart
@override
Page<void> buildPage(BuildContext context, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: const DetailsPage(),
    transitionDuration: Durations.medium4,
    reverseTransitionDuration: Durations.medium4,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Easing.emphasizedDecelerate,
        ),
        child: child,
      );
    },
  );
}
```

See [references/page-transitions.md](references/page-transitions.md) for a reusable `AppPageTransitions` helper class with fade, slide-fade, and slide-up transitions, and usage with `GoRouteData`.

### Hero Animations

Use `Hero` for shared-element transitions between routes. The framework handles the animation automatically.

```dart
// Source screen
Hero(
  tag: 'product-image-${product.id}',
  child: Image.network(product.imageUrl),
)

// Destination screen
Hero(
  tag: 'product-image-${product.id}',
  child: Image.network(product.imageUrl),
)
```

Rules for Hero:

- **Tags must be unique within each route** — use meaningful identifiers, not indices
- **Both source and destination must be visible during the transition** — Hero does not work with lazy lists that remove the source widget
- **Wrap only the visual element** — not the entire card or list tile

---

## Performance

### Do

- **Animate `Transform` and `Opacity`** — these operate on the compositing layer and skip layout/paint
- **Use the `child` parameter** in `AnimatedBuilder` and `TweenAnimationBuilder` to avoid rebuilding static widgets every frame
- **Use `RepaintBoundary`** around animated widgets in complex layouts to isolate repaints

### Do Not

- **Do not animate `width`, `height`, or `padding` on complex layouts** — triggers expensive layout recalculations every frame
- **Do not wrap entire screens in `AnimatedBuilder`** — only wrap the subtree that changes
- **Do not create multiple `AnimationController` instances for animations that share timing** — use `Interval` on a single controller

---

## Anti-Patterns

### Hardcoded magic values

```dart
// Bad — arbitrary values with no semantic meaning
AnimatedContainer(
  duration: Duration(milliseconds: 375),
  curve: Curves.easeInOutCubic,
  // ...
)

// Good — M3 tokens with clear intent
AnimatedContainer(
  duration: Durations.medium2,
  curve: Easing.standard,
  // ...
)
```

### Missing controller disposal

```dart
// Bad — memory leak
@override
void dispose() {
  super.dispose();
}

// Good — dispose before super.dispose()
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### Rebuilding static children every frame

```dart
// Bad — entire subtree rebuilds 60 times/second
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Opacity(
      opacity: _controller.value,
      child: const ExpensiveWidget(), // rebuilt every frame
    );
  },
)

// Good — static child passed through
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Opacity(
      opacity: _controller.value,
      child: child,
    );
  },
  child: const ExpensiveWidget(), // built once
)
```

### Using explicit when implicit suffices

```dart
// Bad — unnecessary complexity for a simple target-value animation
class _FadeWidgetState extends State<FadeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // ... 20+ lines of boilerplate

// Good — one widget, zero boilerplate
AnimatedOpacity(
  duration: Durations.short3,
  curve: Easing.standard,
  opacity: isVisible ? 1.0 : 0.0,
  child: child,
)
```

---

## Quick Reference

| Approach                  | When to Use                                  |
| ------------------------- | -------------------------------------------- |
| `AnimatedFoo`             | Built-in widget exists for the property      |
| `TweenAnimationBuilder`   | Custom property, no playback control needed  |
| `AnimationController`     | Need play/pause/reverse/repeat/status        |
| `Hero`                    | Shared-element transition between routes     |
| `CustomTransitionPage`    | Custom GoRouter page transition              |

| Mixin                            | When to Use                        |
| -------------------------------- | ---------------------------------- |
| `SingleTickerProviderStateMixin` | Widget owns exactly one controller |
| `TickerProviderStateMixin`       | Widget owns multiple controllers   |

## Additional Resources

- [references/explicit-animations.md](references/explicit-animations.md) — `didUpdateWidget`, testable controllers, transition widgets vs `AnimatedBuilder`
- [references/staggered-animations.md](references/staggered-animations.md) — staggered entry animations and staggered list items
- [references/page-transitions.md](references/page-transitions.md) — reusable `AppPageTransitions` helper and GoRouter integration
- [references/looping-animations.md](references/looping-animations.md) — repeating, pulsing, and continuous rotation patterns
