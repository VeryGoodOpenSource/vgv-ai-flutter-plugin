---
title: "Bloc"
description: "Best practices for Bloc state management in Flutter/Dart."
---
<!-- GENERATED FROM skills/bloc/SKILL.md — DO NOT EDIT. Run `npm run gen:docs` after editing the skill. -->

State management library for Dart and Flutter using the BLoC (Business Logic Component) pattern to separate business logic from the presentation layer.

---

## Core Standards

Apply these standards to ALL Bloc/Cubit work:

- **Use `blocTest()` from `package:bloc_test`** for all Bloc and Cubit tests — never raw `test()` with manual stream assertions
- **Use `package:mocktail` for mocking** — never `package:mockito`
- **No bloc-to-bloc direct dependencies** — blocs communicate through the UI or shared repositories
- **Page/View separation** — Page provides the Bloc/Cubit via `BlocProvider`, View consumes via `BlocBuilder`/`BlocListener`
- **Sealed classes for events and multi-state types** — enables exhaustive pattern matching with Dart 3 `switch`
- **Equatable for all states and events** — extend `Equatable` and override `props` for value equality
- **Business logic in Bloc/Cubit only** — never in widgets, pages, or views
- **Single responsibility** — one Bloc/Cubit per feature concern
- **Emit only after async checks** — use `emit` only inside the handler callback

---

## Cubit vs Bloc

| Aspect            | Cubit                          | Bloc                                    |
| ----------------- | ------------------------------ | --------------------------------------- |
| API               | Functions → `emit(state)`      | Events → `on<Event>` → `emit(state)`    |
| Complexity        | Low                            | Higher                                  |
| Traceability      | Less (no event log)            | Full (events + transitions)             |
| When to use       | Simple state, UI-driven logic  | Complex flows, event-driven, transforms |
| Testing           | Call methods, assert states    | Add events, assert states               |

### Cubit Example

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

### Bloc Example

```dart
sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object> get props => [];
}

final class CounterIncrementPressed extends CounterEvent {}
final class CounterDecrementPressed extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncrementPressed>((event, emit) => emit(state + 1));
    on<CounterDecrementPressed>((event, emit) => emit(state - 1));
  }
}
```

---

## Naming Conventions

### Events

**Pattern:** `BlocSubject` + `Noun` + `VerbPastTense`

| Event class name                | Meaning                          |
| ------------------------------- | -------------------------------- |
| `TodoListSubscriptionRequested` | Subscribing to todo list stream  |
| `TodoListTodoDeleted`           | Deleting a specific todo         |
| `TodoListUndoDeletionRequested` | Undoing the last deletion        |
| `LoginFormSubmitted`            | Submitting the login form        |
| `ProfilePageRefreshed`          | Refreshing the profile page      |

```dart
sealed class TodoListEvent extends Equatable {
  const TodoListEvent();

  @override
  List<Object> get props => [];
}

final class TodoListSubscriptionRequested extends TodoListEvent {}

final class TodoListTodoDeleted extends TodoListEvent {
  const TodoListTodoDeleted({required this.todo});

  final Todo todo;

  @override
  List<Object> get props => [todo];
}
```

### States

#### Subclass Approach (multiple state types)

Use when each state carries different data.

| State class name              | Meaning                          |
| ----------------------------- | -------------------------------- |
| `LoginInitial`                | No action taken yet              |
| `LoginInProgress`             | Login request in flight          |
| `LoginSuccess`                | Login succeeded                  |
| `LoginFailure`                | Login failed                     |

```dart
sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

final class LoginInitial extends LoginState {}
final class LoginInProgress extends LoginState {}
final class LoginSuccess extends LoginState {
  const LoginSuccess({required this.user});

  final User user;

  @override
  List<Object> get props => [user];
}
final class LoginFailure extends LoginState {
  const LoginFailure({required this.error});

  final String error;

  @override
  List<Object> get props => [error];
}
```

#### Single Class Approach (one state, multiple fields)

Use when all states share the same data shape.

| Field         | Type                | Purpose                        |
| ------------- | ------------------- | ------------------------------ |
| `status`      | `enum`              | Current loading status         |
| `items`       | `List<Item>`        | Loaded data                    |
| `error`       | `String?`           | Error message if failed        |

```dart
enum TodoListStatus { initial, loading, success, failure }

class TodoListState extends Equatable {
  const TodoListState({
    this.status = TodoListStatus.initial,
    this.todos = const [],
    this.error,
  });

  final TodoListStatus status;
  final List<Todo> todos;
  final String? error;

  TodoListState copyWith({
    TodoListStatus? status,
    List<Todo>? todos,
    String? error,
  }) {
    return TodoListState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, todos, error];
}
```

---

## Architecture

| Layer              | Contains                           | Depends on          |
| ------------------ | ---------------------------------- | ------------------- |
| **Presentation**   | Pages, Views, Widgets              | Business Logic      |
| **Business Logic** | Blocs, Cubits                      | Data                |
| **Data**           | Repositories, Data Providers       | External sources    |

### Data Layer

Repositories abstract data sources and provide a clean API for Blocs/Cubits. Mirror the feature folder structure under `test/` for all test files.

See [Architecture](/best-practices/bloc/architecture) for the repository example, feature folder structure, and test directory layout.

---

## Flutter Widgets

- `BlocProvider` — creates and provides a Bloc/Cubit to the subtree
- `BlocBuilder` — rebuilds widget when state changes
- `BlocListener` — executes side effects (navigation, snackbar) on state change
- `BlocConsumer` — combines `BlocBuilder` + `BlocListener`
- `BlocSelector` — rebuilds only when a selected property changes
- Use `context.read` in callbacks (`onPressed`, `onTap`), `context.watch` or `BlocBuilder` in `build` methods
- Never use `context.watch` outside of `build`

See [Flutter Widgets](/best-practices/bloc/widgets) for the full widget and context extension tables, Page/View pattern example, and BlocListener example. See [Testing](/best-practices/bloc/testing) for `blocTest()` parameters, Cubit/Bloc test examples, mocking dependencies, and widget integration tests. See [Common Patterns](/best-practices/bloc/patterns) for adding features with Bloc/Cubit, async operations, and event transformers.
