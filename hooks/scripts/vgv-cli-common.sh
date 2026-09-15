#!/bin/bash
# Shared helpers for Very Good CLI version checks and hook deny responses.

MIN_VERSION="1.3.0"
MIN_MAJOR=1
MIN_MINOR=3
MIN_PATCH=0

# Which harness fired this hook. Claude Code names the pre-tool event
# "PreToolUse"; Gemini CLI names the same event "BeforeTool" and reads a
# different response shape, so every response helper branches on this.
# Set it with read_hook_event before calling deny/allow.
HOOK_EVENT_NAME="PreToolUse"

# Read the firing event name out of a hook payload, defaulting to Claude Code's
# name when the payload is empty or carries no event.
# Usage: HOOK_EVENT_NAME=$(read_hook_event "$INPUT")
read_hook_event() {
  local event
  event=$(printf '%s' "$1" | jq -r '.hook_event_name // empty' 2>/dev/null)
  echo "${event:-PreToolUse}"
}

deny() {
  if [ "$HOOK_EVENT_NAME" = "BeforeTool" ]; then
    # Gemini CLI reads a top-level decision/reason pair.
    jq -n \
      --arg reason "$1" \
      '{
        decision: "deny",
        reason: $reason
      }'
  else
    jq -n \
      --arg reason "$1" \
      '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: $reason
        }
      }'
  fi
  exit 0
}

# Auto-approve the tool call, skipping the interactive permission prompt.
# A PreToolUse "allow" fires before the permission-mode check, so the call
# proceeds in every run mode (interactive, headless, skipAutoPermissionPrompt).
# Explicit deny/ask rules and managed deny lists still take precedence.
#
# Gemini CLI has no auto-approve for BeforeTool hooks — a hook there can block
# or stay out of the way, nothing else — so this exits silently on that harness.
# The equivalent there is "trust": true on the MCP server in settings.json.
allow() {
  if [ "$HOOK_EVENT_NAME" = "BeforeTool" ]; then
    exit 0
  fi
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

# Check Very Good CLI availability and version.
# Returns: "ok", "not_installed", or "outdated:<version>"
check_vgv_cli() {
  if ! command -v very_good &>/dev/null; then
    echo "not_installed"
    return
  fi
  RAW=$(very_good --version 2>/dev/null)
  VERSION=$(echo "$RAW" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -z "$VERSION" ]; then
    echo "not_installed"
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
