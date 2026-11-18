# Common Patterns

## Adding a New Feature with Bloc

1. Create feature directory: `lib/<feature>/`
1. Add barrel file: `lib/<feature>/<feature>.dart`
1. Define events: `lib/<feature>/bloc/<feature>_event.dart` — sealed class with event subclasses
1. Define state: `lib/<feature>/bloc/<feature>_state.dart` — sealed or single class with Equatable
1. Implement Bloc: `lib/<feature>/bloc/<feature>_bloc.dart` — register event handlers, inject repository
1. Create page: `lib/<feature>/view/<feature>_page.dart` — provides Bloc via `BlocProvider`
1. Create view: `lib/<feature>/view/<feature>_view.dart` — consumes state via `BlocBuilder`
1. Create test structure: mirror under `test/<feature>/`
1. Write `blocTest` for every event handler and state transition

## Adding a New Feature with Cubit

1. Create feature directory: `lib/<feature>/`
1. Add barrel file: `lib/<feature>/<feature>.dart`
1. Define state: `lib/<feature>/cubit/<feature>_state.dart`
1. Implement Cubit: `lib/<feature>/cubit/<feature>_cubit.dart` — public methods that `emit`
1. Create page and view with `BlocProvider` / `BlocBuilder`
1. Create test structure: mirror under `test/<feature>/`
1. Write `blocTest` for every public method
