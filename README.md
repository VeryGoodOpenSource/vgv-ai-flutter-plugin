# VGV AI Flutter Plugin

[![Very Good Ventures][logo_white]][very_good_ventures_link_dark]
[![Very Good Ventures][logo_black]][very_good_ventures_link_light]

A [Claude Code][claude_code_link] plugin that accelerates Flutter & Dart development with best-practices skills from [Very Good Ventures][vgv_link].

Developed with 💙 by [Very Good Ventures][vgv_link] 🦄

## Overview

VGV AI Flutter Plugin is a collection of contextual best-practices skills that Claude uses when helping you write Flutter and Dart code. Each skill provides opinionated, production-quality guidance covering architecture patterns, naming conventions, folder structures, code examples, testing strategies, and anti-patterns to avoid, so you get code that follows [VGV standards][vgv_link] out of the box.

## Installation

One-line install from your terminal:

```bash
claude plugin marketplace add VeryGoodOpenSource/very-good-claude-code-marketplace && claude plugin install vgv-ai-flutter-plugin
```

Or inside an active Claude Code session, run these as **two separate commands** (the second only after the first completes):

1. Add the marketplace:

   ```text
   /plugin marketplace add VeryGoodOpenSource/very-good-claude-code-marketplace
   ```

2. Install the plugin:

   ```text
   /plugin install vgv-ai-flutter-plugin
   ```

For more details, see the [Very Good Claude Marketplace][marketplace_link].

## Skills

| Skill | Description |
| ----- | ----------- |
| [**Create Project**](skills/create-project/SKILL.md) | Scaffold new Dart/Flutter projects from Very Good CLI templates — `flutter_app`, `dart_package`, `flutter_plugin`, `dart_cli`, `flame_game`, and more — including vague requests where the template, name, or organization is still missing |
| [**Animations**](skills/animations/SKILL.md) | Flutter built-in animations — implicit vs explicit decision tree, Material 3 motion tokens (`Durations`, `Easing`), page transitions with GoRouter, Hero animations, staggered animations, and performance guidelines |
| [**Accessibility**](skills/accessibility/SKILL.md) | WCAG 2.2 compliance with A/AA/AAA conformance level selection across iOS, Android, Web, macOS, Windows, and Linux — semantics, screen reader support, touch targets, focus management, color contrast, text scaling, and motion sensitivity |
| [**Testing**](skills/testing/SKILL.md) | Unit, widget, and golden/snapshot testing — `mocktail` mocking (never `mockito`), `pumpApp` helpers, `TestTag` golden tagging, test structure & naming, coverage patterns, and `dart_test.yaml` configuration. Also covers one-line golden-test requests and asks for the patterns it forbids |
| [**Navigation**](skills/navigation/SKILL.md) | GoRouter routing — `@TypedGoRoute` type-safe routes, deep linking, redirects, shell routes, `go()` vs `push()` call sites, and widget testing with `MockGoRouter` |
| [**Internationalization**](skills/internationalization/SKILL.md) | i18n/l10n — ARB files, `context.l10n` patterns, pluralization, RTL/LTR support with directional widgets for Arabic and Hebrew, staying on `flutter_localizations` instead of third-party i18n packages, and backend localization strategies |
| [**Material Theming**](skills/material-theming/SKILL.md) | Material 3 theming — `ColorScheme`, `TextTheme`, component themes, spacing systems, light/dark mode support, and refactoring hardcoded or duplicated styling out of widget code |
| [**Bloc**](skills/bloc/SKILL.md) | State management with Bloc/Cubit — sealed events & states, `BlocProvider`/`BlocBuilder` widgets, event transformers, and testing with `blocTest()` & `mocktail` |
| [**Layered Architecture**](skills/layered-architecture/SKILL.md) | VGV layered architecture — four-layer package structure (Data, Repository, Business Logic, Presentation), laying out a new app's packages from a one-line description, dependency rules, where a model or file belongs and why a domain model cannot live in a data package, data flow, and bootstrap wiring |
| [**Security**](skills/static-security/SKILL.md) | Flutter-specific static security review — secrets management (rejects `--dart-define`, `String.fromEnvironment`, `.env`, and CI-injected keys as fixes), `flutter_secure_storage`, certificate pinning, `Random.secure()`, `formz` validation, dependency vulnerability scanning with `osv-scanner`, and OWASP Mobile Top 10 guidance |
| [**UI Package**](skills/ui-package/SKILL.md) | Flutter UI package creation — custom widget libraries with `ThemeExtension`-based theming, design tokens, a barrel-only public API consumers import instead of reaching into `lib/src/`, `pumpApp`-based widget tests, Widgetbook catalog, and consistent API conventions |
| [**License Compliance**](skills/license-compliance/SKILL.md) | Dependency license auditing — categorizes licenses (permissive, weak/strong copyleft, unknown), flags non-compliant or missing licenses, and produces a structured compliance report using Very Good CLI |
| [**Dart/Flutter SDK Upgrade**](skills/dart-flutter-sdk-upgrade/SKILL.md) | Bump Dart and Flutter SDK constraints across packages — CI workflow versions, pubspec.yaml environment constraints, and PR preparation for SDK upgrades |
| [**Very Good Analysis Upgrade**](skills/very-good-analysis-upgrade/SKILL.md) | Upgrade the `very_good_analysis` lint package across Dart/Flutter projects — version bump in `pubspec.yaml`, minimal lint fixes for new rules, and PR preparation |
| [**Green Gate**](skills/green-gate/SKILL.md) | Autonomous verify-fix-rerun loop that drives a package to green across four quality gates — analyze, format, test, and coverage — exiting only when a final iteration proves all four pass with observed numbers (default 100% coverage, overridable). Also answers how the gates are configured — tool per gate, arguments, order, coverage target and exclusions — and holds the line when asked to weaken one: no lowered threshold, no coverage ignore on reachable code, no skipping a gate that passed earlier |

