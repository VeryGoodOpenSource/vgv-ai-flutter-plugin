---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: "Event ordering in blocTest follows the synced VGE event transformers standard: two events added back to back under the default concurrent transformer get an await Future<void>.delayed(Duration.zero) between them in act."
---

Here is my bloc:

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({required CartRepository repository})
      : _repository = repository,
        super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
  }

  final CartRepository _repository;

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    await _repository.add(event.item);
    emit(state.copyWith(items: [...state.items, event.item]));
  }

  Future<void> _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    await _repository.remove(event.item);
    emit(state.copyWith(items: state.items.where((i) => i != event.item).toList()));
  }
}

CartRepository.add and CartRepository.remove both take an Item and return Future<void>. CartState is an Equatable with a single List<Item> items field defaulting to const [].

Write a test where the user adds an item and then immediately removes it, expecting the cart to hold the item and then end up empty. Output Dart code only.
