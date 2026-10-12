#!/bin/bash
# PreToolUse hook: block Bash commands that bypass MCP tools.
# Denies flutter create, dart create, very_good create, very_good test,
# very_good packages, flutter test, dart test.

if ! command -v jq &>/dev/null; then
  echo "jq is required for block-cli-workarounds hook but not found" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only shell commands are this hook's business. Filtering on .tool_input.command alone
# keys on a field name rather than the caller's identity, so an unrelated MCP tool that
# happens to take a `command` argument can reach this hook and be denied on a host that
# does not apply the hooks.json matcher. When a host sends no tool_name at all, fall
# through to the command check rather than silently dropping enforcement.
if [ -n "$TOOL_NAME" ] && ! is_shell_tool "$TOOL_NAME"; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# A deny refuses the whole shell call, so a command chained before or after the blocked
# one (`edit-a-file && dart test`) never runs either. Without saying so, the agent
# assumes the chained command's side effect happened and carries on without it.
WHOLE_CALL_REFUSED="This whole shell call was refused, so none of it ran: run any other commands it chained in a call of their own."

# Deny with an install/upgrade message when the CLI is missing or outdated, with a PATH
# message when dart is not there to run it, and otherwise redirect to the MCP tool.
deny_with_cli_check() {
  local mcp_hint="$1"
  local cli_status
  cli_status=$(check_vgv_cli)
  case "$cli_status" in
    not_installed)
      deny "Very Good CLI is required but was not found. Install with: dart pub global activate very_good_cli. $WHOLE_CALL_REFUSED"
      ;;
    outdated:*)
      local version="${cli_status#outdated:}"
      deny "Very Good CLI ${version} is too old (requires >= ${MIN_VERSION}). Update with: dart pub global activate very_good_cli. $WHOLE_CALL_REFUSED"
      ;;
    dart_missing)
      # Redirecting to the MCP tool here would be a dead end: the server starts through
      # the same very_good shim, which cannot exec dart from this PATH either. The advice
      # names no shell, since which startup file exports PATH differs per shell.
      deny "Very Good CLI was found but could not run: dart is not on the PATH available to hooks, so the very_good_cli MCP server cannot start either. Put the Dart SDK bin directory on the PATH your login shell always exports, or start Claude Code from a shell where dart already resolves, then begin a new session. $WHOLE_CALL_REFUSED"
      ;;
    unverifiable)
      # dart resolves, so the shim can run and the MCP server is not a dead end: the
      # version is just unreadable, which after a Dart SDK upgrade means a snapshot built
      # for the old SDK. Redirect as usual and say how to clear that if the tool fails.
      deny "$mcp_hint If that tool fails (for example with 'Invalid SDK hash'), the Dart SDK changed under the installed Very Good CLI: run 'very_good --version' once in a terminal to rebuild it, then reconnect the server with /mcp. $WHOLE_CALL_REFUSED"
      ;;
    *)
      deny "$mcp_hint $WHOLE_CALL_REFUSED"
      ;;
  esac
}

# Split on shell operators and check the first two tokens of each subcommand.
# This avoids false positives from file paths (.dart) or quoted strings.
BLOCKED=$(echo "$COMMAND" | awk '{
  n = split($0, parts, /[;&|]+/)
  for (i = 1; i <= n; i++) {
    gsub(/^[[:space:]]+/, "", parts[i])
    split(parts[i], w, /[[:space:]]+/)
    b = w[1]; s = w[2]
    if ((b == "flutter" || b == "dart") && s == "create")   { print "create";      exit }
    if ((b == "flutter" || b == "dart") && s == "test")     { print "test";         exit }
    if (b == "very_good" && s == "create")                  { print "vg_create";    exit }
    if (b == "very_good" && s == "test")                    { print "vg_test";      exit }
    if (b == "very_good" && s == "packages")                { print "vg_packages";  exit }
  }
}')

case "$BLOCKED" in
  create)      deny_with_cli_check "Do not use 'flutter create' or 'dart create'. Use the very_good_cli MCP 'create' tool instead." ;;
  test)        deny_with_cli_check "Do not use 'flutter test' or 'dart test'. Use the very_good_cli MCP 'test' tool instead." ;;
  vg_create)   deny_with_cli_check "Do not use 'very_good create' via shell. Use the very_good_cli MCP 'create' tool instead." ;;
  vg_test)     deny_with_cli_check "Do not use 'very_good test' via shell. Use the very_good_cli MCP 'test' tool instead." ;;
  vg_packages) deny_with_cli_check "Do not use 'very_good packages' via shell. Use the very_good_cli MCP 'packages_get' or 'packages_check_licenses' tool instead." ;;
esac

# Not a blocked command — allow
exit 0
