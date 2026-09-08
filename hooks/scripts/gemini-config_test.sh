#!/bin/bash
# Tests for the Gemini CLI port of the enforcement layer (.gemini/).
#
# Usage: bash hooks/scripts/gemini-config_test.sh
#
# Gemini CLI fails silently on every mistake this file guards against: an
# un-migrated Claude Code event name is skipped with a one-line warning, a
# timeout copied over in seconds becomes a few-millisecond timeout, a Claude
# tool matcher never matches a Gemini tool, and an agent whose frontmatter
# carries an unrecognized key is dropped from the registry. None of that breaks
# a build on its own, so it is asserted here.
#
# Static only: it reads the committed files and needs jq, not Gemini CLI.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETTINGS="$REPO_ROOT/.gemini/settings.json"
AGENT="$REPO_ROOT/.gemini/agents/flutter-reviewer.md"
MCP_JSON="$REPO_ROOT/.mcp.json"

PASSED=0
FAILED=0

pass() {
  printf "  \033[32mPASS\033[0m  %s\n" "$1"
  PASSED=$((PASSED + 1))
}

fail() {
  printf "  \033[31mFAIL\033[0m  %s\n" "$1"
  FAILED=$((FAILED + 1))
}

check() {
  # check "<label>" "<actual>" "<expected>"
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1 (expected '$3', got '$2')"
  fi
}

# Hook events Gemini CLI recognizes. Anything else is skipped at load time with
# "Invalid hook event name: ... Skipping." — including every Claude Code name
# except SessionStart.
GEMINI_EVENTS="BeforeTool AfterTool BeforeAgent AfterAgent BeforeModel AfterModel BeforeToolSelection SessionStart SessionEnd Notification PreCompress"

# Tools Gemini CLI accepts in an agent's `tools` list, plus the mcp_ prefix
# handled separately below.
GEMINI_TOOLS="glob write_todos write_file web_search web_fetch replace run_shell_command grep_search read_many_files read_file list_directory activate_skill ask_user get_internal_docs enter_plan_mode exit_plan_mode update_topic complete_task invoke_agent read_mcp_resource list_mcp_resources"

# Tools that would let the reviewer change the working tree. The Claude Code
# agent is held to read-only by the allow-readonly-git.sh PreToolUse hook;
# Gemini CLI has no agent-scoped hooks, so the same guarantee rests entirely on
# these three staying out of its tool list.
WRITE_TOOLS="write_file replace run_shell_command"

echo "=== Gemini CLI config tests ==="

# --- .gemini/settings.json -------------------------------------------------

echo ""
echo "--- settings.json ---"

if [ ! -f "$SETTINGS" ]; then
  fail "missing $SETTINGS"
  echo ""
  echo "=== Results: $PASSED passed, $FAILED failed ==="
  exit 1
fi

if jq empty "$SETTINGS" 2>/dev/null; then
  pass "settings.json is valid JSON"
else
  fail "settings.json is not valid JSON"
  echo ""
  echo "=== Results: $PASSED passed, $FAILED failed ==="
  exit 1
fi

# Every configured event must be one Gemini CLI actually fires.
while read -r event; do
  [ -z "$event" ] && continue
  if echo " $GEMINI_EVENTS " | grep -q " $event "; then
    pass "event '$event' is a Gemini CLI event name"
  else
    fail "event '$event' is not a Gemini CLI event name (Claude Code name left un-migrated?)"
  fi
done < <(jq -r '.hooks | keys[]' "$SETTINGS")

# Gemini CLI reads timeouts in milliseconds; Claude Code reads them in seconds.
# Copying 10 across turns a 10-second budget into a 10-millisecond one.
while read -r timeout; do
  [ -z "$timeout" ] && continue
  if [ "$timeout" -ge 1000 ]; then
    pass "timeout ${timeout} is in milliseconds"
  else
    fail "timeout ${timeout} looks like seconds; Gemini CLI reads milliseconds"
  fi
done < <(jq -r '[.hooks[][].hooks[].timeout] | unique[]' "$SETTINGS")

# Every hook is a command hook pointing at a script that exists.
while read -r type; do
  check "hook type is 'command'" "$type" "command"
done < <(jq -r '.hooks[][].hooks[].type' "$SETTINGS")

