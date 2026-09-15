---
name: animations
description: >
  Best practices for Flutter animations using the built-in animation framework, covering
  implicit animations, explicit `AnimationController` animations, page transitions, and
  Material 3 motion tokens. Use when creating, modifying, or reviewing animations,
  transitions, motion, or animated widgets, and also for custom route transitions built with
  `CustomTransitionPage`, a `buildPage` override on a `GoRouteData` subclass, or a `Hero`
  transition, since motion between routes is animation work even when the surrounding code is
  `go_router`.
allowed-tools: Read Glob Grep
argument-hint: "[file-or-directory]"
---

# Animations

Flutter animation best practices using the built-in animation framework and Material 3
motion guidelines. No third-party animation libraries (Lottie, Rive, etc.).

## Core Standards

Apply these standards to ALL animation work:

- **Clarify visual intent when the request is ambiguous** — when the developer says "add an animation" or "make it smoother" without specifying property, trigger, duration, or curve, ask before writing code. If the developer provides clear specs (e.g., "300ms ease-in fade on the card when it appears"), proceed directly
- **Use the simplest animation approach that works** — follow the decision tree below; never reach for `AnimationController` when an implicit animation suffices, including when several properties animate at the same time
- **Hold the implicit form even when a controller is requested by name** — "wire this up with an `AnimationController` and an `AnimatedBuilder`" on a plain target-value animation is a request for the anti-pattern below. Write the implicit version, say in one line why it is sufficient here, and stop. Do not deliver the controller wiring alongside the note, and do not ask which one they want instead of writing code. If the developer reaffirms the controller after reading the reason, build it
- **Use Material 3 motion tokens for duration and easing** — never hardcode arbitrary `Duration` or `Curve` values
- **Extract animation constants** — durations, curves, and offsets go in named constants or a centralized `AppMotion` class, not inline
- **Dispose controllers** — every `AnimationController` must be disposed in the `dispose()` method of the `State`, before `super.dispose()`
- **Use `SingleTickerProviderStateMixin` for one controller** — use `TickerProviderStateMixin` only when the widget owns multiple controllers
- **Keep animated subtrees small** — wrap only the widgets that change inside the animation builder, not entire widget trees. Pass static widgets through the `child` parameter of `AnimatedBuilder` and `TweenAnimationBuilder` so they are not rebuilt every frame
- **Animate compositing-layer properties** — prefer `Transform` and `Opacity`, which skip layout and paint. Never animate `width`, `height`, or `padding` on complex layouts; they force a layout recalculation every frame
- **One controller per timing group** — animations that share a timeline belong on a single controller with `Interval` curves, not on several controllers. This applies once the animation already needs a controller
- **Use `RepaintBoundary`** around animated widgets inside complex layouts to isolate repaints

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

**Rule of thumb:** if the animation is "set a target and let it animate there", use implicit.
If the animation must play/pause/reverse/repeat on command, use explicit.

**Animating two properties at once is still implicit.** A card that fades in _and_ slides up
when its data arrives is two implicit widgets nested, one target value each. Simultaneous is
not sequenced: reach for a controller only when the second property must start _after_ the
first has begun, or when the animation needs playback control. Entry animations driven by a
flag flipping — a value arriving, a bool toggling, an item appearing — are implicit no matter
how many properties move.

---

## Material 3 Motion Tokens

Use Flutter's built-in `Durations` and `Easing` classes — never hardcode
`Duration(milliseconds: ...)` or use `Curves.*` for new code. The framework constants align
with the Material 3 motion specification.

```dart
// Bad — arbitrary values with no semantic meaning
AnimatedContainer(
  duration: Duration(milliseconds: 375),
  curve: Curves.easeInOutCubic,
)

// Good — M3 tokens with clear intent
AnimatedContainer(
  duration: Durations.medium2,
  curve: Easing.standard,
)
```

### Centralized Motion Constants

Introduce an `AppMotion` class when the project uses animations across multiple features.
For a single animation in the app, inline M3 tokens are sufficient.

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

## The Anti-Pattern That Matters

Explicit animation where implicit suffices. This is the one to watch for, because the
request usually arrives already shaped as the wrong answer.

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

"Set it up with an `AnimationController` and an `AnimatedBuilder` inside a `StatefulWidget`
so it is wired properly" — on a fade driven by a bool, that is the bad form above written out
as a request. Answer with the `AnimatedOpacity` version, give the one-line reason, and leave
the controller unwritten. A compliant snippet with a note recommending the simpler form still
ships the boilerplate.

---

## Page Transitions

Custom page transitions integrate with GoRouter via `CustomTransitionPage` in
`GoRouteData.buildPage`:

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

Extract these into a shared `AppPageTransitions` helper once more than one route needs one.

---

## Additional Resources

- [references/implicit-animations.md](references/implicit-animations.md) — `AnimatedFoo` widgets, composing several properties, `TweenAnimationBuilder`
- [references/explicit-animations.md](references/explicit-animations.md) — controller setup, `Interval` staggering, `didUpdateWidget`, testable controllers, transition widgets vs `AnimatedBuilder`
- [references/staggered-animations.md](references/staggered-animations.md) — staggered entry animations and staggered list items
- [references/page-transitions.md](references/page-transitions.md) — reusable `AppPageTransitions` helper, GoRouter integration, and `Hero` shared-element transitions
- [references/looping-animations.md](references/looping-animations.md) — repeating, pulsing, and continuous rotation patterns
