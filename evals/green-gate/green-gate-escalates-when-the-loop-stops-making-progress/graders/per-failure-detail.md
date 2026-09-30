---
type: llm
---

PASS if all four remaining failures appear individually, each with its diagnostic code and
its file and line number. Any layout counts: a list of `code @ file:line` entries, or a
table with the code in one column and the location in another.

Judge only whether those four entries are present and complete. A response that also asks
for the analyzer's full message text, or says the codes alone do not identify the root
cause, still passes — wanting more detail is not the same as omitting the detail required
here.

FAIL if the response gives only a count such as "4 errors remain", or if any of the four is
missing its diagnostic code, its file, or its line number.
