#!/bin/bash
# PreToolUse hook (flutter-reviewer agent): restrict Bash to read-only git inspection.
# Allows only `git diff` and `git status`. Denies everything else (file writes,
# git checkout/apply, redirections, compound-command bypass, multi-line commands,
# and the file-writing and program-running options of git diff).
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
# A newline separates commands exactly like `;`, and the allow check below passes
# when any one line matches, so `git status` on the first line would carry every
# line after it. `$` is denied whole: expansions such as `${X:-...}` can produce
# option text the checks below never see.
case "$COMMAND" in
  *";"* | *"&"* | *"|"* | *">"* | *"<"* | *'`'* | *'$'* | *$'\n'* | *$'\r'*)
    deny "$DENY_REASON"
    ;;
esac

# Deny git options that write files or run programs: `--output` writes the diff to
# any path, and `--ext-diff` runs the configured external diff driver. Quotes and
# backslashes are stripped first so `"--output"` or `--out\put` cannot hide the option,
# and matching on the prefix covers both the `--output=<file>` and `--output <file>`
# forms. `--output-indicator-*` only changes the diff's marker characters, so it stays
# allowed.
read -ra WORDS <<<"${COMMAND//[\"\'\\]/}"
for word in "${WORDS[@]}"; do
  case "$word" in
    --output-indicator-*) ;;
    --out* | --ext*) deny "$DENY_REASON" ;;
  esac
done

# Allow only `git diff …` and `git status …` (with optional leading whitespace).
if echo "$COMMAND" | grep -Eq '^[[:space:]]*git[[:space:]]+(diff|status)([[:space:]]|$)'; then
  exit 0
fi

deny "$DENY_REASON"
