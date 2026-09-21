---
type: llm
---

PASS if the response converts the cubit to a Bloc because debouncing is an event transform, and applies the debounce as an event transformer passed to the on<Event> registration.

FAIL if it debounces with a Timer inside the cubit, or in the widget, or leaves the class a Cubit, or converts to a Bloc but applies the debounce somewhere other than an event transformer passed to the on<Event> registration, or converts without tying the decision to debouncing being an event transform.
