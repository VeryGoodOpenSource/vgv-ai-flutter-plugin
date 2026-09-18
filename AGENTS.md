# VGV AI Flutter Plugin

## Project Overview

VGV AI Flutter Plugin provides best-practices skills for Flutter and Dart development. It is a **documentation-only repository** — there is no Dart/Flutter source code, no `pubspec.yaml`, and no tests. All value lives in the markdown skill files.

## Repository Structure

```text
.mcp.json                # MCP server configuration (Dart and Very Good CLI)
skills_lint.yaml         # skills_lint rule severities, read by the CI Skills Lint job
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, keywords)
agents/
  flutter-reviewer.md  # Read-only Flutter code reviewer subagent
docs/                  # Gitignored, local only
  plan/                # Planning and design documents
evals/                 # `claude plugin eval` suite — all 15 skills, 100 cases
  README.md            # Case format, grader reference, how to add a case
  BASELINE.md          # Last full two-arm measurement: per-skill Δ and routing
  _fixture/
    fixture.sh         # The only copy of the neutral Flutter skeleton; every case symlinks here
  <skill>/             # One directory per skill, named for the skill it covers
    NOTES.md           # What each case discriminates and why it exists
    <case-name>/       # One directory per case, named for the case
      prompt.md        # Frontmatter: run limits and tools. Body: the prompt
      case.yaml        # schema_version, name, and the scaffold hook
      fixture.sh       # Symlink to _fixture/fixture.sh
      graders/
        <name>.md      # One grader per file; frontmatter is its type and options
  results/             # Written by each run — gitignored
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
skills/                  # every <skill>/ ships SKILL.md + agents/openai.yaml (Codex sidecar)
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
   - `model` _(optional)_ — model to use **while the skill is active**. The override applies for
     the rest of the current turn and is not saved to settings, so a user on Opus who triggers a
     skill pinned to `sonnet` stays on sonnet until their next prompt. Nine skills here set it.
     Note the eval consequence: `create-project` pins `haiku`, so in a two-arm run its with-plugin
     arm answers on a weaker model than the no-plugin arm, which understates its measured lift.
     Routing is decided before the switch, so a pin never explains a routing miss
   - `effort` _(optional)_ — reasoning effort while the skill is active (`low`/`medium`/`high`/
     `xhigh`/`max`), overriding the session level for that turn. Seven skills here set it
2. **H1 title** — human-readable skill name
3. **Core Standards** — enforced constraints, always first
4. **Content sections** — architecture, code examples, workflows, anti-patterns

Every skill also ships a Codex sidecar at `agents/openai.yaml` beside its `SKILL.md`, holding the skill-picker metadata `interface.display_name` and `interface.short_description`. Every skill in this plugin is **model-invoked** (the model may auto-activate it), so no skill sets `disable-model-invocation` or a Codex `policy` block; a user-invoked-only skill would set both, kept in sync. See `CONTRIBUTING.md` → Cross-harness portability.

## Writing Conventions

- Frame standards as clear directives — no soft language ("consider", "prefer")
- Use fenced code blocks with language identifiers for all examples
- Provide complete, copy-pasteable snippets, not fragments
- Reference packages by full name (e.g., `package:mocktail`)
- Include anti-patterns alongside correct patterns when helpful
- Align pipe characters vertically in all markdown tables (enforced by markdownlint MD060)

## Adding a New Skill

1. Create `skills/<skill_name>/SKILL.md` following the format above, plus the Codex sidecar
   `skills/<skill_name>/agents/openai.yaml` (`interface.display_name` + `interface.short_description`)
2. Create `evals/<skill_name>/<case_name>/` — one case directory per major workflow
   the skill covers, each with a routing grader, plus one negative-control case. Routing
   graders carry `weight: 3` **and** `arm: both`; without `arm: both` the runner drops
   them from the score in a two-arm run and a routing failure scores 1.00. Nothing has to
   be registered, and the fixture symlink is the only setup step. See `evals/README.md`
3. Update `keywords` **and** the `description` (marketplace text) in `.claude-plugin/plugin.json`
4. Update the skills table in `README.md` (skill name must link to the `SKILL.md` file)
5. Add the skill's slash command (e.g., `/<skill-name>`) to the **Usage** list in `README.md`
6. Add any new domain terms to the `words` list in `config/cspell.json`
7. Update the repository structure in `AGENTS.md`

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
  `README.md` skills table and the `interface.short_description` in the skill's
  `agents/openai.yaml`, so all three stay in sync. Nothing checks them against
  each other. `description` also carries every trigger phrase and is capped at
  1024 characters, which `skills_lint` enforces as an error. Several are already
  within ten characters of it, so check the current length before adding a
  trigger phrase. Keep it to
  triggers and scope, leaving pure teaching material to the body. Do not cut a
  sentence just because the body repeats it — routing happens before the body
  loads — and re-run the skill's eval cases after any trim.
- **Changing what a skill teaches** — run the skill's eval cases to confirm the new
  guidance actually lands in the model's output, and update any case that asserted
  the old behavior. A failing case after a deliberate change means the case needs
  updating; a failing case after a Claude Code or MCP server change means the skill
  does.
- **Restructuring a skill's reference files** (`reference.md` ↔ `references/`) —
  update the repository structure block in `AGENTS.md` to match the new layout, and
  update every markdown link pointing at the moved file. CI catches a link that points
  at a file that no longer exists (`check-relative-paths` in `skills_lint.yaml`), but it
  cannot tell you a link now points at the wrong file, so still read each one.
- **Adding or changing a hook** in `hooks/hooks.json` — update the **Hooks**
  section in `README.md` (and the `## Hooks` section in `CLAUDE.md` if behavior
  changes).
- **Adding or changing an MCP tool** — update the **MCP Integration** tools table
  in `README.md`, and check whether any skill's `allowed-tools` names a tool that
  was renamed or removed. Nothing validates those names.

## Evals

Evals ask whether Claude routes to a skill and follows it. `evals/README.md` is the
single source of truth for the case format, the grader reference, prerequisites,
and what makes a case worth having — read it before writing a case, and put new eval
documentation there rather than here.

[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals), cases under
`evals/<skill>/<case>/`. Run with `claude plugin eval . --scaffold`. Needs Claude Code
>= 2.1.269 and uses the local session, so no API key. Read the two arm scores, not the
total: the no-plugin arm is supposed to fail.

`--scaffold` is not optional. Every run starts in an empty workspace, and without the
flag the fixture script is skipped silently and cases fail for reasons unrelated to the
skill.

Run them by hand before opening a PR. They do **not** run on a pull request, because they
call real models; `.github/workflows/evals.yaml` runs them after a merge to `main`, scoped
by `--tag` to the changed skills, with-plugin arm only, and always non-blocking. A full
run is manual (`workflow_dispatch`) and is the expensive one.

Isolation is structural rather than configured: each run gets a throwaway home,
workspace and configuration, and the eval directory is unreadable from inside a run.
Nothing about the fixture or the tool grants can leak skill content into the no-plugin
arm the way the previous harness could.

## Commits

Use conventional commits: `type(scope): description`

Examples: `feat: add bloc skill`, `chore: add logo to README`
