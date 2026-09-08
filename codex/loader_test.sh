#!/bin/bash
# Asserts that Codex loads this plugin through its own native install path.
#
# Usage: bash codex/loader_test.sh
#
# Installs the working tree as a Codex plugin into a throwaway CODEX_HOME —
# `codex plugin marketplace add` then `codex plugin add`, the same two commands
# a user runs — and then checks what Codex actually picked up. Your real Codex
# configuration is never touched.
#
# Needs the `codex` CLI but no credentials: the assertions go through
# `codex debug prompt-input` and `codex doctor --json`, which render local state
# without contacting a model.
#
# Codex silently ignores a malformed hooks.json and ships no validator for agent
# files, so those two are checked here directly rather than through the CLI.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$PLUGIN_ROOT/.codex-plugin/plugin.json"

PASSED=0
FAILED=0
pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() {
  printf "  \033[31mFAIL\033[0m  %s\n" "$1"
  if [ $# -gt 1 ]; then printf "        %s\n" "$2"; fi
  FAILED=$((FAILED + 1))
}
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected [$2], got [$3]"; fi
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
# project is a git repository, matching what a real user would have.
git -C "$WORKDIR" init -q

codex_in_sandbox() {
  env HOME="$FAKE_HOME" CODEX_HOME="$FAKE_CODEX_HOME" codex "$@"
}

printf '\033[1mCodex %s\033[0m\n' "$(codex --version 2>/dev/null | head -1)"

echo ""
echo "=== Plugin manifest ==="
PLUGIN_NAME=$(jq -r '.name // empty' "$MANIFEST" 2>/dev/null)
if [ -n "$PLUGIN_NAME" ]; then
  pass "plugin.json is valid JSON (name: $PLUGIN_NAME)"
else
  fail "plugin.json is valid JSON"
  exit 1
fi

# Codex ingestion requires all of these; a missing one makes the plugin
# uninstallable, and nothing else in this repo checks them.
for field in .version .description .author.name \
             .interface.displayName .interface.shortDescription \
             .interface.longDescription .interface.developerName \
             .interface.category .interface.capabilities .interface.defaultPrompt; do
  if [ -n "$(jq -r "$field // empty" "$MANIFEST")" ]; then
    pass "plugin.json has $field"
  else
    fail "plugin.json has $field"
  fi
done

# release-please bumps both manifests; drift means one of them is stale.
assert_eq "plugin.json version matches .claude-plugin/plugin.json" \
  "$(jq -r .version "$PLUGIN_ROOT/.claude-plugin/plugin.json")" \
  "$(jq -r .version "$MANIFEST")"
# `mcpServers` is what carries .mcp.json into Codex; without it there is no MCP.
assert_eq "plugin.json points mcpServers at .mcp.json" "./.mcp.json" \
  "$(jq -r '.mcpServers // empty' "$MANIFEST")"

echo ""
echo "=== Native install ==="
# The published marketplace entry lives in very-good-claude-code-marketplace and
# points here with a remote `url` source, so it always resolves the default
# branch. To test *this* working tree instead, synthesize a throwaway marketplace
# whose single entry is a local path — a symlink back to the checkout.
MARKETPLACE_NAME="loader-test"
MARKETPLACE_ROOT="$SANDBOX/marketplace"
mkdir -p "$MARKETPLACE_ROOT/.agents/plugins" "$MARKETPLACE_ROOT/plugins"
ln -s "$PLUGIN_ROOT" "$MARKETPLACE_ROOT/plugins/$PLUGIN_NAME"
jq -n --arg mp "$MARKETPLACE_NAME" --arg n "$PLUGIN_NAME" '{
  name: $mp,
  interface: { displayName: "Loader Test" },
  plugins: [ {
    name: $n,
    source: { source: "local", path: ("./plugins/" + $n) },
    policy: { installation: "AVAILABLE", authentication: "ON_INSTALL" },
    category: "Productivity"
  } ]
}' > "$MARKETPLACE_ROOT/.agents/plugins/marketplace.json"

if codex_in_sandbox plugin marketplace add "$MARKETPLACE_ROOT" >"$SANDBOX/mp.log" 2>&1; then
  pass "codex plugin marketplace add accepts the marketplace"
else
  fail "codex plugin marketplace add accepts the marketplace" "$(tail -3 "$SANDBOX/mp.log")"
  cat "$SANDBOX/mp.log" >&2
  exit 1
fi
# A marketplace entry Codex cannot resolve is dropped silently, so confirm the
# plugin is actually listed before trying to install it.
if codex_in_sandbox plugin list 2>/dev/null | grep -q "$PLUGIN_NAME@$MARKETPLACE_NAME"; then
  pass "the plugin resolves from the marketplace entry"
else
  fail "the plugin resolves from the marketplace entry" \
    "$(codex_in_sandbox plugin list 2>&1 | tail -2)"
  exit 1
fi
if codex_in_sandbox plugin add "$PLUGIN_NAME@$MARKETPLACE_NAME" >"$SANDBOX/add.log" 2>&1; then
  pass "codex plugin add installs the plugin"
else
  fail "codex plugin add installs the plugin" "$(tail -3 "$SANDBOX/add.log")"
  cat "$SANDBOX/add.log" >&2
  exit 1
fi

INSTALLED_ROOT=$(sed -n 's/^Installed plugin root: //p' "$SANDBOX/add.log" | tail -1)
if [ -n "$INSTALLED_ROOT" ] && [ -d "$INSTALLED_ROOT" ]; then
  pass "the installed plugin root exists"
else
  fail "the installed plugin root exists" "reported [${INSTALLED_ROOT:-none}]"
  exit 1
fi

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
  # Codex namespaces a plugin's skills as <plugin>:<skill>; accept either form.
  if ! grep -qE -- "- ($PLUGIN_NAME:)?$name: " "$PROMPT_JSON"; then
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
# They must come from the installed plugin, not from some other skills root.
if grep -qF "$INSTALLED_ROOT/skills" "$PROMPT_JSON"; then
  pass "the skills root is the installed plugin"
else
  fail "the skills root is the installed plugin" "$INSTALLED_ROOT/skills not listed"
fi

echo ""
echo "=== MCP servers load ==="
DOCTOR_JSON="$SANDBOX/doctor.json"
codex_in_sandbox doctor --json >"$DOCTOR_JSON" 2>/dev/null
doctor_status() {
  jq -r --arg id "$1" '.checks[] | select(.id == $id) | .status' "$DOCTOR_JSON" 2>/dev/null
}

status=$(doctor_status config.load)
assert_eq "codex doctor: config.load is ok" "ok" "${status:-no such check}"

# mcp.config degrades to a warning when the server executables are absent, which
# is the normal state anywhere without the Dart SDK and Very Good CLI installed,
# CI runners included. Only a hard failure means the config is wrong; what the
# servers were registered as is asserted below.
status=$(doctor_status mcp.config)
case "$status" in
  ok) pass "codex doctor: mcp.config is ok" ;;
  warning) pass "codex doctor: mcp.config has no errors (warning, likely no dart/very_good on PATH)" ;;
  *) fail "codex doctor: mcp.config has no errors" "got [${status:-no such check}]" ;;
