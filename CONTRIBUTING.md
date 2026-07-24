# 🦄 Contributing to VGV AI Flutter Plugin

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Getting Started

1. **Fork** the repository and clone your fork locally.
2. Create a new branch from `main` for your work.
3. Open the project in your editor of choice — any text editor works.

## Types of Contributions

| Contribution | Where |
| ------------ | ----- |
| **New skill** | `skills/<skill-name>/SKILL.md` |
| **Improve an existing skill** | Edit the relevant `skills/*/SKILL.md` or `reference.md` |
| **Hooks** | `hooks/` directory |
| **Bug reports & feature requests** | [GitHub Issues](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues) |

## Adding a New Skill

### 1. Create the skill file

Create `skills/<skill-name>/SKILL.md`. The file must begin with YAML frontmatter:

```yaml
---
name: <skill-name>
description: When this skill should be triggered — be specific.
allowed-tools: Read,Glob,Grep
argument-hint: "[file-or-directory]"   # optional
---
```

| Field | Required | Rules |
| ----- | -------- | ----- |
| `name` | Yes | Must match the skill's folder name exactly; lowercase letters, numbers, and hyphens only |
| `description` | Yes | Describes when the skill should be triggered |
| `allowed-tools` | Yes | Comma-separated list of tools the skill may use |
| `argument-hint` | No | Placeholder hint shown to the user |

After the frontmatter, structure the file as:

1. **H1 title** — human-readable skill name
2. **Core Standards** — enforced constraints, always first
3. **Content sections** — architecture, code examples, workflows, anti-patterns

### 2. Update `plugin.json` tags

Add relevant keywords to the `keywords` array in `.claude-plugin/plugin.json`.

### 3. Update the README skills table

Add a row to the skills table in `README.md`. The skill name must link to the `SKILL.md` file:

```markdown
| [**Skill Name**](skills/<skill-name>/SKILL.md) | Short description of what the skill covers |
```

### 4. Update `CLAUDE.md` repository structure

Add the new skill directory and files to the repository structure tree in `CLAUDE.md`.

## Skill Writing Guidelines

