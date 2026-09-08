#!/bin/bash
# Tests for codex/install.sh
#
# Usage: bash codex/install_test.sh
#
# Every case runs the installer against a throwaway CODEX_HOME and skills
# directory, so nothing touches the real ~/.codex. The `codex` CLI is not
# required — the installer warns and skips the MCP step when it is missing, and
# these tests only assert on the parts that are pure file manipulation (skills,
# hooks, agents).
#
# The hooks merge is the part worth guarding: it edits a shared file that other
# tools also write to, so it has to leave foreign entries alone and it has to be
# idempotent across re-runs.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$SCRIPT_DIR/install.sh"

PASSED=0
FAILED=0

pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() {
  printf "  \033[31mFAIL\033[0m  %s\n" "$1"
  if [ $# -gt 1 ]; then printf "        %s\n" "$2"; fi
  FAILED=$((FAILED + 1))
}

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$label"
  else
    fail "$label" "expected [$expected], got [$actual]"
  fi
}

# Run the installer in a fresh sandbox. Sets HOME_DIR / CODEX_DIR / SKILLS_DIR
# for the assertions that follow.
new_sandbox() {
  SANDBOX=$(mktemp -d)
  CODEX_DIR="$SANDBOX/codex"
  SKILLS_DIR="$SANDBOX/skills"
  mkdir -p "$CODEX_DIR"
}

install() {
  CODEX_HOME="$CODEX_DIR" bash "$INSTALLER" --skills-dir "$SKILLS_DIR" "$@" >"$SANDBOX/out.log" 2>&1
}

hooks_json() { cat "$CODEX_DIR/hooks.json"; }

# Count handler entries across every event.
count_handlers() {
  hooks_json | jq '[.hooks[][].hooks[]] | length'
}

# Count handlers belonging to this plugin.
count_vgv_handlers() {
  hooks_json | jq '[.hooks[][].hooks[] | select(.command | test("hooks/scripts/"))] | length'
}

cleanup() { [ -n "${SANDBOX:-}" ] && rm -rf "$SANDBOX"; }
trap cleanup EXIT

skill_count=$(find "$PLUGIN_ROOT/skills" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')

echo "=== Fresh install ==="
new_sandbox
install
assert_eq "installs every skill" "$skill_count" "$(ls "$SKILLS_DIR" | wc -l | tr -d ' ')"
if [ -L "$SKILLS_DIR/bloc" ]; then
  pass "skills are symlinked by default"
else
  fail "skills are symlinked by default"
fi
if [ -f "$SKILLS_DIR/bloc/SKILL.md" ]; then
  pass "a linked skill resolves to its SKILL.md"
else
  fail "a linked skill resolves to its SKILL.md"
fi
if [ -f "$CODEX_DIR/agents/flutter-reviewer.toml" ]; then
  pass "installs the flutter-reviewer agent"
else
  fail "installs the flutter-reviewer agent"
fi
assert_eq "installs 5 hook handlers" "5" "$(count_vgv_handlers)"
assert_eq "hooks.json has no leftover placeholder" "0" \
  "$(hooks_json | grep -c '__VGV_PLUGIN_ROOT__')"
assert_eq "hook commands point at this checkout" "5" \
  "$(hooks_json | jq --arg r "$PLUGIN_ROOT" '[.hooks[][].hooks[] | select(.command | contains($r))] | length')"
assert_eq "PostToolUse matches Codex apply_patch" "apply_patch|Edit|Write" \
  "$(hooks_json | jq -r '.hooks.PostToolUse[0].matcher')"
assert_eq "PreToolUse guards the very-good-cli MCP tools" "1" \
  "$(hooks_json | jq '[.hooks.PreToolUse[] | select(.matcher == "mcp__.*very-good-cli__.*")] | length')"
assert_eq "PreToolUse guards Bash" "1" \
  "$(hooks_json | jq '[.hooks.PreToolUse[] | select(.matcher == "Bash")] | length')"
cleanup

echo ""
echo "=== --copy ==="
new_sandbox
install --copy
if [ -d "$SKILLS_DIR/bloc" ] && [ ! -L "$SKILLS_DIR/bloc" ]; then
  pass "--copy installs real directories"
else
  fail "--copy installs real directories"
fi
cleanup

echo ""
echo "=== Re-running is idempotent ==="
new_sandbox
install
first=$(count_vgv_handlers)
install
assert_eq "handler count is unchanged after a second run" "$first" "$(count_vgv_handlers)"
install
assert_eq "handler count is unchanged after a third run" "$first" "$(count_vgv_handlers)"
cleanup

echo ""
echo "=== Merging into someone else's hooks.json ==="
new_sandbox
cat > "$CODEX_DIR/hooks.json" <<'EOF'
{
  "description": "someone else's hooks",
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "bash /opt/other/notify.sh" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "bash /opt/other/prompt.sh" } ] }
    ]
  }
}
EOF
install
assert_eq "our SessionStart group is added next to theirs" "2" \
  "$(hooks_json | jq '.hooks.SessionStart | length')"