esac

# Assert what each server was registered as, straight from .mcp.json, so this
# cannot drift from the file Claude Code reads.
while IFS= read -r server; do
  want_command=$(jq -r --arg s "$server" '.mcpServers[$s].command' "$PLUGIN_ROOT/.mcp.json")
  want_args=$(jq -r --arg s "$server" '(.mcpServers[$s].args // []) | join(" ")' "$PLUGIN_ROOT/.mcp.json")
  out=$(codex_in_sandbox mcp get "$server" 2>/dev/null)
  if [ -z "$out" ]; then
    fail "MCP server '$server' is registered"
    continue
  fi
  pass "MCP server '$server' is registered"
  for field in "enabled: true" "transport: stdio" "command: $want_command" "args: $want_args"; do
    if printf '%s\n' "$out" | grep -qF "$field"; then
      pass "  $server $field"
    else
      fail "  $server $field" "$(printf '%s' "$out" | tr '\n' ' ')"
    fi
  done
done < <(jq -r '.mcpServers | keys[]' "$PLUGIN_ROOT/.mcp.json")

echo ""
echo "=== Hooks ==="
# Codex discovers a plugin's hooks at <plugin root>/hooks/hooks.json — the same
# file Claude Code uses — and resolves ${CLAUDE_PLUGIN_ROOT} in it as a
# compatibility alias for the installed plugin directory.
INSTALLED_HOOKS="$INSTALLED_ROOT/hooks/hooks.json"
if [ -f "$INSTALLED_HOOKS" ]; then
  pass "hooks.json is installed at the plugin hook-discovery path"
