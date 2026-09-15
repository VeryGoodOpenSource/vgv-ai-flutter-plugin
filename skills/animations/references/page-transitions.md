# Page Transition Patterns for GoRouter

## Shared Transition Helper

Create a reusable transition builder to maintain consistency across routes:

```dart
abstract class AppPageTransitions {
  static CustomTransitionPage<void> fade({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
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

  static CustomTransitionPage<void> slideFade({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: Durations.medium4,
      reverseTransitionDuration: Durations.medium4,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Easing.emphasizedDecelerate,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static CustomTransitionPage<void> slideUp({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: Durations.medium4,
      reverseTransitionDuration: Durations.medium4,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Easing.emphasizedDecelerate,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
```

## Using Transitions in GoRouteData

```dart
@TypedGoRoute<DetailsPageRoute>(
  name: 'details',
  path: 'details/:id',
)
@immutable
class DetailsPageRoute extends GoRouteData {
  const DetailsPageRoute({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return AppPageTransitions.slideFade(
      key: state.pageKey,
      child: DetailsPage(id: id),
    );
  }
}
```

## Hero Animations

Use `Hero` for shared-element transitions between routes. The framework handles the
animation automatically — matching tags on both routes is the whole setup.

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

Rules for `Hero`:

- **Tags must be unique within each route** — use meaningful identifiers, not indices
- **Both source and destination must be visible during the transition** — `Hero` does not work with lazy lists that remove the source widget
- **Wrap only the visual element** — not the entire card or list tile
