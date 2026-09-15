# Type-Safe Route Definitions

`@TypedGoRoute` annotations on `GoRouteData` classes eliminate typos and manual parameter
casting. `package:go_router_builder` generates the type-safe helpers at build time via
`dart run build_runner build --delete-conflicting-outputs`.

## Basic Route

```dart
@TypedGoRoute<CategoriesPageRoute>(
  name: 'categories',
  path: '/categories',
)
@immutable
class CategoriesPageRoute extends GoRouteData {
  const CategoriesPageRoute({
    this.size,
    this.color,
  });

  final String? size;
  final String? color;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CategoriesPage(size: size, color: color);
  }
}
```

## Route with Sub-Routes

Nest `TypedGoRoute` entries under a parent so back navigation and URLs follow the hierarchy:

```dart
@TypedGoRoute<FlutterPageRoute>(
  name: 'flutter',
  path: '/flutter',
  routes: [
    TypedGoRoute<FlutterNewsPageRoute>(
      name: 'flutterNews',
      path: 'news',
    ),
    TypedGoRoute<FlutterArticlesPageRoute>(
      name: 'flutterArticles',
      path: 'articles',
      routes: [
        TypedGoRoute<FlutterArticlePageRoute>(
          name: 'flutterArticle',
          path: 'article/:id',
        ),
      ],
    ),
  ],
)
@immutable
class FlutterPageRoute extends GoRouteData {
  const FlutterPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FlutterPage();
  }
}
```

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