else
  fail "hooks.json is installed at the plugin hook-discovery path" "$INSTALLED_HOOKS"
fi
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
assert_eq "every handler is a command handler with a string command" "0" "$bad_shape"

# Codex names its file-editing tool apply_patch, so a matcher that only says
# Edit|Write would never fire there. Claude Code ignores the extra alternative.
if jq -e '[.hooks.PostToolUse[].matcher] | all(test("apply_patch"))' "$INSTALLED_HOOKS" >/dev/null 2>&1; then
  pass "PostToolUse matchers cover Codex's apply_patch"
else
  fail "PostToolUse matchers cover Codex's apply_patch" \
    "$(jq -c '[.hooks.PostToolUse[].matcher]' "$INSTALLED_HOOKS")"
fi

# Every referenced script has to exist inside the installed plugin, or the hook
# is a silent no-op. This is also what proves ${CLAUDE_PLUGIN_ROOT} points at a
# real tree once expanded.
missing_scripts=""
checked=0
while IFS= read -r command; do
  [ -n "$command" ] || continue
  script=$(printf '%s' "$command" \
    | sed -n 's|.*\${CLAUDE_PLUGIN_ROOT}/\([^" ]*\).*|\1|p')
  [ -n "$script" ] || continue
  checked=$((checked + 1))
  if [ ! -f "$INSTALLED_ROOT/$script" ]; then
    missing_scripts="$missing_scripts $script"
  fi
done < <(jq -r '[.hooks[][] | .hooks[]?.command] | .[]' "$INSTALLED_HOOKS")

if [ "$checked" -eq 0 ]; then
  fail "hook commands reference plugin-root scripts" "no \${CLAUDE_PLUGIN_ROOT} references found"
elif [ -n "$missing_scripts" ]; then
  fail "all $checked hook scripts exist in the installed plugin" "missing:$missing_scripts"
else
  pass "all $checked hook scripts exist in the installed plugin"
fi

echo ""
echo "=== Agents ==="
# Codex reads custom agents from ~/.codex/agents or a project's .codex/agents,
# neither of which a plugin can populate, so the reviewer agent is a file users
# copy. Validate it here since Codex will not.
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
done

# Codex copies a custom agent verbatim, so the installed tree must carry it for
# the documented `cp` to work.
if [ -f "$INSTALLED_ROOT/codex/agents/flutter-reviewer.toml" ]; then
  pass "the reviewer agent ships inside the installed plugin"
else
  fail "the reviewer agent ships inside the installed plugin"
fi

# The read-only reviewer must stay read-only: Codex has no per-agent tool
# allowlist, so the sandbox is the only thing enforcing it.
reviewer="$PLUGIN_ROOT/codex/agents/flutter-reviewer.toml"
if [ -f "$reviewer" ]; then
  mode=$(agent_field "$reviewer" sandbox_mode)
  assert_eq "flutter-reviewer is sandboxed read-only" "read-only" "${mode:-unset}"
fi

echo ""
echo "=== Uninstall ==="
if codex_in_sandbox plugin remove "$PLUGIN_NAME@$MARKETPLACE_NAME" >"$SANDBOX/rm.log" 2>&1; then
  pass "codex plugin remove uninstalls it"
else
  fail "codex plugin remove uninstalls it" "$(tail -3 "$SANDBOX/rm.log")"
fi

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
