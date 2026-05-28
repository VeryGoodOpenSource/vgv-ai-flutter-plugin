# Redirects

Redirects can be applied at the root router level and at individual route levels. Parent redirects execute before child redirects.

## Root-Level Redirect (Authentication Guard)

```dart
GoRouter _routes(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorKey,
    redirect: (context, state) {
      final status = context.read<AppBloc>().state.status;
      if (status == AppStatus.unauthenticated) {
        return SignInPageRoute().location;
      }
      return null;
    },
    routes: $appRoutes,
  );
}
```

## Route-Level Redirect (Authorization Guard)

```dart
@TypedGoRoute<PremiumPageRoute>(
  name: 'premium',
  path: '/premium',
  routes: [
    TypedGoRoute<PremiumShowsPageRoute>(
      name: 'premiumShows',
      path: 'shows',
    ),
  ],
)
class PremiumPageRoute extends GoRouteData {
  @override
  String? redirect(BuildContext context, GoRouterState state) {
    final status = context.read<AppBloc>().state.user.status;
    if (status != UserStatus.premium) {
      return RestrictedPageRoute().location;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PremiumPage();
  }
}
```
