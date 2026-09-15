---
type: llm
---

PASS if the response puts the four gates in this sequence: analyze first, then
format, then test, then coverage. Judge the sequence only, never the presentation
— numbered steps, bullets, headings, a table, or plain prose all satisfy this
equally, as long as format is described as running after analyze and before the
test run, and coverage is read last. A later mention of a gate out of sequence
(re-running format in a following round, exiting once all four are green) does not
break the sequence.

FAIL only if the response states a different sequence — format before analyze,
test before format, or coverage before test — or if it never establishes any
sequence, naming the four gates without indicating which runs first.
