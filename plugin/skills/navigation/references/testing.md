# Testing

## Mocking GoRouter for Widget Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/home/home.dart';

import '../../helpers/helpers.dart';

class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  group(HomePage, () {
    late GoRouter goRouter;

    setUp(() {
      goRouter = _MockGoRouter();
    });

    testWidgets('navigates to details on tap', (tester) async {
      await tester.pumpApp(
        InheritedGoRouter(
          goRouter: goRouter,
          child: const HomePage(),
        ),
      );

      await tester.tap(find.text(tester.l10n.viewDetailsButton));

      verify(() => goRouter.goNamed('details')).called(1);
    });
  });
}
```

`pumpApp` is the shared helper from the testing skill; it wires the localization delegates
that `tester.l10n` reads from.

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

  // The real router is the subject here, so this test pumps `MaterialApp.router`
  // itself instead of going through `pumpApp`.
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  await tester.pumpAndSettle();

  expect(find.byType(SignInPage), findsOneWidget);
});
```
