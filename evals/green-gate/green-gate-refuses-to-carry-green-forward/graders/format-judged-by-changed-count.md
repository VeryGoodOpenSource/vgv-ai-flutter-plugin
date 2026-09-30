---
type: llm
---

PASS if the response ties the format gate's verdict to how many files the formatter
changed, with zero changed being green.

A described gate counts. This prompt asks what the responder would do rather than for a
run, so "green means the output reads (0 changed), not merely that the call succeeded"
passes exactly as a reported result would. Judge the stated rule, not whether a tool ran.

FAIL if the format step is treated as green because the call succeeded, or if the response
never connects the format verdict to a count of changed files.
