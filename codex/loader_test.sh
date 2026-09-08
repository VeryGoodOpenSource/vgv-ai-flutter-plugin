#!/bin/bash
# Asserts that Codex actually loads what codex/install.sh installs.
#
# Usage: bash codex/loader_test.sh
#
# Requires the `codex` CLI. Everything runs against a throwaway CODEX_HOME and a
# throwaway HOME, so your real Codex configuration is never touched.
#
# The checks that need Codex use `codex debug prompt-input`, which renders the
# model-visible prompt as JSON without contacting a model, so this needs no
# credentials and costs nothing. Codex silently ignores a malformed hooks.json
# and has no validator for agent files, so those two are checked here directly
# rather than through the CLI.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASSED=0
FAILED=0
pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() {
  printf "  \033[31mFAIL\033[0m  %s\n" "$1"
  if [ $# -gt 1 ]; then printf "        %s\n" "$2"; fi
  FAILED=$((FAILED + 1))
}

for tool in codex jq python3; do
  if ! command -v "$tool" &>/dev/null; then
    printf "\033[31merror\033[0m  %s is required to run the Codex loader test\n" "$tool" >&2
    exit 1
  fi
done

# The agent files are TOML and Codex ships no validator for them, so they are
# parsed here. tomllib is standard from Python 3.11; older versions need tomli.
TOML_MODULE=""
for candidate in tomllib tomli; do
  if python3 -c "import $candidate" 2>/dev/null; then
    TOML_MODULE="$candidate"
    break
  fi
done
if [ -z "$TOML_MODULE" ]; then
  printf "\033[31merror\033[0m  no TOML parser available for %s\n" "$(python3 -V 2>&1)" >&2
  printf "        use Python 3.11+ (stdlib tomllib), or: python3 -m pip install tomli\n" >&2
  exit 1
fi

SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT
FAKE_HOME="$SANDBOX/home"
FAKE_CODEX_HOME="$SANDBOX/codex"
WORKDIR="$SANDBOX/project"
mkdir -p "$FAKE_HOME" "$FAKE_CODEX_HOME" "$WORKDIR"

# Codex scans for repo-scoped skills up to the repository root, so the scratch
# project needs to be a git repository for discovery to behave as it would for a
# real user.
git -C "$WORKDIR" init -q

printf '\033[1mCodex %s\033[0m\n' "$(codex --version 2>/dev/null | head -1)"

echo ""
echo "=== Install ==="
if CODEX_HOME="$FAKE_CODEX_HOME" bash "$SCRIPT_DIR/install.sh" \
     --skills-dir "$FAKE_HOME/.agents/skills" >"$SANDBOX/install.log" 2>&1; then
  pass "codex/install.sh completes"
else
  fail "codex/install.sh completes" "$(tail -5 "$SANDBOX/install.log")"
  cat "$SANDBOX/install.log" >&2
  exit 1
fi

# Everything below runs as if $FAKE_HOME were the user's home directory.
codex_in_sandbox() {
  env HOME="$FAKE_HOME" CODEX_HOME="$FAKE_CODEX_HOME" codex "$@"
}

echo ""
echo "=== Skills load ==="
PROMPT_JSON="$SANDBOX/prompt-input.json"
if (cd "$WORKDIR" && codex_in_sandbox debug prompt-input "hello" >"$PROMPT_JSON" 2>"$SANDBOX/pi.err"); then
  pass "codex debug prompt-input succeeds"
else
  fail "codex debug prompt-input succeeds" "$(tail -5 "$SANDBOX/pi.err")"
  exit 1
fi

expected=0
missing=""
for dir in "$PLUGIN_ROOT"/skills/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  name="$(basename "$dir")"
  expected=$((expected + 1))
  # Codex namespaces a skill when it can resolve a plugin manifest above it, so
  # accept both the bare and the namespaced listing.
  if ! grep -qE -- "- (vgv-ai-flutter-plugin:)?$name: " "$PROMPT_JSON"; then
    missing="$missing $name"
  fi
done

if [ "$expected" -eq 0 ]; then
  fail "found skills to check" "no SKILL.md files under $PLUGIN_ROOT/skills"
elif [ -n "$missing" ]; then
  fail "all $expected skills appear in the Codex prompt" "missing:$missing"
else
  pass "all $expected skills appear in the Codex prompt"
fi

echo ""
echo "=== Config loads ==="
DOCTOR_JSON="$SANDBOX/doctor.json"
codex_in_sandbox doctor --json >"$DOCTOR_JSON" 2>/dev/null
# `codex doctor` exits non-zero when it cannot find credentials, which is the
# normal state here, so assert on the individual checks instead of the exit code.
doctor_status() {
  jq -r --arg id "$1" '.checks[] | select(.id == $id) | .status' "$DOCTOR_JSON" 2>/dev/null
}

# config.load proves the TOML the installer wrote actually parses.
status=$(doctor_status config.load)
if [ "$status" = "ok" ]; then
  pass "codex doctor: config.load is ok"
else
  fail "codex doctor: config.load is ok" "got [${status:-no such check}]"
fi

# mcp.config downgrades to a warning when the server executables are missing,
# which is the normal state anywhere without the Dart SDK and Very Good CLI
# installed — CI runners included. Only a hard failure means the config is
# wrong; what the servers were registered *as* is asserted below instead.
status=$(doctor_status mcp.config)
case "$status" in
  ok)
    pass "codex doctor: mcp.config is ok"
    ;;
  warning)
    pass "codex doctor: mcp.config has no errors (warning, likely no dart/very_good on PATH)"
    ;;
  *)
    fail "codex doctor: mcp.config has no errors" "got [${status:-no such check}]"
    ;;
