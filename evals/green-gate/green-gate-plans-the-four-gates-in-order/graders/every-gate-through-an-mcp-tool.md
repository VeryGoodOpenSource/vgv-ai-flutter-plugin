---
type: llm
---

PASS if tests and coverage are produced by a single Very Good CLI test tool call carrying coverage arguments, formatting goes through the Dart MCP server's format tool, and every gate runs through an MCP tool rather than a shell command. Naming `flutter test`, `dart test` or `dart format` only to say that path is redundant or blocked still satisfies this.

FAIL if it plans to actually run a gate through a shell command, if tests and coverage are split across separate calls rather than one test tool call carrying coverage arguments, or if formatting does not go through the Dart MCP server's format tool.
