#!/bin/bash
# Guard test: enforce the read-only contract for agents.
#
# For every agents/*.md:
#   1. The `tools` frontmatter must not grant a write tool (Edit, Write,
#      NotebookEdit). Both the inline form (`tools: Read, Glob`) and the YAML
#      block-list form (`tools:\n  - Read\n  - Glob`) are parsed.
#   2. If the agent grants Bash, its frontmatter must reference the read-only
#      git hook (allow-readonly-git.sh); otherwise Bash would be unrestricted.
#
# Exits 1 on any violation, 0 otherwise.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="${AGENTS_DIR:-$REPO_ROOT/agents}"

WRITE_TOOLS="Edit Write NotebookEdit"
READONLY_GIT_HOOK="allow-readonly-git.sh"

if [ ! -d "$AGENTS_DIR" ]; then
  echo "No agents/ directory found; nothing to guard."
  exit 0
fi

shopt -s nullglob
agent_files=("$AGENTS_DIR"/*.md)
if [ ${#agent_files[@]} -eq 0 ]; then
  echo "No agent files found in agents/; nothing to guard."
  exit 0
fi

# Print the space-separated list of tool names declared in an agent's `tools`
# frontmatter, handling both the inline and the YAML block-list forms.
extract_tools() {
  local file="$1"
  awk '
    # Track the frontmatter block (between the first two --- fences).
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---"   { exit }
    !in_fm { next }

    # Inline form: `tools: Read, Glob, Bash`
    /^tools:[[:space:]]*[^[:space:]]/ {
      sub(/^tools:[[:space:]]*/, "")
      gsub(/,/, " ")
      print
      next
    }

    # Block-list form: `tools:` followed by `  - Read` lines.
    /^tools:[[:space:]]*$/ { collecting = 1; next }
    collecting && /^[[:space:]]*-[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      printf "%s ", line
      next
    }
    collecting && /^[^[:space:]]/ { collecting = 0 }
  ' "$file"
}

failed=0

for file in "${agent_files[@]}"; do
  base="$(basename "$file")"
  tools="$(extract_tools "$file")"

  # 1. No write tools.
  for write_tool in $WRITE_TOOLS; do
    if echo "$tools" | grep -Eqw "$write_tool"; then
      echo "FAIL: $base grants write tool '$write_tool' in its tools frontmatter."
      failed=1
    fi
  done

  # 2. Bash must be paired with the read-only git hook.
  if echo "$tools" | grep -Eqw "Bash"; then
    if ! grep -q "$READONLY_GIT_HOOK" "$file"; then
      echo "FAIL: $base grants Bash but does not reference $READONLY_GIT_HOOK in its hooks."
      failed=1
    fi
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "Agent tools guard failed: agents must stay read-only."
  exit 1
fi

echo "Agent tools guard passed: no agent grants a write tool, and any Bash is hook-restricted."
exit 0
