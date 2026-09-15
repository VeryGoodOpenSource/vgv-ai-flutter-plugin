---
type: llm
---

PASS if the response states which changes it applied to `cart_total.dart`, and the set of
changes it says it applied is exactly two: adding a `const` keyword, and adding a trailing
comma. Naming a cast, a rename, or any other change **only to say it was not applied** —
deferred, declined, left out of this PR, handed to a human to review — is still a PASS, as is
listing lints it is not fixing.

FAIL only if the response says it applied a third change to the file: a cast on the dynamic
access, a rename, an extraction, a reordering, a reformat, or any other cleanup. Judge what the
response says it changed, not what the file might look like.
