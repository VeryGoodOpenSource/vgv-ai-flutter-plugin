---
type: llm
---

The response lays out a plan for upgrading a lint dependency in a Dart package. It was
asked to plan only, so judge the sequence it describes rather than any work performed.

PASS if all five of these appear in the plan, in this relative order:

1. editing the very_good_analysis entry in pubspec.yaml
2. running pub get
3. running analyze
4. fixing the warnings the new version introduced
5. running analyze a second time to confirm the result is clean

Numbering, headings and wording are free, and additional steps around or between these
five — resolving the version, matching dart to flutter commands, committing, opening a PR
— do not affect the verdict. The second analyze counts however it is framed; it need not
be tied to a commit.

FAIL if any of the five is missing, or if any two of them appear in the opposite of the
order above. In particular, FAIL if the plan fixes the warnings and stops there with no
second analyze.
