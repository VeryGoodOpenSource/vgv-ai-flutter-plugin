---
type: llm
---

PASS if the reply reports all four gates as green and backs each with a number from this
run: no analyzer errors, zero files changed by the formatter, the tests passing, and a
coverage percentage at the target.

Commentary alongside those numbers does not fail this. A reply may add that the suite is
small, that 100% line coverage is shallow for a three-line class, that more tests would be
worth writing, or that a session-start hook warning appeared, and still pass. None of those
is a gate failure, and saying so is not a contradiction.

FAIL if it omits the formatter's changed count, omits a coverage percentage, or calls the
package green while reporting a number that makes a gate red — a coverage figure under the
target, a failing test, or an analyzer error.
