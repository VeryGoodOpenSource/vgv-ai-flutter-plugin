@AGENTS.md

<!-- First line is the @AGENTS.md import (Claude Code memory), not a heading. -->

## Hooks

The `hooks/` directory contains SessionStart, PreToolUse, and PostToolUse hooks defined in `hooks.json`.

### SessionStart Hooks

These run **when a session begins**:

- `warn-missing-mcp.sh` — checks if Very Good CLI is installed and >= 1.3.0; outputs a warning to Claude's context if missing, outdated, or present but unable to run because `dart` is not on the `PATH` hooks inherit (non-blocking)

### PreToolUse Hooks

These run **before** a tool call is executed:

- `mcp__.*very-good-cli__.*` matcher → `check-vgv-cli.sh` — reads `tool_name` from the payload and exits 0 unless the caller is a Very Good CLI tool, so a host that does not apply the matcher cannot have the decision land on an unrelated tool; for its own tools it auto-approves the call by returning a PreToolUse `allow` decision, so it is always permitted regardless of run mode (interactive, headless, or `skipAutoPermissionPrompt`) and never dead-ends when the tool isn't on `permissions.allow`; denies with an install/upgrade message if the CLI is missing or < 1.3.0, and stands aside when the CLI is present but its version cannot be read (`dart` missing from `PATH`), leaving normal permission handling to apply. The `.*` in the matcher covers both the bare `mcp__very-good-cli__*` server (repo-root `.mcp.json`) and the plugin-namespaced `mcp__plugin_<plugin>_very-good-cli__*` form used when installed from a marketplace
- `Bash` matcher → `block-cli-workarounds.sh` — denies `flutter`/`dart` `test`/`create` and `very_good test`/`create`/`packages` in the shell and points to the MCP tool. Quoted text is data unless `eval`, `sh -c` or `$( )` runs it. Every adjacent word pair is checked, so wrappers (`fvm`, `melos`, `sudo`, `timeout`) and `/path/to/flutter` need no list. The denial names the match and says the whole call was refused. Pinned gaps: `"flutter" test` and `$F test` pass; unquoted `echo flutter test` is denied

The first two PreToolUse hooks are plugin-level (defined in `hooks.json`) and share common utilities
from `vgv-cli-common.sh`. The following hook is **agent-scoped** — it is declared in the
`flutter-reviewer` agent's frontmatter, not in `hooks.json`, so it only fires for that agent:

- `Bash` matcher → `allow-readonly-git.sh` — restricts the `flutter-reviewer` agent's Bash to
  single-line `git diff` / `git status` only; denies anything else, including compound or
  multi-line commands, shell expansion (`$`), and the `--output` / `--ext-diff` options that
  write files or run programs (blocking). Enforces the agent's read-only contract.

### PostToolUse Hooks

These run **after** a tool call completes:

- `Edit|Write` matcher → `analyze.sh` — runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix the issue)
- `Edit|Write` matcher → `format.sh` — runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking)

All hook scripts require **jq** to parse the hook payload (they skip gracefully if `jq` is not installed).

### Hook scoping

A `matcher` in `hooks.json` is a filter, not a guarantee — hosts name tools differently and do not
all treat a non-matching matcher as exclusionary. Every hook therefore confirms from its own
payload that the call is its business before deciding, and exits 0 when it is not. Scope on
`tool_name` rather than on the presence of a `tool_input` field, since field names such as
`command` are not unique to one tool.

`hooks/scripts/*_test.sh` covers the hook scripts and runs in CI under the **Script Tests** job.
Add cases there when changing hook behavior.
