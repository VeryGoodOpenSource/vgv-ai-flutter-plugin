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
name: vgv-<skill-name>
description: When this skill should be triggered — be specific.
allowed-tools: Read,Glob,Grep
argument-hint: "[file-or-directory]"   # optional
---
```

| Field | Required | Rules |
| ----- | -------- | ----- |
| `name` | Yes | Prefixed with `vgv-`, lowercase letters, numbers, and hyphens only |
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

## CI Checks

Every pull request runs the following checks automatically:

| Check | What it does | Config |
| ----- | ------------ | ------ |
| Spelling | Runs cspell on all `*.md` files | `config/cspell.json` |
| File size | Ensures no file exceeds 50 KB | `scripts/check_large_files.sh` |
| Skill validation | Validates `SKILL.md` frontmatter and structure | `scripts/validate_skills.sh` |
| Plugin validation | Validates and test-installs the plugin | `claude plugin validate .` |

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
