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

### 5. Publish it to the website (optional)

To surface the skill on [engineering.verygood.ventures](https://engineering.verygood.ventures), add a `web:` block to the skill's frontmatter, then regenerate the site pages:

```yaml
web:
  section: best-practices   # or "tooling"
  title: My Skill           # optional
  order: 11                 # optional
```

```bash
cd website
npm ci            # first time only
npm run gen:docs  # regenerate pages from skills
```

Commit the regenerated files under `website/src/content/docs/{best-practices,tooling}/` and `website/src/generated/`. **Never edit those files by hand** — CI fails if they are out of sync with the skills. See the **Website** section of `CLAUDE.md`.

## Skill Writing Guidelines

- **Use clear directives** — no soft language ("consider", "prefer"). Say "Use X" or "Do not use Y".
- **Fence all code blocks** with language identifiers (e.g., ` ```dart `).
- **Provide complete, copy-pasteable snippets** — not fragments.
- **Reference packages by full name** (e.g., `package:mocktail`, not just "mocktail").
- **Show anti-patterns alongside correct patterns** when helpful, so readers understand both what to do and what to avoid.

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

Run the same check CI runs, from the repository root:

```bash
claude plugin validate .
```

This validates the manifest, skill frontmatter, hook JSON, MCP config, and file
references. It is static, so it confirms structure but does not replace the live
checks above.

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
| Spelling | Runs cspell on all `*.md` files | `config/cspell.json` |
| File size | Ensures no file exceeds 50 KB | `scripts/check_large_files.sh` |
| Skill validation | Validates `SKILL.md` frontmatter and structure | `scripts/validate_skills.sh` |
| Plugin validation | Validates and test-installs the plugin | `claude plugin validate .` |
| Website | Regenerates docs from skills, fails on drift, then builds the site | `website/` (`ci.yaml` → `site` job) |

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
