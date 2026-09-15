#!/bin/bash
# Shared helpers for Very Good CLI version checks and hook deny responses.

MIN_VERSION="1.3.0"
MIN_MAJOR=1
MIN_MINOR=3
MIN_PATCH=0

deny() {
  jq -n \
    --arg reason "$1" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
}

# Auto-approve the tool call, skipping the interactive permission prompt.
# A PreToolUse "allow" fires before the permission-mode check, so the call
# proceeds in every run mode (interactive, headless, skipAutoPermissionPrompt).
# Explicit deny/ask rules and managed deny lists still take precedence.
allow() {
  jq -n \
    --arg reason "$1" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
}

# True when the tool name identifies a Very Good CLI MCP tool. Claude Code names MCP
# tools mcp__<server>__<tool>, and mcp__plugin_<plugin>_<server>__<tool> when the plugin
# is installed from a marketplace; both carry the server segment this matches on.
is_vgv_cli_tool() {
  case "$1" in
    *very-good-cli*) return 0 ;;
    *) return 1 ;;
  esac
}

# True when the tool name identifies the host's shell tool. Claude Code calls it Bash,
# Cursor calls it Shell.
is_shell_tool() {
  case "$1" in
    Bash | Shell) return 0 ;;
    *) return 1 ;;
  esac
}

# Resolve the very_good binary. `dart pub global activate` installs it to
# ~/.pub-cache/bin, which an interactive shell adds to PATH but a hook subprocess does
# not necessarily inherit, so fall back to the pub-cache location before giving up.
resolve_vgv_bin() {
  if command -v very_good &>/dev/null; then
    command -v very_good
    return 0
  fi
  local fallback="${PUB_CACHE:-$HOME/.pub-cache}/bin/very_good"
  if [ -x "$fallback" ]; then
    echo "$fallback"
    return 0
  fi
  return 1
}

# Check Very Good CLI availability and version.
# Returns: "ok", "not_installed", "outdated:<version>", or "unverifiable".
#
# "unverifiable" means the binary was found but its version could not be read. The
# installed very_good is a shell shim that execs `dart`, so a PATH without dart on it
# makes the check inconclusive. Callers must not report that as "not installed".
check_vgv_cli() {
  local vgv_bin
  if ! vgv_bin=$(resolve_vgv_bin); then
    echo "not_installed"
    return
  fi
  RAW=$("$vgv_bin" --version 2>/dev/null)
  VERSION=$(echo "$RAW" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -z "$VERSION" ]; then
    echo "unverifiable"
    return
  fi
  IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
  if [ "$MAJOR" -lt "$MIN_MAJOR" ] 2>/dev/null ||
     { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -lt "$MIN_MINOR" ]; } 2>/dev/null ||
     { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -eq "$MIN_MINOR" ] && [ "$PATCH" -lt "$MIN_PATCH" ]; } 2>/dev/null; then
    echo "outdated:$VERSION"
    return
  fi
  echo "ok"
}
