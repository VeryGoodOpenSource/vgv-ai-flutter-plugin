---
type: llm
---

PASS if the submit callback is gated on the form's validation status and passes the validated field values from state, for example state.email.value, into the event.

FAIL if it reads TextEditingController.text at the submit site, or if the submit callback is not gated on the form's validation status.
