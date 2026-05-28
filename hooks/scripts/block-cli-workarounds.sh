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
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Deny with an install/upgrade message when the CLI is missing or outdated,
# otherwise redirect to the MCP tool.
deny_with_cli_check() {
  local mcp_hint="$1"
  local cli_status
  cli_status=$(check_vgv_cli)
  case "$cli_status" in
    not_installed)
      deny "Very Good CLI is required but was not found. Install with: dart pub global activate very_good_cli"
      ;;
    outdated:*)
      local version="${cli_status#outdated:}"
      deny "Very Good CLI ${version} is too old (requires >= ${MIN_VERSION}). Update with: dart pub global activate very_good_cli"
      ;;
    *)
      deny "$mcp_hint"
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
