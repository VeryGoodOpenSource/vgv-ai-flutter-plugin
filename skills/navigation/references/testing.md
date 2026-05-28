# Testing

## Mocking GoRouter for Widget Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
  });

  testWidgets('navigates to details on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockRouter,
          child: const HomePage(),
        ),
      ),
    );

    await tester.tap(find.text('View Details'));
    verify(() => mockRouter.goNamed('details')).called(1);
  });
}
```

## Testing Redirects

```dart
testWidgets('redirects unauthenticated user to sign in', (tester) async {
  final router = GoRouter(
    initialLocation: '/premium',
    redirect: (context, state) {
      // Simulate unauthenticated state
      return '/sign-in';
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumPage()),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  await tester.pumpAndSettle();

  expect(find.byType(SignInPage), findsOneWidget);
});
```
