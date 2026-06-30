#!/bin/bash
# PreToolUse hook (flutter-reviewer agent): restrict Bash to read-only git inspection.
# Allows only `git diff` and `git status`. Denies everything else (file writes,
# git checkout/apply, redirections, compound-command bypass).
#
# Uses the shared deny() helper (JSON permissionDecision) for consistency with
# the other PreToolUse Bash hook (block-cli-workarounds.sh).

# Skip gracefully if jq is unavailable, matching the repo convention.
if ! command -v jq &>/dev/null; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

DENY_REASON="flutter-reviewer is read-only: only 'git diff' and 'git status' are allowed."

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Reject shell operators outright. A compound command (`;`, `&&`, `||`, `|`,
# redirections, command substitution) could smuggle a mutating command past a
# first-token check, so anything not a single bare git command is denied.
case "$COMMAND" in
  *";"* | *"&"* | *"|"* | *">"* | *"<"* | *'`'* | *'$('*)
    deny "$DENY_REASON"
    ;;
esac

# Allow only `git diff …` and `git status …` (with optional leading whitespace).
if echo "$COMMAND" | grep -Eq '^[[:space:]]*git[[:space:]]+(diff|status)([[:space:]]|$)'; then
  exit 0
fi

deny "$DENY_REASON"
