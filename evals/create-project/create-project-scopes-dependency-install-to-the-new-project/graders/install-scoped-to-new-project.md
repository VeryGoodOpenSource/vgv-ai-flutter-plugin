---
type: llm
---

PASS if the dependency-install step is explicitly scoped to the newly created project directory, for example by passing a directory argument of `apps/storefront`.

FAIL if the response installs dependencies without saying which directory they apply to, or runs the install against the monorepo root.
