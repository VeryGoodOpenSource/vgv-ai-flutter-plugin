#!/bin/bash
# Tests for check-vgv-cli.sh
#
# Usage: bash hooks/scripts/check-vgv-cli_test.sh
#
# The hook reads a JSON payload from stdin and either emits a decision JSON on stdout
# (allow/deny) or exits silently, meaning it stood aside. Every case runs against a
# stubbed very_good on a PATH that contains nothing else, so results do not depend on
# what is installed on the machine running the tests.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/check-vgv-cli.sh"

PASSED=0
FAILED=0

STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

BASE_PATH="$(dirname "$(command -v jq)"):/usr/bin:/bin:/usr/sbin:/sbin"

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

# Returns the permissionDecision, or "aside" when the hook produced no decision.
run_hook() {
  local payload="$1"
  local output
  output=$(printf '%s' "$payload" \
    | env -i PATH="$STUB_DIR:$BASE_PATH" HOME="$STUB_DIR" PUB_CACHE="$STUB_DIR/pub-cache" \
        bash "$HOOK" 2>/dev/null) || true
  if [ -z "$output" ]; then
    echo "aside"
  else
    echo "$output" | jq -r '.hookSpecificOutput.permissionDecision'
  fi
}

assert_decision() {
  local expected="$1" label="$2" payload="$3"
  local result
  result=$(run_hook "$payload")
  if [ "$result" = "$expected" ]; then
    printf "  \033[32mPASS\033[0m  %-10s %s\n" "$expected" "$label"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  expected %s but got %s:  %s\n" "$expected" "$result" "$label"
    FAILED=$((FAILED + 1))
  fi
}

VGV_TOOL='{"tool_name":"mcp__very-good-cli__create","tool_input":{}}'
VGV_PLUGIN_TOOL='{"tool_name":"mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__test","tool_input":{}}'

echo "=== check-vgv-cli tests ==="
echo ""
echo "--- Tools that are not this hook's business (stand aside) ---"
no_cli
assert_decision aside "browser MCP call, Cursor naming"   '{"tool_name":"MCP:browser_tabs","tool_input":{"action":"list"}}'
assert_decision aside "browser MCP call, Claude naming"   '{"tool_name":"mcp__cursor-ide-browser__browser_navigate","tool_input":{}}'
assert_decision aside "shell tool call"                   '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
assert_decision aside "empty payload"                     '{}'
assert_decision aside "null tool_name"                    '{"tool_name":null}'
# Cursor's preToolUse payload carries no server segment, so a genuine Very Good CLI call
# is indistinguishable from any other server's `test`. Standing aside is the safe result.
assert_decision aside "server-less MCP name"              '{"tool_name":"MCP:test","tool_input":{}}'

echo ""
echo "--- Very Good CLI tools, CLI present and current ---"
stub_cli 1.5.0
assert_decision allow "version above minimum"             "$VGV_TOOL"
assert_decision allow "marketplace-namespaced tool"       "$VGV_PLUGIN_TOOL"
stub_cli 1.3.0
assert_decision allow "version exactly at minimum"        "$VGV_TOOL"

echo ""
echo "--- Very Good CLI tools, CLI missing or outdated ---"
stub_cli 1.2.9
assert_decision deny  "version below minimum"             "$VGV_TOOL"
stub_cli 0.9.0
assert_decision deny  "major version below minimum"       "$VGV_TOOL"
no_cli
assert_decision deny  "CLI not installed"                 "$VGV_TOOL"

echo ""
echo "--- CLI reachable only through the pub-cache fallback ---"
stub_cli 1.5.0 --in-pub-cache
assert_decision allow "resolved from PUB_CACHE, not PATH" "$VGV_TOOL"

echo ""
echo "--- Version unreadable (shim present, dart missing) ---"
stub_cli
assert_decision aside "inconclusive check does not deny"  "$VGV_TOOL"

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
