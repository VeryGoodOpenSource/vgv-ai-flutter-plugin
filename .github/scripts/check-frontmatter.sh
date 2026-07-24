#!/usr/bin/env bash
# Frontmatter portability guard.
#
# Covers the two silent-skip gaps validate-skill@v1 leaves open:
#   1. A UTF-8 BOM before the opening `---` passes validate-skill but makes
#      Gemini CLI (and any parser anchoring /^---/) skip the file silently.
#      Checked for every skills/**/SKILL.md and agents/**/*.md.
#   2. agents/**/*.md frontmatter has no validator at all (validate-skill
#      hard-requires the filename SKILL.md; `claude plugin validate` exits 0
#      on a broken agent block). Checked here: frontmatter first, closed,
#      non-empty name + description, name matches the filename stem.
#
# Skill frontmatter content is deliberately NOT re-validated here —
# Flash-Brew-Digital/validate-skill owns that in the validate-skills CI job.
#
# Parsing is plain-text matching, not YAML-aware: keys are expected as bare
# `name: value` / `description: value` lines (the only forms used in this
# repo). Quoted values would be flagged as mismatches — keep values unquoted.

set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

errors=0

fail() {
  echo "error: $1" >&2
  errors=$((errors + 1))
}

# Strip trailing CR (CRLF files) and trailing whitespace.
trim() {
  sed 's/[[:space:]]*$//'
}

# --- 1. BOM guard (skills + agents) ---------------------------------------
# find -L so symlinked SKILL.md files are checked too.
while IFS= read -r file; do
  if [ "$(head -c 3 "$file" | od -An -tx1 | tr -d ' \n')" = "efbbbf" ]; then
    fail "$file starts with a UTF-8 BOM — Gemini CLI silently skips it"
  fi
done < <(find -L skills -name SKILL.md -type f; find -L agents -name '*.md' -type f)

# --- 2. Agent frontmatter (agents only) -----------------------------------
while IFS= read -r file; do
  if [ "$(head -n 1 "$file" | trim)" != "---" ]; then
    fail "$file: frontmatter must start on line 1 with ---"
    continue
  fi
  close_line=$(awk 'NR > 1 && $0 ~ /^---[[:space:]]*$/ { print NR; exit }' "$file")
  if [ -z "$close_line" ]; then
    fail "$file: frontmatter block is never closed with ---"
    continue
  fi
  block=$(sed -n "2,$((close_line - 1))p" "$file" | trim)
  name=$(printf '%s\n' "$block" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)
  if [ -z "$name" ]; then
    fail "$file: frontmatter has no non-empty name"
  elif [ "$name" != "$(basename "$file" .md)" ]; then
    fail "$file: name '$name' does not match filename stem"
  fi
  if ! printf '%s\n' "$block" | grep -q '^description:'; then
    fail "$file: frontmatter has no description"
  else
    desc=$(printf '%s\n' "$block" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)
    case "$desc" in
      "" | "|" | "|-" | "|+" | ">" | ">-" | ">+")
        # Empty or block-scalar-only value: require at least one non-empty
        # indented continuation line, else the description is effectively
        # empty — the exact silent-skip case on Gemini/Codex/OpenCode.
        if ! printf '%s\n' "$block" | awk '
          /^description:/ { in_block = 1; next }
          in_block && /^[^[:space:]]/ { in_block = 0 }
          in_block && /[^[:space:]]/ { found = 1 }
          END { exit !found }
        '; then
          fail "$file: description is empty"
        fi
        ;;
    esac
  fi
done < <(find -L agents -name '*.md' -type f)

if [ "$errors" -gt 0 ]; then
  echo "check-frontmatter: $errors problem(s) found" >&2
  exit 1
fi

echo "check-frontmatter: all skills and agents pass"
