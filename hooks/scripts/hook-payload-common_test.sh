#!/bin/bash
# Tests for hook-payload-common.sh
#
# Usage: bash hooks/scripts/hook-payload-common_test.sh
#
# changed_dart_files() reads a hook payload and prints the `.dart` files it
# touched. It has to read both shapes the two harnesses produce:
#
#   Claude Code  Edit / Write  ->  .tool_input.file_path
#   Codex        apply_patch   ->  .tool_input.command (an apply_patch envelope)
#
# Each case builds real files in a temp tree, because the helper only reports
# paths that exist on disk.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hooks/scripts/hook-payload-common.sh
source "$SCRIPT_DIR/hook-payload-common.sh"

PASSED=0
FAILED=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/lib"
: > "$WORK/lib/a.dart"
: > "$WORK/lib/b.dart"
: > "$WORK/lib/renamed.dart"
: > "$WORK/README.md"

# Compare the helper's output (sorted) against the expected newline-separated list.
assert_files() {
  local label="$1" payload="$2" expected="$3"
  local actual
  actual=$(changed_dart_files "$payload" | LC_ALL=C sort | tr '\n' ' ')
  expected=$(printf '%s' "$expected" | tr '\n' ' ')
  if [ "$actual" = "$expected" ]; then
    printf "  \033[32mPASS\033[0m  %s\n" "$label"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  %s\n        expected: [%s]\n        actual:   [%s]\n" \
      "$label" "$expected" "$actual"
    FAILED=$((FAILED + 1))
  fi
}

patch_payload() {
  jq -n --arg c "$1" --arg d "$WORK" '{"cwd":$d,"tool_input":{"command":$c}}'
}

echo "=== Claude Code payloads (tool_input.file_path) ==="

assert_files "Edit on a .dart file" \
  "$(jq -n --arg p "$WORK/lib/a.dart" '{"tool_input":{"file_path":$p}}')" \
  "$WORK/lib/a.dart "

assert_files "Write to a non-Dart file is ignored" \
  "$(jq -n --arg p "$WORK/README.md" '{"tool_input":{"file_path":$p}}')" \
  ""

assert_files "path that does not exist is ignored" \
  "$(jq -n --arg p "$WORK/lib/gone.dart" '{"tool_input":{"file_path":$p}}')" \
  ""

assert_files "empty payload" '{}' ""

echo ""
echo "=== Codex payloads (tool_input.command, apply_patch envelope) ==="

assert_files "Update File with an absolute path" \
  "$(patch_payload "*** Begin Patch
*** Update File: $WORK/lib/a.dart
@@
-  print(\"hi\");
+  print(\"bye\");
*** End Patch")" \
  "$WORK/lib/a.dart "

assert_files "Update File with a path relative to cwd" \
  "$(patch_payload '*** Begin Patch
*** Update File: lib/a.dart
@@
-old
+new
*** End Patch')" \
  "$WORK/lib/a.dart "

assert_files "Add File" \
  "$(patch_payload '*** Begin Patch
*** Add File: lib/b.dart
+void main() {}
*** End Patch')" \
  "$WORK/lib/b.dart "

assert_files "several files in one patch" \
  "$(patch_payload '*** Begin Patch
*** Add File: lib/b.dart
+void main() {}
*** Update File: lib/a.dart
@@
-old
+new
*** End Patch')" \
  "$WORK/lib/a.dart $WORK/lib/b.dart "

assert_files "Delete File is skipped" \
  "$(patch_payload '*** Begin Patch
*** Delete File: lib/a.dart
*** End Patch')" \
  ""

assert_files "Delete File does not swallow the preceding file" \
  "$(patch_payload '*** Begin Patch
*** Update File: lib/a.dart
@@
-old
+new
*** Delete File: lib/gone.dart
*** End Patch')" \
  "$WORK/lib/a.dart "

assert_files "Move to wins over the original path" \
  "$(patch_payload '*** Begin Patch
*** Update File: lib/gone.dart
*** Move to: lib/renamed.dart
@@
-old
+new
*** End Patch')" \
  "$WORK/lib/renamed.dart "

assert_files "non-Dart files in a patch are ignored" \
  "$(patch_payload '*** Begin Patch
*** Update File: README.md
@@
-old
+new
*** End Patch')" \
  ""

assert_files "a patch that touches nothing that exists" \
  "$(patch_payload '*** Begin Patch
*** Update File: lib/nope.dart
@@
-old
+new
*** End Patch')" \
  ""

echo ""
echo "=== Payloads that must not be read as a patch ==="

# A Bash command that merely mentions a .dart file must never be treated as an
# edit — otherwise the PostToolUse hooks would fire on every shell call.
assert_files "a Bash command is not an apply_patch envelope" \
  "$(patch_payload 'cat lib/a.dart')" \
  ""

assert_files "a shell command quoting patch markers is not an envelope" \
  "$(patch_payload 'echo "*** Begin Patch"')" \
  ""

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