assert_eq "foreign notify.sh is still registered" "1" \
  "$(hooks_json | jq '[.hooks[][].hooks[] | select(.command | contains("other/notify.sh"))] | length')"
assert_eq "foreign UserPromptSubmit event survives" "1" \
  "$(hooks_json | jq '[.hooks[][].hooks[] | select(.command | contains("other/prompt.sh"))] | length')"
assert_eq "unrelated top-level keys survive" "someone else's hooks" \
  "$(hooks_json | jq -r '.description')"
assert_eq "our handlers were added alongside" "5" "$(count_vgv_handlers)"
assert_eq "total handlers is theirs plus ours" "7" "$(count_handlers)"
if ls "$CODEX_DIR"/hooks.json.bak-* >/dev/null 2>&1; then
  pass "backs up the previous hooks.json"
else
  fail "backs up the previous hooks.json"
fi
# A second run must not duplicate ours or drop theirs.
install
assert_eq "re-run keeps the foreign handlers" "2" \
  "$(hooks_json | jq '[.hooks[][].hooks[] | select(.command | test("/opt/other/"))] | length')"
assert_eq "re-run does not duplicate ours" "5" "$(count_vgv_handlers)"
cleanup

echo ""
echo "=== --uninstall ==="
new_sandbox
cat > "$CODEX_DIR/hooks.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "bash /opt/other/notify.sh" } ] }
    ]
  }
}
EOF
install
install --uninstall
assert_eq "removes our hook handlers" "0" "$(count_vgv_handlers)"
assert_eq "leaves the foreign handler in place" "1" "$(count_handlers)"
assert_eq "removes the installed skills" "0" "$(ls "$SKILLS_DIR" 2>/dev/null | wc -l | tr -d ' ')"
if [ ! -f "$CODEX_DIR/agents/flutter-reviewer.toml" ]; then
  pass "removes the flutter-reviewer agent"
else
  fail "removes the flutter-reviewer agent"
fi
cleanup

echo ""
echo "=== --uninstall on a hooks.json we never touched ==="
new_sandbox
echo '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"bash /opt/other/stop.sh"}]}]}}' \
  > "$CODEX_DIR/hooks.json"
install --uninstall
assert_eq "leaves it alone" "1" "$(count_handlers)"
cleanup

echo ""
echo "=== --dry-run ==="
new_sandbox
install --dry-run
if [ ! -e "$CODEX_DIR/hooks.json" ] && [ ! -e "$SKILLS_DIR" ]; then
  pass "--dry-run writes nothing"
else
  fail "--dry-run writes nothing"
fi
if grep -q 'would install' "$SANDBOX/out.log"; then
  pass "--dry-run reports what it would do"
else
  fail "--dry-run reports what it would do"
fi
cleanup

echo ""
echo "=== Bad input ==="
new_sandbox
if install --nonsense; then
  fail "rejects an unknown option"
else
  pass "rejects an unknown option"
fi
cleanup

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
