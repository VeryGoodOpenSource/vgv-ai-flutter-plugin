#!/bin/bash
# Tests for warn-missing-mcp.sh
#
# Usage: bash hooks/scripts/warn-missing-mcp_test.sh
#
# The hook takes no input. It prints a warning to stdout when the Very Good CLI is
# missing, outdated, or present but unable to run, and prints nothing when the CLI is
# current. It always exits 0. Every case runs against a stubbed very_good on a PATH that
# contains nothing else, so results do not depend on what is installed on the machine.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/warn-missing-mcp.sh"

PASSED=0
FAILED=0

STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

BASE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# Install a stubbed very_good. With a version argument the stub reports that version;
# with no argument it fails the way the real shim does when `dart` is missing from PATH.
# Usage: stub_cli [version] [--in-pub-cache]
stub_cli() {
  local version="${1:-}"
  local location="${2:-}"
  local target="$STUB_DIR/very_good"
  rm -rf "$STUB_DIR/pub-cache" "$STUB_DIR/very_good"
  if [ "$location" = "--in-pub-cache" ]; then
    mkdir -p "$STUB_DIR/pub-cache/bin"
    target="$STUB_DIR/pub-cache/bin/very_good"
  fi
  if [ -z "$version" ]; then
    printf '#!/bin/sh\necho "very_good: dart: command not found" >&2\nexit 127\n' > "$target"
  else
    printf '#!/bin/sh\necho "very_good %s"\n' "$version" > "$target"
  fi
  chmod +x "$target"
}

no_cli() { rm -rf "$STUB_DIR/pub-cache" "$STUB_DIR/very_good"; }

# Install or remove a stubbed dart. The hooks only probe for its presence, so the stub
# needs no behavior: it is what separates "dart is off this PATH" from "dart runs and
# the version is still unreadable", which carry different diagnoses.
stub_dart() { printf '#!/bin/sh\nexit 0\n' > "$STUB_DIR/dart"; chmod +x "$STUB_DIR/dart"; }
no_dart() { rm -f "$STUB_DIR/dart"; }

# Runs the hook. Leaves stdout in LAST_OUTPUT and the exit status in LAST_STATUS.
LAST_OUTPUT=""
LAST_STATUS=0
run_hook() {
  LAST_STATUS=0
  LAST_OUTPUT=$(env -i PATH="$STUB_DIR:$BASE_PATH" HOME="$STUB_DIR" PUB_CACHE="$STUB_DIR/pub-cache" \
    bash "$HOOK" 2>/dev/null) || LAST_STATUS=$?
}

pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() { printf "  \033[31mFAIL\033[0m  %s\n    got (exit %s): %s\n" "$1" "$LAST_STATUS" "$LAST_OUTPUT"; FAILED=$((FAILED + 1)); }

# The hook is non-blocking: it must exit 0 whatever it finds.
assert_exit_zero() {
  if [ "$LAST_STATUS" -eq 0 ]; then pass "exit 0:  $1"; else fail "expected exit 0:  $1"; fi
}

assert_silent() {
  run_hook
  assert_exit_zero "$1"
  if [ -z "$LAST_OUTPUT" ]; then pass "silent:  $1"; else fail "expected no warning:  $1"; fi
}

assert_warns() {
  local needle="$1" label="$2"
  run_hook
  assert_exit_zero "$label"
  if [[ "$LAST_OUTPUT" == *"$needle"* ]]; then
    pass "warns '$needle':  $label"
  else
    fail "expected warning containing '$needle':  $label"
  fi
}

assert_omits() {
  local needle="$1" label="$2"
  run_hook
  assert_exit_zero "$label"
  if [[ "$LAST_OUTPUT" != *"$needle"* ]]; then
    pass "omits '$needle':  $label"
  else
    fail "expected no mention of '$needle':  $label"
  fi
}

echo "=== warn-missing-mcp tests ==="
echo ""
echo "--- CLI present and current (no warning) ---"
stub_cli 1.6.0
assert_silent "version above minimum"
stub_cli 1.5.0
assert_silent "version exactly at minimum"
stub_cli 1.6.0 --in-pub-cache
assert_silent "resolved from PUB_CACHE, not PATH"

echo ""
echo "--- CLI missing or outdated ---"
no_cli
assert_warns "not installed" "CLI not installed"
stub_cli 1.4.9
assert_warns "1.4.9 is too old" "version below minimum"

echo ""
echo "--- Version unreadable, dart missing (a PATH problem) ---"
# Not "not installed": the binary is there. The warning must point at dart and PATH.
no_dart
stub_cli
assert_warns "dart is not on the PATH" "CLI that cannot run points at PATH"

echo ""
echo "--- Version unreadable, dart present (not a PATH problem) ---"
# dart resolves, so PATH is not at fault. Blaming it here is the bug this split fixes:
# it sends users to edit shell profiles when the real cause is a snapshot built for an
# older SDK, cleared by running very_good once.
stub_dart
stub_cli
assert_warns "very_good --version" "unreadable version with dart present asks for a rebuild"
assert_warns "/mcp" "unreadable version with dart present says to reconnect the server"
assert_omits "dart is not on the PATH" "unreadable version with dart present never blames PATH"
no_dart

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
