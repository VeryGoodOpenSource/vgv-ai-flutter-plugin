---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: "The Cubit vs Bloc decision under pressure: debouncing is an event transform, so the Cubit is converted to a Bloc and the debounce becomes a transformer on the on<Event> registration."
---

Here is my search cubit:

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository) : super(const SearchState.initial());
  final SearchRepository _repository;
  Future<void> query(String term) async {
    final results = await _repository.search(term);
    emit(SearchState.loaded(results));
  }
}

Every keystroke calls query and the API is getting hammered. I want the input debounced. Should this stay a Cubit? Explain the decision, then show the refactored class.
