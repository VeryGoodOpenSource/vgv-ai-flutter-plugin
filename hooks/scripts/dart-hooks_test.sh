#!/bin/bash
# Tests for analyze.sh and format.sh
#
# Usage: bash hooks/scripts/dart-hooks_test.sh
#
# Both hooks have to read two different payload shapes:
#
#   Claude Code  Edit / Write  ->  .tool_input.file_path
#   Codex        apply_patch   ->  .tool_input.command (a patch envelope)
#
# Getting that wrong fails silently — the hook exits 0 having done nothing — so
# these cases assert exactly which files reach the Dart SDK. A stub `dart` on
# PATH records its arguments, which keeps the suite fast and means CI needs no
# Dart SDK installed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYZE="$SCRIPT_DIR/analyze.sh"
FORMAT="$SCRIPT_DIR/format.sh"

PASSED=0
FAILED=0

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# A `dart` that records the files it was asked to act on, and fails when told to.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/dart" <<'STUB'
#!/bin/bash
subcommand="$1"; shift
: > "$DART_STUB_LOG"
for arg in "$@"; do
  printf '%s\n' "$(basename "$arg")" >> "$DART_STUB_LOG"
done
if [ -n "${DART_STUB_FAIL:-}" ] && [ "$subcommand" = "analyze" ]; then
  echo "error - stubbed analyzer failure" >&2
  exit 1
fi
exit 0
STUB
chmod +x "$WORK/bin/dart"
export DART_STUB_LOG="$WORK/dart.log"

mkdir -p "$WORK/repo/lib"
: > "$WORK/repo/lib/a.dart"
: > "$WORK/repo/lib/b.dart"
: > "$WORK/repo/lib/renamed.dart"
: > "$WORK/repo/README.md"

# Run a hook with the stub first on PATH. Echoes the basenames dart received.
run_hook() {
  local hook="$1" payload="$2"
  : > "$DART_STUB_LOG"
  PATH="$WORK/bin:$PATH" bash "$hook" <<< "$payload" >/dev/null 2>&1
  LC_ALL=C sort "$DART_STUB_LOG" | tr '\n' ' '
}

assert_files() {
  local label="$1" hook="$2" payload="$3" expected="$4" actual
  actual=$(run_hook "$hook" "$payload")
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

assert_exit() {
  local label="$1" hook="$2" payload="$3" expected="$4" actual
  PATH="$WORK/bin:$PATH" bash "$hook" <<< "$payload" >/dev/null 2>&1
  actual=$?
  if [ "$actual" = "$expected" ]; then
    printf "  \033[32mPASS\033[0m  %s\n" "$label"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  %s (expected exit %s, got %s)\n" "$label" "$expected" "$actual"
    FAILED=$((FAILED + 1))
  fi
}

claude_payload() { jq -n --arg p "$1" '{"tool_input":{"file_path":$p}}'; }
codex_payload()  { jq -n --arg c "$1" --arg d "$WORK/repo" '{"cwd":$d,"tool_input":{"command":$c}}'; }

echo "=== Claude Code payloads (tool_input.file_path) ==="
assert_files "Edit on a .dart file" "$ANALYZE" \
  "$(claude_payload "$WORK/repo/lib/a.dart")" "a.dart "
assert_files "non-Dart file is ignored" "$ANALYZE" \
  "$(claude_payload "$WORK/repo/README.md")" ""
assert_files "path that does not exist is ignored" "$ANALYZE" \
  "$(claude_payload "$WORK/repo/lib/gone.dart")" ""
assert_files "empty payload" "$ANALYZE" '{}' ""

echo ""
echo "=== Codex payloads (tool_input.command, apply_patch envelope) ==="
assert_files "Update File, absolute path" "$ANALYZE" \
  "$(codex_payload "*** Begin Patch
*** Update File: $WORK/repo/lib/a.dart
@@
-old
+new
*** End Patch")" "a.dart "

assert_files "Update File, path relative to cwd" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Update File: lib/a.dart
@@
-old
+new
*** End Patch')" "a.dart "

assert_files "Add File" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Add File: lib/b.dart
+void main() {}
*** End Patch')" "b.dart "

assert_files "several files in one patch" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Add File: lib/b.dart
+void main() {}
*** Update File: lib/a.dart
@@
-old
+new
*** End Patch')" "a.dart b.dart "

assert_files "Delete File is skipped" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Delete File: lib/a.dart
*** End Patch')" ""

assert_files "Delete File does not swallow the preceding file" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Update File: lib/a.dart
@@
-old
+new
*** Delete File: lib/gone.dart
*** End Patch')" "a.dart "

# A rename lists both paths; only the destination exists once the patch lands.
assert_files "Move to wins over the original path" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Update File: lib/gone.dart
*** Move to: lib/renamed.dart
@@
-old
+new
*** End Patch')" "renamed.dart "

assert_files "non-Dart files in a patch are ignored" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Update File: README.md
@@
-old
+new
*** End Patch')" ""

assert_files "a patch touching nothing that exists" "$ANALYZE" \
  "$(codex_payload '*** Begin Patch
*** Update File: lib/nope.dart
@@
-old
+new
*** End Patch')" ""

echo ""
echo "=== Payloads that must not be read as an edit ==="
# Otherwise the hooks would fire on ordinary shell calls.
assert_files "a Bash command naming a .dart file" "$ANALYZE" \
  "$(codex_payload 'cat lib/a.dart')" ""
assert_files "a shell command quoting patch markers" "$ANALYZE" \
  "$(codex_payload 'echo "*** Add File: lib/a.dart"')" ""
# A heredoc puts a patch marker at the start of its own line, so only the
# "*** Begin Patch" guard distinguishes this from a real edit.
assert_files "a heredoc whose body starts with a patch marker" "$ANALYZE" \
  "$(codex_payload 'cat <<EOF > notes.txt
*** Add File: lib/a.dart
EOF')" ""
assert_files "a patch envelope that is not the first thing in the command" "$ANALYZE" \
  "$(codex_payload 'echo hi
*** Update File: lib/a.dart')" ""

echo ""
echo "=== Exit codes ==="
assert_exit "analyze exits 0 when the analyzer passes" "$ANALYZE" \
  "$(claude_payload "$WORK/repo/lib/a.dart")" 0
DART_STUB_FAIL=1 assert_exit "analyze exits 2 so the model sees the failure" "$ANALYZE" \
  "$(claude_payload "$WORK/repo/lib/a.dart")" 2
assert_exit "analyze exits 0 with nothing to do" "$ANALYZE" '{}' 0

echo ""
echo "=== format.sh ==="
assert_files "format reads a Claude payload" "$FORMAT" \
  "$(claude_payload "$WORK/repo/lib/a.dart")" "a.dart "
assert_files "format reads a Codex patch" "$FORMAT" \
  "$(codex_payload '*** Begin Patch
*** Update File: lib/a.dart
@@
-old
+new
*** End Patch')" "a.dart "
assert_exit "format never blocks, even on failure" "$FORMAT" \
  "$(claude_payload "$WORK/repo/lib/a.dart")" 0

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