esac

# Assert what each server was registered as, so a warning above can never hide a
# server pointing at the wrong command.
assert_mcp_server() {
  local server="$1" want_command="$2" want_args="$3" out
  out=$(codex_in_sandbox mcp get "$server" 2>/dev/null)
  if [ -z "$out" ]; then
    fail "MCP server '$server' is registered"
    return
  fi
  pass "MCP server '$server' is registered"
  for field in "enabled: true" "transport: stdio" "command: $want_command" "args: $want_args"; do
    if printf '%s\n' "$out" | grep -qF "$field"; then
      pass "  $server $field"
    else
      fail "  $server $field" "$(printf '%s' "$out" | tr '\n' ' ')"
    fi
  done
}

assert_mcp_server dart dart "mcp-server --enable dart_format"
assert_mcp_server very-good-cli very_good "mcp"

echo ""
echo "=== Hooks are well-formed ==="
# Codex ignores a malformed hooks.json without reporting anything, so a broken
# file would disable the whole enforcement layer silently. Check it here.
INSTALLED_HOOKS="$FAKE_CODEX_HOME/hooks.json"
if jq -e . "$INSTALLED_HOOKS" >/dev/null 2>&1; then
  pass "installed hooks.json is valid JSON"
else
  fail "installed hooks.json is valid JSON"
fi

for event in SessionStart PreToolUse PostToolUse; do
  if jq -e --arg e "$event" '.hooks[$e] | arrays and (length > 0)' "$INSTALLED_HOOKS" >/dev/null 2>&1; then
    pass "$event is wired"
  else
    fail "$event is wired"
  fi
done

bad_shape=$(jq '[.hooks[][] | .hooks[]? | select((.type != "command") or ((.command | type) != "string"))] | length' "$INSTALLED_HOOKS")
if [ "$bad_shape" = "0" ]; then
  pass "every handler is a command handler with a string command"
else
  fail "every handler is a command handler with a string command" "$bad_shape malformed"
fi

unresolved=$(grep -c '__VGV_PLUGIN_ROOT__' "$INSTALLED_HOOKS")
if [ "$unresolved" = "0" ]; then
  pass "no unresolved plugin-root placeholder"
else
  fail "no unresolved plugin-root placeholder" "$unresolved left"
fi

# Every script a hook points at must exist and be readable, or the hook is a
# silent no-op at runtime.
missing_scripts=""
while IFS= read -r script; do
  [ -n "$script" ] || continue
  if [ ! -f "$script" ]; then
    missing_scripts="$missing_scripts $script"
  fi
done < <(jq -r '[.hooks[][] | .hooks[]?.command] | .[]' "$INSTALLED_HOOKS" \
          | sed -n 's/^bash "\(.*\)"$/\1/p')
if [ -z "$missing_scripts" ]; then
  pass "every hook script exists on disk"
else
  fail "every hook script exists on disk" "missing:$missing_scripts"
fi

echo ""
echo "=== Agents are well-formed ==="

# Print one top-level key from an agent file, or nothing if it is absent.
agent_field() {
  python3 -c "
import sys, $TOML_MODULE as toml
with open(sys.argv[1], 'rb') as fh:
    print(toml.load(fh).get(sys.argv[2], ''))
" "$1" "$2" 2>/dev/null
}

for agent in "$PLUGIN_ROOT"/codex/agents/*.toml; do
  [ -f "$agent" ] || continue
  name="$(basename "$agent")"
  if python3 -c "
import sys, $TOML_MODULE as toml
with open(sys.argv[1], 'rb') as fh:
    data = toml.load(fh)
missing = [k for k in ('name', 'description', 'developer_instructions') if not data.get(k)]
if missing:
    print('missing required fields: ' + ', '.join(missing), file=sys.stderr)
    sys.exit(1)
" "$agent"
  then
    pass "$name parses and has the required fields"
  else
    fail "$name parses and has the required fields"
  fi

  if [ -f "$FAKE_CODEX_HOME/agents/$name" ]; then
    pass "$name is installed into CODEX_HOME/agents"
  else
    fail "$name is installed into CODEX_HOME/agents"
  fi
done

# The read-only reviewer must stay read-only: Codex has no per-agent tool
# allowlist, so the sandbox is the only thing enforcing it.
reviewer="$PLUGIN_ROOT/codex/agents/flutter-reviewer.toml"
if [ -f "$reviewer" ]; then
  mode=$(agent_field "$reviewer" sandbox_mode)
  if [ "$mode" = "read-only" ]; then
    pass "flutter-reviewer is sandboxed read-only"
  else
    fail "flutter-reviewer is sandboxed read-only" "sandbox_mode is [${mode:-unset}]"
  fi
fi

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
