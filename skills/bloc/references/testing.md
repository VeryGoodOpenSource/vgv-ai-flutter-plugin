# Testing

## `blocTest()` Parameters

| Parameter | Type                  | Purpose                                       |
| --------- | --------------------- | --------------------------------------------- |
| `build`   | `() => Bloc/Cubit`    | Creates the Bloc/Cubit under test             |
| `act`     | `(bloc) => void`      | Interacts with the Bloc/Cubit                 |
| `expect`  | `() => List<State>`   | Expected states emitted (in order)            |
| `seed`    | `() => State`         | Initial state before `act`                    |
| `setUp`   | `() => void`          | Runs before `build`                           |
| `verify`  | `(bloc) => void`      | Additional verifications after `expect`       |
| `errors`  | `() => List<Matcher>` | Expected errors thrown                        |
| `wait`    | `Duration`            | Wait duration before asserting (for debounce) |

## Cubit Test Example

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/counter/counter.dart';

void main() {
  group(CounterCubit, () {
    test('initial state is 0', () {
      expect(CounterCubit().state, equals(0));
    });

    blocTest<CounterCubit, int>(
      'emits [1] when increment is called',
      build: CounterCubit.new,
      act: (cubit) => cubit.increment(),
      expect: () => [1],
    );

    blocTest<CounterCubit, int>(
      'emits [2] when increment is called from 1',
      build: CounterCubit.new,
      seed: () => 1,
      act: (cubit) => cubit.increment(),
      expect: () => [2],
    );
  });
}
```

## Bloc Test Example

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_app/todos/todos.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  group(TodosBloc, () {
    late TodoRepository todoRepository;

    setUp(() {
      todoRepository = _MockTodoRepository();
    });

    blocTest<TodosBloc, TodosState>(
      'emits [loading, success] when subscription is requested',
      setUp: () {
        when(() => todoRepository.getTodos())
            .thenAnswer((_) async => [Todo(id: '1', title: 'Test')]);
      },
      build: () => TodosBloc(todoRepository: todoRepository),
      act: (bloc) => bloc.add(const TodosSubscriptionRequested()),
      expect: () => [
        const TodosState(status: TodosStatus.loading),
        isA<TodosState>()
            .having((s) => s.status, 'status', TodosStatus.success)
            .having((s) => s.todos, 'todos', hasLength(1)),
      ],
      verify: (_) {
        verify(() => todoRepository.getTodos()).called(1);
      },
    );

    blocTest<TodosBloc, TodosState>(
      'emits [loading, failure] when repository throws',
      setUp: () {
        when(() => todoRepository.getTodos()).thenThrow(Exception('oops'));
      },
      build: () => TodosBloc(todoRepository: todoRepository),
      act: (bloc) => bloc.add(const TodosSubscriptionRequested()),
      expect: () => [
        const TodosState(status: TodosStatus.loading),
        isA<TodosState>()
            .having((s) => s.status, 'status', TodosStatus.failure),
      ],
    );
  });
}
```

## Mocking Dependencies

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_app/todos/todos.dart';

// Private mock, one per test file
class _MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  group(TodosBloc, () {
    late TodoRepository repository;

    // Register fallback for custom types
    setUpAll(() {
      registerFallbackValue(Todo(id: '', title: ''));
    });

    setUp(() {
      repository = _MockTodoRepository();

      // Stub methods
      when(() => repository.getTodos()).thenAnswer((_) async => []);
      when(() => repository.addTodo(any())).thenAnswer((_) async {});
    });

    blocTest<TodosBloc, TodosState>(
      'loads todos without deleting any',
      build: () => TodosBloc(todoRepository: repository),
      act: (bloc) => bloc.add(const TodosSubscriptionRequested()),
      verify: (_) {
        // Verify calls
        verify(() => repository.getTodos()).called(1);
        verifyNever(() => repository.deleteTodo(any()));
      },
    );
  });
}
```

## Testing Widget Integration

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_app/todos/todos.dart';

import '../../helpers/helpers.dart';

class _MockTodosBloc extends MockBloc<TodosEvent, TodosState>
    implements TodosBloc {}

void main() {
  group(TodosView, () {
    late TodosBloc todosBloc;

    setUp(() {
      todosBloc = _MockTodosBloc();
    });

    Widget buildSubject() {
      return BlocProvider.value(
        value: todosBloc,
        child: const TodosView(),
      );
    }

    testWidgets('renders loading indicator when status is loading',
        (tester) async {
      when(() => todosBloc.state).thenReturn(
        const TodosState(status: TodosStatus.loading),
      );

      await tester.pumpApp(buildSubject());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders todos when status is success', (tester) async {
      final todos = [Todo(id: '1', title: 'Test Todo')];
      when(() => todosBloc.state).thenReturn(
        TodosState(status: TodosStatus.success, todos: todos),
      );

      await tester.pumpApp(buildSubject());

      // Todo titles are data, not UI copy, so they are found as literals.
      expect(find.text('Test Todo'), findsOneWidget);
    });
  });
}
```