- **Use clear directives** — no soft language ("consider", "prefer"). Say "Use X" or "Do not use Y".
- **Fence all code blocks** with language identifiers (e.g., ` ```dart `).
- **Provide complete, copy-pasteable snippets** — not fragments.
- **Reference packages by full name** (e.g., `package:mocktail`, not just "mocktail").
- **Show anti-patterns alongside correct patterns** when helpful, so readers understand both what to do and what to avoid.

## Cross-harness portability

Skills are authored for Claude Code but target the [Agent Skills open
standard](https://agentskills.io/specification) (the `npx skills` format, supported by
many agents). Under that standard a skill is a **static instruction set**: the agent loads
it by matching its `description`, then reads the body — there is no argument or template
substitution. `$ARGUMENTS` and `${CLAUDE_SKILL_DIR}` are Claude Code conveniences, not spec
features, so a body that uses them must still work when they arrive unsubstituted.

**`$ARGUMENTS`** — not a spec concept; on a plain Agent Skill it is never substituted and
stays literal. Always pair it with a fallback that fires when it is empty *or still shows
the literal text* `$ARGUMENTS`:

```markdown
<feature_description>$ARGUMENTS</feature_description>

**If the feature description above is empty or still shows the literal text
`$ARGUMENTS` (the host did not substitute it), ask the user** for it (or read it
from the conversation).
```

**`${CLAUDE_SKILL_DIR}`** — no skill here uses it today (the hooks use
`${CLAUDE_PLUGIN_ROOT}`, resolved by Claude Code, not by skill bodies). If a future skill
references a bundled file, prefer the spec form — a **relative path from the skill root**
(`scripts/x.sh`) — and add a fallback for hosts that do not substitute the absolute form.

**Frontmatter** — an agent silently skips a skill whose frontmatter is malformed. Keep the
opening `---` on line 1, close the block with `---`, and include a non-empty `name:`
(kebab-case, **matching the directory name**) and `description:`. The spec also allows
`license`, `compatibility`, `metadata`, and `allowed-tools`. This plugin's Claude Code
extras (`when_to_use`, `argument-hint`, `effort`, `model`) are not spec fields, but
`npx skills` and other agents ignore unknown frontmatter — keep them top-level so Claude
Code reads them and nothing else breaks. The `Skill validation` CI job
(`Flash-Brew-Digital/validate-skill@v1`) enforces the spec (including
name-matches-directory) across every skill on each pull request, and
`scripts/ci/check-frontmatter.sh` guards the gaps it leaves — a UTF-8 BOM (Gemini-fatal but
passes `validate-skill`) and `agents/**/*.md` frontmatter, which no other check covers.

**MCP references** — this plugin registers two MCP servers in `.mcp.json`: `dart` (Dart and
Flutter actions) and `very-good-cli` (scaffolding, tests, license checks). On Claude Code
they are the primary execution path, and the `check-vgv-cli.sh` / `block-cli-workarounds.sh`
hooks deliberately steer the quality gates through the MCP tools instead of the raw CLI — do
not weaken that on Claude Code. Those hooks do not run on other hosts and the MCP servers may
not be connected there, so every skill that drives an MCP tool must name the equivalent
`very_good` / `dart` / `flutter` CLI command as a fallback and never block when the server is
absent. The `dart-flutter-sdk-upgrade` and `very-good-analysis-upgrade` skills already phrase
this as "use the MCP tool if available; otherwise Bash" — match that.

**Subagents** — subagents are not part of the Agent Skills standard, and no skill in this
plugin dispatches one. The `flutter-reviewer` agent (`agents/flutter-reviewer.md`) is a
Claude Code construct; on a host without a subagent mechanism its four preloaded standards
(`bloc`, `testing`, `static-security`, `accessibility`) still apply — run the review inline
against those skills instead of dispatching the agent.

**`AskUserQuestion` and `allowed-tools`** — both are Claude Code conveniences. A skill that
asks the user a structured question or declares a narrow `allowed-tools` list carries the
cross-harness fallbacks in [`skills/shared/references/interaction-fallbacks.md`](skills/shared/references/interaction-fallbacks.md):
ask the same question as plain numbered text where `AskUserQuestion` is absent, and treat
`allowed-tools` as a permission hint rather than a hard cap.

**Shared content via symlinks** — references shared across skills live once under
`skills/shared/references/` and are symlinked into each consuming skill's `references/`
directory (for example `interaction-fallbacks.md`). `npx skills` dereferences symlinks when
it copies a cloned or local skill, so those install paths work as-is. Before relying on a
server-side snapshot install, verify with a real `npx skills add` that the shared files
arrive intact; if they do not, materialize them (dereference the symlinks into real files at
publish time, or vendor real copies).

## Testing Locally

Editing a skill or hook and pushing straight to a PR only tells you the files
are valid, not that they work correctly. Load your working copy into a real Claude Code
session and exercise it before you commit.

### Prerequisites

- **Claude Code CLI** installed (`npm install -g @anthropic-ai/claude-code`).
- **Dart SDK** and **jq** on your `PATH` — the hooks need both.
- **Very Good CLI** ≥ 1.3.0 (`dart pub global activate very_good_cli`) for the
  Very Good CLI MCP server tools.

See the README [Hooks](README.md#hooks) and [MCP Integration](README.md#mcp-integration)
sections for the full prerequisite details.

### Load your local copy

From the repository root, launch Claude Code pointed at this directory:

```bash
claude --plugin-dir .
```

`--plugin-dir` loads the plugin for that session only, needs no install or
marketplace, and overrides any marketplace-installed copy of the same plugin.
`${CLAUDE_PLUGIN_ROOT}` (used throughout `hooks/hooks.json`) resolves to the
directory you pass, so the hook script paths resolve correctly.

### Verify each component loaded

| Component | How to verify |
| ----------- | --------------- |
| **Skills** | Run `/help`. Skills appear namespaced as `/vgv-ai-flutter-plugin:<skill>` (e.g. `/vgv-ai-flutter-plugin:bloc`). Invoke one to confirm it triggers. |
| **MCP servers** | Run `/mcp`. Confirm `dart` and `very-good-cli` both show connected. |
| **Hooks** | Have Claude `Edit` or `Write` a `.dart` file and confirm `analyze.sh` and `format.sh` run. Launch without Very Good CLI to see the SessionStart warning fire. |

### Iterate on changes

After editing a `SKILL.md`, a hook script, or `.mcp.json`, **restart the
`claude --plugin-dir .` session** to guarantee the change is picked up. Changes
to `.claude-plugin/plugin.json` always require a restart. Edits to the hook
`.sh` scripts take effect on the next matching tool call with no restart, since
each hook runs the script fresh.

### Rehearse the real install (optional)

To mimic the marketplace install flow without pushing anything, register a
throwaway local marketplace. Create `.claude-plugin/marketplace.json` in a temp
directory with an **absolute** path to this repo:

```jsonc
// /tmp/vgv-test-marketplace/.claude-plugin/marketplace.json
{
  "plugins": [
    {
      "name": "vgv-ai-flutter-plugin",
      "source": {
        "type": "directory",
        "path": "/ABSOLUTE/path/to/vgv-ai-flutter-plugin"
      }
    }
  ]
}
```

Then, inside a session:

```text
/plugin marketplace add /tmp/vgv-test-marketplace
/plugin install vgv-ai-flutter-plugin
```

### Validate before you push

Run the same checks CI runs, from the repository root:

```bash
claude plugin validate .
```

```bash
bash scripts/ci/check-frontmatter.sh
```

The first validates the manifest, skill frontmatter, hook JSON, MCP config, and file
references. The second is the frontmatter guard (UTF-8 BOM detection plus `agents/**/*.md`
frontmatter). Both are static, so they confirm structure but do not replace the live checks
above.

### Troubleshooting

| Symptom | Likely cause | Fix |
| --------------------------------------- | ------------------------------------------- | ------------------------------------------------------------- |
| Skill missing from `/help` | Invalid frontmatter, or `name` doesn't match the folder | Run `claude plugin validate .` and fix the reported error |
| MCP server "executable not found" | `dart` or `very_good` not on `PATH` | Install the SDK / activate the CLI, then verify with `which` |
| Hook never fires | `jq` not installed, or script lacks `+x` / a shebang | Install `jq`; `chmod +x` the script and add `#!/bin/bash` |
| `${CLAUDE_PLUGIN_ROOT}` not resolving | Session not launched via `--plugin-dir` (or restart pending) | Restart with `claude --plugin-dir .` from the repo root |
| Local marketplace won't install | `source.path` is relative | Use an absolute path in `marketplace.json` |

## CI Checks

Every pull request runs the following checks automatically:

| Check | What it does | Config |
| ----- | ------------ | ------ |
| Markdown lint | Lints all `*.md` files (except `CHANGELOG.md`) | `config/custom.markdownlint.jsonc` |
| Spelling | Runs cspell on all `*.md` files | `config/cspell.json` |
| Skill validation | Validates **every** `SKILL.md`'s frontmatter and structure against the Agent Skills spec, so a malformed skill fails the build instead of silently vanishing on another host | `Flash-Brew-Digital/validate-skill@v1` |
| Frontmatter guard | Fails on a UTF-8 BOM in any `SKILL.md` or agent file (Gemini-fatal, passes validate-skill) and validates `agents/**/*.md` frontmatter, which no other check covers | `scripts/ci/check-frontmatter.sh` |
| Plugin validation | Validates the plugin manifests via the Claude Code CLI | `claude plugin validate .` |
| Script tests | Runs the hook script unit tests | `hooks/scripts/*_test.sh` |

If the spelling check flags a legitimate word, add it to `config/cspell.json` in the `words` array.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) with the format:

```text
type(scope): description
```

| Type | When to use | Example |
| ---- | ----------- | ------- |
| `feat` | New skill or feature | `feat: add bloc skill` |
| `fix` | Fix an error or incorrect guidance | `fix: correct GoRouter redirect example` |
| `docs` | Documentation-only change | `docs: add logo to README` |
| `chore` | Maintenance, CI, tooling | `chore: update cspell config` |
| `refactor` | Restructure without changing behavior | `refactor: reorganize testing skill sections` |
| `ci` | CI pipeline changes | `ci: add manifest validation step` |

## Pull Requests

- Branch from `main`.
- Keep PRs focused — **one skill per PR** for new skills.
- Fill out the [PR template](.github/PULL_REQUEST_TEMPLATE.md) completely.
- Ensure all CI checks pass before requesting review.
- Link any related issues in the PR description.
