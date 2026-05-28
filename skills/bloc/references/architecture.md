# Architecture

## Data Layer

Repositories abstract data sources and provide a clean API for Blocs/Cubits.

```dart
class TodoRepository {
  const TodoRepository({required TodoApiClient apiClient})
      : _apiClient = apiClient;

  final TodoApiClient _apiClient;

  Future<List<Todo>> getTodos() => _apiClient.fetchTodos();

  Future<void> addTodo(Todo todo) => _apiClient.createTodo(todo);

  Future<void> deleteTodo(String id) => _apiClient.deleteTodo(id);
}
```

## Feature Folder Structure

```text
lib/
├── todos/
│   ├── todos.dart                  # Barrel file
│   ├── bloc/
│   │   ├── todos_bloc.dart
│   │   ├── todos_event.dart
│   │   └── todos_state.dart
│   ├── view/
│   │   ├── todos_page.dart         # Provides Bloc via BlocProvider
│   │   └── todos_view.dart         # Consumes Bloc via BlocBuilder
│   └── widgets/
│       └── todo_list_tile.dart
test/
├── todos/
│   ├── bloc/
│   │   └── todos_bloc_test.dart
│   ├── view/
│   │   ├── todos_page_test.dart
│   │   └── todos_view_test.dart
│   └── widgets/
│       └── todo_list_tile_test.dart
```
