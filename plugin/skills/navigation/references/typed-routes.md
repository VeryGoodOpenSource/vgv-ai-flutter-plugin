# Type-Safe Route Definitions

`@TypedGoRoute` annotations on `GoRouteData` classes eliminate typos and manual parameter
casting. `package:go_router_builder` generates the type-safe helpers at build time via
`dart run build_runner build --delete-conflicting-outputs`.

## Shell Routes

Use `TypedShellRoute` for persistent chrome — a bottom navigation bar or a nav rail — around
a set of routes:

```dart
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<HomePageRoute>(
      name: 'home',
      path: '/home',
    ),
    TypedGoRoute<SettingsPageRoute>(
      name: 'settings',
      path: '/settings',
    ),
  ],
)
class AppShellRoute extends ShellRouteData {
  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return AppShell(child: navigator);
  }
}
```