## Agents

This plugin ships subagents that Claude Code can dispatch as isolated, specialized reviewers. Unlike skills, agents are **not** invoked as slash commands — Claude dispatches them automatically, or you can ask Claude to run one by name (e.g. "review my changes with the flutter-reviewer agent").

| Agent | Description |
| ----- | ----------- |
| [**Flutter Reviewer**](agents/flutter-reviewer.md) | Read-only reviewer of changed Dart code against the preloaded `bloc`, `testing`, `static-security`, and `accessibility` standards — emits a `location \| problem \| fix \| standard` findings table. Never edits files; Bash is hook-restricted to `git diff`/`git status` |

## Hooks

This plugin includes SessionStart, PreToolUse, and PostToolUse hooks that validate the Very Good CLI, guard against CLI bypass, and automatically run Dart analysis and formatting on `.dart` files.

| Hook | Trigger | Behavior |
| ---- | ------- | -------- |
| **Warn Missing MCP** (`warn-missing-mcp.sh`) | SessionStart | Warns if the Very Good CLI is missing or older than 1.3.0; non-blocking |
| **Check VGV CLI** (`check-vgv-cli.sh`) | PreToolUse (`mcp__.*very-good-cli__.*`) | Verifies from the payload that the caller is a Very Good CLI tool and stands aside otherwise, so the decision never lands on an unrelated tool; for its own tools, auto-approves the call in every run mode via a PreToolUse `allow` decision, so they never dead-end when the tool isn't on `permissions.allow` (including under `skipAutoPermissionPrompt`); denies with an install/upgrade message if the CLI is missing or < 1.3.0 |
| **Block CLI Workarounds** (`block-cli-workarounds.sh`) | PreToolUse (`Bash`) | Blocks direct CLI bypass of Very Good CLI commands through the host's shell tool; inspects the command only when the payload identifies a shell call, so an unrelated tool carrying a `command` argument is left alone; exits 2 on failure (blocking) |
| **Allow Read-only Git** (`allow-readonly-git.sh`) | PreToolUse (`Bash`, `flutter-reviewer` agent only) | Restricts the `flutter-reviewer` agent's Bash to `git diff`/`git status`; exits 2 on anything else (blocking). Scoped via the agent's frontmatter, not `hooks.json` |
| **Analyze** (`analyze.sh`) | PostToolUse (`Edit`/`Write`) | Runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix issues before continuing) |
| **Format** (`format.sh`) | PostToolUse (`Edit`/`Write`) | Runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking — formatting is applied silently) |

### Prerequisites

- **Dart SDK** — must be available on your `PATH`
- **jq** — used to parse the hook payload; hooks are skipped gracefully if `jq` is not installed

The Very Good CLI is resolved from `PATH`, falling back to `$PUB_CACHE/bin` (default
`~/.pub-cache/bin`) for hosts that launch hooks without an interactive shell's `PATH`. The
installed `very_good` is a shim that execs `dart`, so when the binary is found but its version
cannot be read the check is reported as inconclusive and the hook stands aside rather than
reporting the CLI as missing.

## Evals

Skill evals ask whether Claude routes to a skill and follows it. [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) runs each case with this plugin loaded and again with no plugin at all, so a grader that passes in both arms is measuring the model rather than the skill. Runs authenticate the same way your normal Claude Code sessions do, so they need no API key locally.

