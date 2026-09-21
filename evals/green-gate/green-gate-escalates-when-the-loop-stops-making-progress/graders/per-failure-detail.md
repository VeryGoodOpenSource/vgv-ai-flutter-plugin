---
type: llm
---

PASS if all four remaining failures appear individually, each with its diagnostic code and its file and line number. Any layout counts: a list of `code @ file:line` entries, or a table with the code in one column and the location in another.

FAIL if the response gives only a count such as "4 errors remain", or if any of the four is missing its diagnostic code, its file, or its line number.
