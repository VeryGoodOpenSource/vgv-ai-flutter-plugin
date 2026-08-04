# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VGV AI Flutter Plugin is a Claude Code plugin that provides best-practices skills for Flutter and Dart development. It is a **documentation-only repository** — there is no Dart/Flutter source code, no `pubspec.yaml`, and no tests. All value lives in the markdown skill files.

## Repository Structure

```text
.mcp.json                # MCP server configuration (Dart and Very Good CLI)
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, keywords)
agents/
  flutter-reviewer.md  # Read-only Flutter code reviewer subagent
docs/
  plan/                # Planning and design documents
evals/
  README.md            # Case format, assertion reference, how to add a case
  promptfooconfig.yaml # Claude Agent SDK provider + the two ablation columns
  tests/               # Eval cases, one YAML file per skill — all 15 covered, 100 cases
    accessibility.yaml
    animations.yaml
    bloc.yaml
    create-project.yaml
    dart-flutter-sdk-upgrade.yaml
    green-gate.yaml
    internationalization.yaml
    layered-architecture.yaml
    license-compliance.yaml
    material-theming.yaml
    navigation.yaml
    static-security.yaml
    testing.yaml
    ui-package.yaml
    very-good-analysis-upgrade.yaml
  assertions/
    dart-parses.js     # The one custom promptfoo assertion we own
  ci-summary.js        # Renders a promptfoo export into a GitHub step summary
  fixture/
    pubspec.yaml       # Neutral Flutter skeleton used as working-directory context
hooks/
  hooks.json           # Hook definitions (PreToolUse and PostToolUse)
  scripts/
    allow-readonly-git.sh  # Restricts flutter-reviewer Bash to git diff/status
    analyze.sh         # Runs dart analyze on modified .dart files
    block-cli-workarounds.sh  # Prevents direct CLI bypass via Bash
    check-vgv-cli.sh   # Validates VGV CLI installed and >= 1.3.0
    format.sh          # Runs dart format on modified .dart files
    vgv-cli-common.sh  # Shared utilities for VGV CLI hook scripts
    warn-missing-mcp.sh  # Warns at session start if VGV CLI is missing/outdated
skills/
  accessibility/SKILL.md
  accessibility/references/
  animations/SKILL.md
  animations/references/
    explicit-animations.md
    looping-animations.md
    page-transitions.md
    staggered-animations.md
  bloc/SKILL.md
  bloc/references/
  create-project/SKILL.md
  dart-flutter-sdk-upgrade/SKILL.md
  dart-flutter-sdk-upgrade/references/
    version-conflicts.md
  green-gate/SKILL.md
  green-gate/references/
    coverage.md
  internationalization/SKILL.md
  layered-architecture/SKILL.md
  layered-architecture/references/
  license-compliance/SKILL.md
  material-theming/SKILL.md
  navigation/SKILL.md
  static-security/SKILL.md
  static-security/references/
  testing/SKILL.md
  testing/references/
  ui-package/SKILL.md
  ui-package/reference.md
  very-good-analysis-upgrade/SKILL.md
  very-good-analysis-upgrade/references/
    lint-fixes.md
```

## Skill File Format

Every `SKILL.md` follows this structure:

1. **YAML frontmatter** with the following fields:
   - `name` _(required)_ — must match the skill's folder name exactly; lowercase letters, numbers, and hyphens only (e.g., `bloc`)
   - `description` _(required)_ — when the skill should be triggered
   - `allowed-tools` _(optional)_ — space-separated list of tools the skill may use (e.g., `Read Glob Grep`)
   - `argument-hint` _(optional)_ — placeholder hint shown to the user (e.g., `"[file-or-directory]"`)
2. **H1 title** — human-readable skill name
3. **Core Standards** — enforced constraints, always first
4. **Content sections** — architecture, code examples, workflows, anti-patterns

## Writing Conventions

- Frame standards as clear directives — no soft language ("consider", "prefer")
- Use fenced code blocks with language identifiers for all examples
- Provide complete, copy-pasteable snippets, not fragments
- Reference packages by full name (e.g., `package:mocktail`)
- Include anti-patterns alongside correct patterns when helpful
- Align pipe characters vertically in all markdown tables (enforced by markdownlint MD060)

## Adding a New Skill

1. Create `skills/<skill_name>/SKILL.md` following the format above
2. Create `evals/tests/<skill_name>.yaml` — eval cases with one prompt per major
   workflow the skill covers, a `skill-used` assertion on each, and one
   `not-skill-used` negative control. Routing assertions carry `weight: 3` so a routing
   miss cannot clear the per-case threshold. Register the file under `tests:` in
   `evals/promptfooconfig.yaml`. See `evals/README.md` for the format
3. Update `keywords` **and** the `description` (marketplace text) in `.claude-plugin/plugin.json`
4. Update the skills table in `README.md` (skill name must link to the `SKILL.md` file)
5. Add the skill's slash command (e.g., `/<skill-name>`) to the **Usage** list in `README.md`
6. Add any new domain terms to the `words` list in `config/cspell.json`
7. Update the repository structure in `CLAUDE.md`

## Adding a New Agent

Agents are subagents that Claude Code dispatches as isolated, specialized helpers (e.g., reviewers).
They live in `agents/<name>.md` at the plugin root and are **auto-discovered** — unlike skills, no
`.claude-plugin/plugin.json` change is required. An `agents/<name>.md` file registers as
`vgv-ai-flutter-plugin:<name>`.

