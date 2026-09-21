---
type: llm
---

The response answers which version of a package it will upgrade to and how it will find
that version. It had no ability to run commands, so judge the method it commits to, not
whether a concrete version number came back.

PASS if the response commits to finding the target version itself and names the source or
command it will use to read the latest release, for example a request to the pub.dev API
for the package.

FAIL if it asks the user which version to target, tells the user to look the version up,
or names no way of finding it.
