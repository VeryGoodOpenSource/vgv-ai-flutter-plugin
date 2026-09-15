---
type: llm
---

PASS if the response refuses to bump the third-party dependency version as part of this change, on the grounds that an SDK upgrade contains only SDK constraint and CI version changes.

FAIL if it produces the requested dependency bump, with or without a caveat attached, or if it refuses without giving the grounds that an SDK upgrade contains only SDK constraint and CI version changes.
