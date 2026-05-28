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