```bash
claude plugin eval . --scaffold
```

Run them locally before opening a PR that changes a skill. CI also runs them **after** a merge to `main`, scoped to the skills that changed, as an advisory signal rather than a gate — see [evals/README.md](evals/README.md#running-in-ci).

See [evals/README.md](evals/README.md) for the case format, the grader reference, prerequisites, and what these evals deliberately do not cover.

## Usage

Skills activate automatically when Claude detects relevant context in your conversation. Simply ask Claude to help with a Flutter or Dart task, and the appropriate skill's guidance will be applied.

For example:

> **You:** Create a new Bloc for user authentication with login and logout events.
>
> **Claude:** _(applies the Bloc skill — uses sealed classes for events and states, follows the Page/View separation pattern, generates `blocTest()` tests with `mocktail` mocks, and follows VGV naming conventions)_

You can also invoke skills directly as slash commands:

```bash
/create-project
/animations
/accessibility
/bloc
/internationalization
/layered-architecture
/material-theming
/navigation
/static-security
/testing
/ui-package
/license-compliance
/dart-flutter-sdk-upgrade
/very-good-analysis-upgrade
/green-gate
```

## What Each Skill Provides

Every skill includes:

- **Core Standards** — recommended conventions (e.g., `mocktail` over `mockito`, sealed classes for Bloc events)
- **Architecture patterns** — folder structures and layered architecture guidance
- **Code examples** — ready-to-adapt snippets following best practices
- **Testing strategies** — unit, widget, and integration testing patterns
- **Common workflows** — step-by-step guides for tasks like "adding a new feature" or "adding a new route"
- **Anti-patterns** — what to avoid and why

## MCP Integration

This plugin includes a `.mcp.json` configuration that connects Claude Code to two MCP servers — the **Dart and Flutter MCP server** (`dart mcp-server`) and the **Very Good CLI MCP server** (`very_good mcp`). This gives Claude the ability to execute Dart, Flutter, and Very Good CLI actions directly, complementing the skills which provide architectural guidance and best practices.

### Dart and Flutter MCP server (`dart`)

The Dart and Flutter MCP server ships with the Dart SDK and exposes core Dart/Flutter development actions to Claude.

**Available MCP tools:**

| Tool | What it does |
| ---- | ------------ |
| Error analysis & fixing | Analyze the project for static errors and apply fixes |
| Symbol resolution | Resolve symbols to elements and fetch documentation and signature information |
| App introspection | Introspect and interact with a running Dart or Flutter application |
| Package search | Search pub.dev for packages that fit a given use case |
| Dependency management | Add, remove, and update dependencies in `pubspec.yaml` files |
| Package source exploration | Resolve `package:` URIs and search dependency sources |
| Code formatting (`dart_format`) | Format code using the same formatter and config as `dart format` |

The server's `cli` feature category — `dart_format`, `dart_fix`, `create_project`,
`run_tests`, and `list_devices` — is **off by default**, so a bare `dart mcp-server`
advertises 13 tools with no formatter. `.mcp.json` therefore starts it as
`dart mcp-server --enable dart_format`. The `green-gate` skill's format gate calls that
tool; drop the flag and the gate has nothing to call. Test execution is deliberately
left disabled — the `test` tool from the Very Good CLI MCP server is used instead.

**Prerequisites:**

- Dart SDK installed with `dart` on your PATH (the MCP server is provided by `dart mcp-server`)

### Very Good CLI MCP server (`very-good-cli`)

The Very Good CLI MCP server exposes Very Good CLI commands to Claude.

**Available MCP tools:**

| Tool | What it does |
| ---- | ------------ |
| `create` | Scaffold projects from templates (`flutter_app`, `dart_cli`, `dart_package`, `flutter_package`, `flutter_plugin`, `flame_game`, `docs_site`) |
| `test` | Run tests with coverage enforcement |
| `packages_check_licenses` | Audit dependency licenses against an allowed list |
| `packages_get` | Get dependencies for a single package or recursively across a monorepo |

**Prerequisites:**

- Very Good CLI v1.3.0+ installed: `dart pub global activate very_good_cli`
- `very_good` must be on your PATH

**How it works:**

The `.mcp.json` file at the project root registers the `dart` and `very-good-cli` MCP servers using stdio transport. When Claude Code detects this configuration, it connects to both servers and gains access to the tools above. The skills continue to provide knowledge and best practices while the MCP tools handle execution.

[marketplace_link]: https://github.com/VeryGoodOpenSource/very-good-claude-code-marketplace
[claude_code_link]: https://claude.ai/code
[vgv_link]: https://verygood.ventures
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