while read -r command; do
  [ -z "$command" ] && continue
  script="${command##*/}"
  script="${script%\"}"
  if [ -f "$SCRIPT_DIR/$script" ]; then
    pass "hook script hooks/scripts/$script exists"
  else
    fail "hook script hooks/scripts/$script does not exist"
  fi
done < <(jq -r '.hooks[][].hooks[].command' "$SETTINGS")

# Matchers must use Gemini CLI tool names. Claude Code's names never match.
while read -r matcher; do
  [ -z "$matcher" ] && continue
  if echo "$matcher" | grep -qE '(^|\|)(Bash|Edit|Write|Read|Glob|Grep|LS)($|\|)'; then
    fail "matcher '$matcher' uses Claude Code tool names"
  else
    pass "matcher '$matcher' uses Gemini CLI tool names"
  fi
done < <(jq -r '.hooks[][] | select(.matcher != null) | .matcher' "$SETTINGS")

# Gemini CLI exposes MCP tools as mcp_<server>_<tool>, not Claude Code's
# mcp__<server>__<tool>.
vgv_matcher=$(jq -r '[.hooks.BeforeTool[] | select(.matcher | test("very-good-cli")) | .matcher] | first // ""' "$SETTINGS")
check "Very Good CLI matcher uses Gemini MCP tool naming" "$vgv_matcher" "mcp_very-good-cli_.*"

# The two harnesses must register the same MCP servers.
claude_servers=$(jq -r '.mcpServers | keys | sort | join(",")' "$MCP_JSON")
gemini_servers=$(jq -r '.mcpServers | keys | sort | join(",")' "$SETTINGS")
check "MCP servers match .mcp.json" "$gemini_servers" "$claude_servers"

# --- .gemini/agents/flutter-reviewer.md ------------------------------------

echo ""
echo "--- flutter-reviewer agent ---"

if [ ! -f "$AGENT" ]; then
  fail "missing $AGENT"
  echo ""
  echo "=== Results: $PASSED passed, $FAILED failed ==="
  exit 1
fi

if [ "$(head -1 "$AGENT")" = "---" ]; then
  pass "frontmatter opens on line 1"
else
  fail "frontmatter must open with '---' on line 1"
fi

frontmatter=$(awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside' "$AGENT")

# Gemini CLI validates local agent frontmatter with a strict schema: any key
# outside this set drops the whole agent with a validation error.
allowed_keys="kind name description display_name tools mcp_servers model temperature max_turns timeout_mins"
while read -r key; do
  [ -z "$key" ] && continue
  if echo " $allowed_keys " | grep -q " $key "; then
    pass "frontmatter key '$key' is in Gemini's strict schema"
  else
    fail "frontmatter key '$key' is rejected by Gemini's strict agent schema"
  fi
done < <(echo "$frontmatter" | grep -E '^[a-z_]+:' | cut -d: -f1)

agent_name=$(echo "$frontmatter" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//')
check "agent name matches the file name" "$agent_name" "flutter-reviewer"

if echo "$frontmatter" | grep -qE '^description:'; then
  pass "agent declares a description"
else
  fail "agent must declare a description"
fi

tools=$(echo "$frontmatter" | awk '/^tools:/{inside=1; next} /^[a-z_]+:/{inside=0} inside && /^[[:space:]]*-[[:space:]]/{sub(/^[[:space:]]*-[[:space:]]*/, ""); print}')

if [ -z "$tools" ]; then
  fail "agent declares no tools"
else
  pass "agent declares an explicit tool list"
fi

for tool in $tools; do
  if echo " $GEMINI_TOOLS " | grep -q " $tool "; then
    pass "tool '$tool' is a Gemini CLI built-in"
  elif echo "$tool" | grep -qE '^mcp_[a-zA-Z0-9.:-]+_[a-zA-Z0-9_.:-]+$'; then
    pass "tool '$tool' is a well-formed MCP tool name"
  else
    fail "tool '$tool' is not a valid Gemini CLI tool name"
  fi
done

for tool in $WRITE_TOOLS; do
  if echo " $tools " | tr '\n' ' ' | grep -q " $tool "; then
    fail "read-only contract broken: agent grants '$tool'"
  else
    pass "read-only contract holds: agent does not grant '$tool'"
  fi
done

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