1. Create `agents/<agent_name>.md` with YAML frontmatter:
   - `name` _(required)_ — must match the file name; lowercase letters, numbers, and hyphens only
   - `description` _(required)_ — when Claude should dispatch the agent
   - `tools` _(optional)_ — comma-separated bare tool names. The `tools` field cannot scope Bash by
     command; for a read-only agent, omit write tools (`Edit`, `Write`, `NotebookEdit`) and restrict
     Bash with an agent-scoped PreToolUse hook (see `flutter-reviewer.md`)
   - `skills` _(optional)_ — bare skill names to preload at startup (full skill content is injected)
   - `model` _(optional)_ — `inherit` to use the session model
   - `hooks` _(optional)_ — agent-scoped hooks, e.g. a PreToolUse `Bash` hook
2. Add an **Agents** table row in `README.md` (agent name links to the `agents/<name>.md` file)
3. Add any new domain terms to the `words` list in `config/cspell.json`
4. Update the repository structure in `CLAUDE.md`

## Maintaining Existing Skills, Hooks, and MCP Tools

Most documentation drift comes from changing existing assets without updating the
docs that describe them. When you touch any of the following, update the matching
documentation in the same change:

- **Updating a skill's scope or description** — update the matching row in the
  `README.md` skills table so the description stays in sync.
- **Changing what a skill teaches** — run the skill's eval cases to confirm the new
  guidance actually lands in the model's output, and update any case that asserted
  the old behavior. A failing case after a deliberate change means the case needs
  updating; a failing case after a Claude Code or MCP server change means the skill
  does.
- **Restructuring a skill's reference files** (`reference.md` ↔ `references/`) —
  update the repository structure block in `CLAUDE.md` to match the new layout, and
  update every markdown link pointing at the moved file. Nothing checks these links
  automatically, so verify each one by hand.
- **Adding or changing a hook** in `hooks/hooks.json` — update the **Hooks**
  section in `README.md` (and the `## Hooks` section in `CLAUDE.md` if behavior
  changes).
- **Adding or changing an MCP tool** — update the **MCP Integration** tools table
  in `README.md`, and check whether any skill's `allowed-tools` names a tool that
  was renamed or removed. Nothing validates those names.

## Evals

Evals ask whether Claude routes to a skill and follows it. `evals/README.md` is the
single source of truth for the case format, the assertion reference, prerequisites,
and what makes a case worth having — read it before writing a case, and put new eval
documentation there rather than here.

[promptfoo](https://www.promptfoo.dev) over the Claude Agent SDK; config
`evals/promptfooconfig.yaml`, cases `evals/tests/<skill>.yaml`. Run with
`npx promptfoo@latest eval -c evals/promptfooconfig.yaml`. Uses the local Claude
Code session, so no API key. Read the per-column split, not the total: the
`sealed-baseline` column is supposed to fail.

Run them by hand before opening a PR. They do **not** run on a pull request, because they
call real models; `.github/workflows/evals.yaml` runs them after a merge to `main`, scoped
to the changed skills, `with-skill` column only, and always non-blocking. A full run is
manual (`workflow_dispatch`) and is the expensive one.

Isolation between the two columns is held by the provider keys in `promptfooconfig.yaml`
and nothing checks it automatically, so treat any change to `tools`, `working_dir`,
`setting_sources` or `plugins` as invalidating earlier numbers.

## Hooks

The `hooks/` directory contains SessionStart, PreToolUse, and PostToolUse hooks defined in `hooks.json`.

### SessionStart Hooks

These run **when a session begins**:

- `warn-missing-mcp.sh` — checks if Very Good CLI is installed and >= 1.3.0; outputs a warning to Claude's context if missing or outdated (non-blocking)

### PreToolUse Hooks

These run **before** a tool call is executed:

- `mcp__.*very-good-cli__.*` matcher → `check-vgv-cli.sh` — auto-approves the Very Good CLI MCP tool call by returning a PreToolUse `allow` decision, so it is always permitted regardless of run mode (interactive, headless, or `skipAutoPermissionPrompt`) and never dead-ends when the tool isn't on `permissions.allow`; denies with an install/upgrade message if the CLI is missing or < 1.3.0. The `.*` in the matcher covers both the bare `mcp__very-good-cli__*` server (repo-root `.mcp.json`) and the plugin-namespaced `mcp__plugin_<plugin>_very-good-cli__*` form used when installed from a marketplace
- `Bash` matcher → `block-cli-workarounds.sh` — prevents direct CLI bypass of VGV CLI commands through the Bash tool; exits 2 on failure (blocking)

The first two PreToolUse hooks are plugin-level (defined in `hooks.json`) and share common utilities
from `vgv-cli-common.sh`. The following hook is **agent-scoped** — it is declared in the
`flutter-reviewer` agent's frontmatter, not in `hooks.json`, so it only fires for that agent:

- `Bash` matcher → `allow-readonly-git.sh` — restricts the `flutter-reviewer` agent's Bash to
  `git diff` / `git status` only; exits 2 on anything else, including compound-command bypass
  (blocking). Enforces the agent's read-only contract.

### PostToolUse Hooks

These run **after** a tool call completes:

- `Edit|Write` matcher → `analyze.sh` — runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix the issue)
- `Edit|Write` matcher → `format.sh` — runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking)

All hook scripts require **jq** to parse the hook payload (they skip gracefully if `jq` is not installed).

## Commits

Use conventional commits: `type(scope): description`

Examples: `feat: add bloc skill`, `chore: add logo to README`
