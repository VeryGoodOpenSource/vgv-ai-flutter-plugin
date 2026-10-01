# Parameter Strategies

## Path Parameters — Resource Identification

Use path parameters to identify specific resources:

```dart
@TypedGoRoute<FlutterArticlePageRoute>(
  name: 'flutterArticle',
  path: 'article/:id',
)
@immutable
class const FlutterArticlePageRoute({required final String id})
    extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FlutterArticlePage(id: id);
  }
}
```

Navigation: `FlutterArticlePageRoute(id: article.id).go(context);`

## Query Parameters — Filtering and Sorting

Use query parameters for optional filtering or sorting criteria:

```dart
@TypedGoRoute<FlutterArticlesPageRoute>(
  name: 'flutterArticles',
  path: 'articles',
)
@immutable
class const FlutterArticlesPageRoute({
  final String? date,
  final String? category,
}) extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FlutterArticlesPage(
      date: date,
      category: category,
    );
  }
}
```

URL example: `/flutter/articles?date=07162024&category=all`

## Why `extra` Is Prohibited

The `extra` parameter does not work on the web and cannot be used for deep linking. Instead, pass identifiers via path or query parameters and fetch data within the destination page.
