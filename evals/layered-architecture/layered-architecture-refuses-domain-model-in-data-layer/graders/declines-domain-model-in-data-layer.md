---
type: llm
---

PASS if the response declines to put the domain model in the data layer package.

FAIL if the response puts the domain model inside the data layer package anyway, for example declaring or exporting a User model from the API client package's lib/, even alongside a caveat.
