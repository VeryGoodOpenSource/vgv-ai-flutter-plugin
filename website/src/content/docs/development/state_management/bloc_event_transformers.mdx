---
title: Bloc Event Transformers
description: Specifying the order in which Bloc events are handled.
---

Since [Bloc v.7.2.0](https://bloclibrary.dev/migration/#v720), events are handled concurrently by default. This allows event handler instances to execute simultaneously and provides no guarantees regarding the order of handler completion.

Concurrent event handling is often desirable, but issues ranging from performance degradation to serious data and behavior defects can emerge if your specified event transformer diverges from the needs of your state management system.

In particular, [race conditions](https://en.wikipedia.org/wiki/Race_condition) can produce bugs when the result of operations varies with their order of execution.

#### Registering Event Transformers

Event transformers are specified in the `transformer` field of the event registration functions in the `Bloc` constructor:

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(MyState()) {
    on<MyEvent>(
      _onEvent,
      transformer: mySequentialTransformer(),
    )
    on<MySecondEvent>(
      _onSecondEvent,
      transformer: mySequentialTransformer(),
    )
  }
}
```

Each `on<E>` statement creates a bucket for handling events of type `E`.

:::note
Note that event transformers are only applied within the bucket they are specified in. In the above example, only events of the same type (two of `MyEvent` or two `MySecondEvent`) would be processed sequentially, while a `MyEvent` and a `MySecondEvent` would be processed concurrently.
:::

If you would like to enforce a global transformer scheme across event types, Joanna May's article ["How to Use Bloc With Streams and Concurrency"](https://verygood.ventures/blog/how-to-use-bloc-with-streams-and-concurrency) provides a concise guide.

### Transformer Types

The [Bloc Event Transformer API](https://bloclibrary.dev/bloc-concepts/#advanced-event-transformations) allows you to implement custom event transformers, but the [`bloc_concurrency`](https://pub.dev/packages/bloc_concurrency) package furnishes several out-of-the box transformers which cover a wide range of use cases. These include:

- `concurrent` (default)
- `sequential`
- `droppable`
- `restartable`

Let's investigate the `sequential`, `droppable`, and `restartable` transformers and look at how they're used.

#### Sequential

The `sequential` transformer ensures that events are handled one at a time, in a first in, first out order from when they are received.

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(MyState()) {
    on<MyEvent>(
      _onEvent,
      transformer: sequential(),
    )
  }
}
```

To illustrate the utility of sequential event handling, suppose we're building a money-tracking app. The `_onChangeBalance` handler first calls an API to read our current account balance, and then sends a call to update the balance to its new value:

```dart
class MoneyBloc extends Bloc<MoneyEvent, MoneyState> {
  MoneyBloc() : super(MoneyState()) {
    on<ChangeBalance>(_onChangeBalance, transformer: concurrent());
  }

  Future<void> _onChangeBalance(
    ChangeBalance event,
    Emitter<MoneyState> emit,
  ) async {
    final balance = await api.readBalance();
    await api.setBalance(balance + event.add);
  }
}
```

We then quickly add two events `ChangeBalance(add: 20)` and `ChangeBalance(add: 40)`, which will be handled concurrently. A possible sequence of events is:

- The first `ChangeBalance` handler instance will read a balance of `$100`, and send a not-yet-received request to the API to update the balance to `$120`.
- Before the first handler finishes its execution, the second handler executes, reads the old account value of `$100`, and completes an API request to update the balance to `$140`.
- Finally, the first handler's call to update the balance reaches the API, and the balance is now overwritten to `$120`.

This example illustrates the issues that can arise from concurrent handling of operations. Had we used a `sequential` transformer for the `ChangeBalance` event handler and ensured that the first addition of $20 had completed before processing the next event, we wouldn't have lost $40.

Note that when operations are safe to execute concurrently, using a `sequential` transformer can introduce unnecessary latency into event handling.

#### Droppable

The `droppable` transformer will discard any events that are added while an event in that bucket is already being processed.

```dart
class SayHiBloc extends Bloc<SayHiEvent, SayHiState> {
  SayHiBloc() : super(SayHiState()) {
    on<SayHello>(
      _onSayHello,
      transformer: droppable(),
    )
  }

  Future<void> _onSayHello(
    SayHello event,
    Emitter<SayHiState> emit,
  ) async {
    await api.say("Hello!");
  }
}
```

In the above example, we'd like to avoid clogging up our API with unnecessary duplicate greetings. The `droppable` transformer will ensure that additional `SayHello` events added while the first `_onSayHello` instance is executing will be discarded and never executed.

Since events added during ongoing handling will be discarded by the `droppable` transformer, ensure that you're OK with any data stored in that event being lost.

#### Restartable

The `restartable` transformer inverts the behavior of `droppable`, halting execution of previous event handlers in order to process the most recently received event.

```dart
class ThoughtBloc extends Bloc<ThoughtEvent, ThoughtState> {
  ThoughtBloc() : super(ThoughtState()) {
    on<ThoughtEvent>(
      _onThought,
      transformer: restartable(),
    )
  }

  Future<void> _onThought(
    ThoughtEvent event,
    Emitter<ThoughtState> emit,
  ) async {
    await api.record(event.thought);
    emit(
      state.copyWith(
        message: 'This is my most recent thought: ${event.thought}',
      )
    );
  }
}
```

If we want to avoid emitting the declaration that `${event.thought}` is my most recent thought when the bloc has received an even more recent thought, the `restartable` transformer will suspend `_onThought`'s processing of the outdated event if a more recent event is received during its execution.

#### Testing Blocs

When writing tests for a bloc, you may encounter an issue where a variable event handling order is acceptable in use, but the inconsistent sequence of event execution makes the determined order of states required by `blocTest`'s `expect` field results in unpredictable test behavior:

```dart
blocTest<MyBloc, MyState>(
  'change value',
  build: () => MyBloc(),
  act: (bloc) {
    bloc.add(ChangeValue(add: 1));
    bloc.add(ChangeValue(remove: 1));
  },
  expect: () => const [
    MyState(value: 1),
    MyState(value: 0),
  ],
);
```

If the `ChangeValue(remove: 1)` event completes execution before `ChangeValue(add: 1)` has finished, the resultant states will instead be `MyState(value: -1),MyState(value: 0)`, causing the test to fail.

Utilizing a `await Future<void>.delayed(Duration.zero)` statement in the `act` function will ensure that the task queue is empty before additional events are added:

```dart
blocTest<MyBloc, MyState>(
  'change value',
  build: () => MyBloc(),
  act: (bloc) {
    bloc.add(ChangeValue(add: 1));
    await Future<void>.delayed(Duration.zero);
    bloc.add(ChangeValue(remove: 1));
  },
  expect: () => const [
    MyState(value: 1),
    MyState(value: 0),
  ],
);
```

### Conclusion

[`bloc_concurrency`](https://pub.dev/packages/bloc_concurrency) provides several event transformers to ensure that your bloc handles events in a manner that's conducive to the goals of your state management system. If `concurrent`, `sequential`, `droppable`, or `restartable` are insufficient for your purposes (for example if you would like a custom debouncing interval), you can always implement a custom [`EventTransformer`](https://bloclibrary.dev/bloc-concepts/#advanced-event-transformations)
