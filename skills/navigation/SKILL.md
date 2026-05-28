---
name: vgv-navigation
description: Best practices for navigation and routing in Flutter using GoRouter.
when_to_use: Use when creating, modifying, or reviewing routes, deep links, redirects, or navigation logic that uses package:go_router or package:go_router_builder.
allowed-tools: Read Glob Grep
model: sonnet
---

# Navigation

Routing and navigation best practices for Flutter applications using GoRouter, the Flutter team's recommended routing package built on the Navigator 2.0 API.

## Core Standards

Apply these standards to ALL navigation work:

- **Use `package:go_router` for all navigation** — never raw Navigator 2.0 or Navigator 1.0 push/pop
- **Use `@TypedGoRoute` annotations for type-safe routes** — never raw string paths in route definitions
- **Prefer `go()` over `push()`** — use `push()` only when expecting return data from the destination
- **Never use the `extra` parameter** — it breaks deep linking and does not work on the web
- **Hierarchical sub-routes for proper back navigation** — structure routes as parent-child trees, not flat lists
- **Hyphens for URL word separation** — never underscores or camelCase in URL paths
- **Navigate by route name, not raw path strings** — use named route navigation to decouple from path changes
- **Use `BuildContext` extensions for navigation** — prefer `context.goNamed()` over `GoRouter.of(context).goNamed()`

## Route Organization

Structure routes hierarchically with logical parent-child relationships. Sub-routes ensure the app bar back button displays correctly and URLs remain clean.

### Hierarchical Structure (Preferred)

```text
/flutter
  /flutter/news
  /flutter/chat
  /flutter/articles
    /flutter/articles?category=all
    /flutter/article/:id
/android
  /android/news
  /android/chat
```

### Flat Structure (Avoid)

```text
/flutter-news
/flutter-chat
/android-news
/android-chat
```

Hierarchical sub-routes produce proper backward navigation automatically — when a user is on `/flutter/news`, the back button navigates to `/flutter`.

## Type-Safe Routes

Use `@TypedGoRoute` annotations with `GoRouteData` classes to eliminate typos and manual parameter casting. The `go_router_builder` package generates type-safe route helpers at build time.

### Basic Route

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

### Route with Sub-Routes

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

## Navigation Methods

### `go()` vs `push()`

| Method   | URL Updates | Back Button | Use Case                                     |
| -------- | ----------- | ----------- | -------------------------------------------- |
| `go()`   | Yes         | App bar     | Standard navigation between screens          |
| `push()` | No          | System      | When expecting return data from popped route |

### Using `go()` (Default)

```dart
const CategoriesPageRoute(size: 'small', color: 'blue').go(context);
```

Using `go()` ensures the back button in the app's `AppBar` displays when the current route has a parent to navigate back to.

### Using `push()` (Return Data Only)

```dart
final result = await DialogPageRoute().push<String>(context);
```

Use `push()` only when a route must return data (e.g., a dialog collecting user input). On the web, `push()` does not update the address bar.

### BuildContext Extensions

Always use extension methods for cleaner syntax:

```dart
// Preferred
context.goNamed('flutterNews');

// Avoid
GoRouter.of(context).goNamed('flutterNews');
```

## Parameter Strategies

Use **path parameters** (`:id`) for resource identification and **query parameters** (`?category=all`) for optional filtering. Never use `extra` — it breaks deep linking and does not work on the web.

See [references/parameters.md](references/parameters.md) for full examples of path parameters, query parameters, and why `extra` is prohibited.

## Redirects

Redirects can be applied at the root router level (e.g., authentication guards) and at individual route levels (e.g., authorization guards). Parent redirects execute before child redirects.

See [references/redirects.md](references/redirects.md) for root-level and route-level redirect examples.

## Testing

Mock `GoRouter` with `package:mocktail` and wrap widgets in `InheritedGoRouter` for widget tests. Test redirects by constructing a `GoRouter` with the target redirect logic and asserting the resulting page.

See [references/testing.md](references/testing.md) for mocking GoRouter and testing redirect examples.

## Common Patterns

### Adding a New Route

1. Create the page widget (following the Page/View pattern if using Bloc)
2. Define a `GoRouteData` class with `@TypedGoRoute` annotation
3. Add it as a sub-route under the appropriate parent route
4. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate route helpers
5. Navigate using the generated type-safe route class

### Deep Linking Setup

1. Structure routes hierarchically with meaningful URL paths
2. Use path parameters for resource identification
3. Use query parameters for filtering — never `extra`
4. Navigate by route name so path restructuring does not break links
5. Test deep links by launching the app with the target URL

### Nested Navigation (Shell Routes)

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

## Quick Reference

| Package             | Purpose                                     |
| ------------------- | ------------------------------------------- |
| `go_router`         | Declarative routing built on Navigator 2.0  |
| `go_router_builder` | Code generation for type-safe route classes |

| Command                                                    | Purpose                          |
| ---------------------------------------------------------- | -------------------------------- |
| `dart run build_runner build --delete-conflicting-outputs` | Generate type-safe route helpers |
| `dart run build_runner watch --delete-conflicting-outputs` | Watch and regenerate on changes  |
