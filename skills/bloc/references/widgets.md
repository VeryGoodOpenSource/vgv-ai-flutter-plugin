# Flutter Widgets

| Widget              | Purpose                                                      |
| ------------------- | ------------------------------------------------------------ |
| `BlocProvider`      | Creates and provides a Bloc/Cubit to the subtree             |
| `BlocBuilder`       | Rebuilds widget when state changes                           |
| `BlocListener`      | Executes side effects (navigation, snackbar) on state change |
| `BlocConsumer`      | Combines `BlocBuilder` + `BlocListener`                      |
| `BlocSelector`      | Rebuilds only when a selected property changes               |
| `MultiBlocProvider` | Provides multiple Blocs/Cubits without nesting               |
| `MultiBlocListener` | Registers multiple listeners without nesting                 |
| `RepositoryProvider`| Provides a repository to the subtree                         |

## Context Extensions

| Extension                | Purpose                                          | Rebuilds?       |
| ------------------------ | ------------------------------------------------ | --------------- |
| `context.read<T>()`      | Access Bloc/Cubit instance (one-time read)       | No              |
| `context.watch<T>()`     | Access Bloc/Cubit and subscribe to changes       | Yes             |
| `context.select<T, R>()` | Subscribe to a specific state property           | Yes (selective) |

- Use `context.read` in callbacks (`onPressed`, `onTap`, `initState`)
- Use `context.watch` or `BlocBuilder` in `build` methods
- Never use `context.watch` outside of `build`

## Page/View Pattern

```dart
class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const TodosPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodosBloc(
        todoRepository: context.read<TodoRepository>(),
      )..add(const TodosSubscriptionRequested()),
      child: const TodosView(),
    );
  }
}

class TodosView extends StatelessWidget {
  const TodosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: BlocBuilder<TodosBloc, TodosState>(
        builder: (context, state) {
          return switch (state.status) {
            TodosStatus.initial || TodosStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            TodosStatus.success =>
              ListView.builder(
                itemCount: state.todos.length,
                itemBuilder: (context, index) =>
                    TodoListTile(todo: state.todos[index]),
              ),
            TodosStatus.failure =>
              Center(child: Text('Error: ${state.error}')),
          };
        },
      ),
    );
  }
}
```

## BlocListener for Side Effects

```dart
BlocListener<LoginBloc, LoginState>(
  listener: (context, state) {
    if (state is LoginFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error)),
      );
    }
    if (state is LoginSuccess) {
      Navigator.of(context).pushReplacement(HomePage.route());
    }
  },
  child: const LoginForm(),
)
```
