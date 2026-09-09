# Widget Test Structure

Full example testing a page that uses a Bloc:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/home/home_page.dart';

import '../helpers/helpers.dart';

class _MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  group(HomePage, () {
    late HomeCubit homeCubit;

    setUp(() {
      homeCubit = _MockHomeCubit();
      when(() => homeCubit.state).thenReturn(const HomeState());
    });

    Widget buildSubject() {
      return BlocProvider<HomeCubit>.value(
        value: homeCubit,
        child: const HomePage(),
      );
    }

    group('renders', () {
      testWidgets('displays welcome text', (tester) async {
        await tester.pumpApp(buildSubject());

        expect(find.text('Welcome'), findsOneWidget);
      });

      testWidgets('displays loading indicator when status is loading',
          (tester) async {
        when(() => homeCubit.state).thenReturn(
          const HomeState(status: HomeStatus.loading),
        );

        await tester.pumpApp(buildSubject());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('navigates', () {
      testWidgets('to SettingsPage when settings icon is tapped',
          (tester) async {
        await tester.pumpApp(buildSubject());

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('calls', () {
      testWidgets('loadData when refresh button is tapped',
          (tester) async {
        when(() => homeCubit.loadData()).thenAnswer((_) async {});

        await tester.pumpApp(buildSubject());

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        verify(() => homeCubit.loadData()).called(1);
      });
    });
  });
}
```

## Testing Themes and Localization

Extend `pumpApp` to inject theme and localizations when needed:

```dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
  }) {
    return pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: widget,
      ),
    );
  }
}
```

## Pumping Methods

| Method               | When to use                                                                     |
| -------------------- | ------------------------------------------------------------------------------- |
| `pumpWidget(widget)` | Initial render — builds the widget tree for the first time                      |
| `pump()`             | Trigger a single frame rebuild (after `setState`, tap, etc.)                    |
| `pump(Duration)`     | Advance time by a specific duration (animations, debounce)                      |
| `pumpAndSettle()`    | Pump repeatedly until no pending frames — use for animations that must complete |

## Finders

| Finder                          | Use case                              | Example                                                                  |
| ------------------------------- | ------------------------------------- | ------------------------------------------------------------------------ |
| `find.byType(T)`                | Find widgets by type (default choice) | `find.byType(ElevatedButton)`                                            |
| `find.text('x')`                | Find text content visible to users    | `find.text('Submit')`                                                    |
| `find.byKey(Key)`               | Find by explicit key (last resort)    | `find.byKey(Key('submit_button'))`                                       |
| `find.byWidget(w)`              | Find an exact widget instance         | `find.byWidget(myWidget)`                                                |
| `find.descendant(of, matching)` | Scoped search within a subtree        | `find.descendant(of: find.byType(AppBar), matching: find.text('Title'))` |

## Interactions

```dart
// Tap
await tester.tap(find.byType(ElevatedButton));
await tester.pump();

// Enter text
await tester.enterText(find.byType(TextField), 'hello@example.com');
await tester.pump();

// Drag / scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pump();

// Long press
await tester.longPress(find.byType(ListTile));
await tester.pump();
```

Always call `pump()` (or `pumpAndSettle()`) after every interaction — widgets do not
rebuild until a frame is triggered.
