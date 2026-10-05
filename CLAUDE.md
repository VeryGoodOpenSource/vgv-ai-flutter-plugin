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
- `Bash` matcher → `block-cli-workarounds.sh` — routes direct CLI invocations to the Very Good CLI MCP tools, through the host's shell tool (`Bash`, or `Shell` on other hosts). It exits 0 when the payload names a non-shell tool, so an unrelated tool carrying a `command` argument is never inspected, and blocks by returning a PreToolUse `deny` decision. Every denial names what it matched and says the whole shell call was refused, so the agent re-runs any command chained with the blocked one instead of assuming it ran. When the CLI is present but cannot run because `dart` is missing from `PATH`, the denial says so rather than redirecting to an MCP server that cannot start. Matching works in two passes:
  - **Pass 1 neutralizes quoting**, so an argument that merely contains a governed string is never read as a command: a quoted `|` is not a pipe, a quoted phrase is one word, and an unquoted `#` comments out the rest of the line. `$( )` and backticks stay command positions even inside double quotes, because the shell still runs them.
  - **Pass 2 tests every adjacent token pair** in each fragment, matching the first on its basename. There is no wrapper list to maintain: `fvm`, `melos exec --`, `timeout`, `sudo -u ci`, `env -i`, `xargs`, `nice`, shell keywords (`then`, `do`), brace groups and `/usr/local/bin/flutter` are all covered by the same rule.

  The trade is that an unquoted `echo flutter test` is denied; text mentioning a governed command belongs in quotes, which pass 1 makes inert. `eval "flutter test"` and `F=flutter; $F test` still pass — catching those means reading inside quotes, which is the issue #147 bug, or executing the command. Those and heredoc bodies are pinned by tests so a change is visible

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
