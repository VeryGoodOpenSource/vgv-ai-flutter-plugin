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
