# VGV AI Flutter Plugin

## Project Overview

VGV AI Flutter Plugin provides best-practices skills for Flutter and Dart development. It is a **documentation-only repository** — there is no Dart/Flutter source code, no `pubspec.yaml`, and no tests. All value lives in the markdown skill files.

## Repository Structure

```text
.mcp.json                # MCP server configuration (Dart and Very Good CLI)
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, keywords)
agents/
  flutter-reviewer.md  # Read-only Flutter code reviewer subagent
docs/
  plan/                # Planning and design documents
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
  very-good-analysis-upgrade/reference.md
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
2. Update `keywords` **and** the `description` (marketplace text) in `.claude-plugin/plugin.json`
3. Update the skills table in `README.md` (skill name must link to the `SKILL.md` file)
4. Add the skill's slash command (e.g., `/<skill-name>`) to the **Usage** list in `README.md`
5. Add any new domain terms to the `words` list in `config/cspell.json`
6. Update the repository structure in `AGENTS.md`

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
4. Update the repository structure in `AGENTS.md`

## Maintaining Existing Skills, Hooks, and MCP Tools

Most documentation drift comes from changing existing assets without updating the
docs that describe them. When you touch any of the following, update the matching
documentation in the same change:

- **Updating a skill's scope or description** — update the matching row in the
  `README.md` skills table so the description stays in sync.
- **Restructuring a skill's reference files** (`reference.md` ↔ `references/`) —
  update the repository structure block in `AGENTS.md` to match the new layout.
- **Adding or changing a hook** in `hooks/hooks.json` — update the **Hooks**
  section in `README.md` (and the `## Hooks` section in `CLAUDE.md` if behavior
  changes).
- **Adding or changing an MCP tool** — update the **MCP Integration** tools table
  in `README.md`.

## Commits

Use conventional commits: `type(scope): description`

Examples: `feat: add bloc skill`, `chore: add logo to README`
