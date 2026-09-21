---
type: llm
---

PASS if the response proceeds with the name and organization it was given, without
interrogating the user for optional parameters such as a description, an output directory,
or an application id. Supplying its own value for an optional parameter satisfies this.

FAIL only if it asks the user to supply more input before proceeding.
