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
| [**Create Project**](skills/create-project/SKILL.md) | Scaffold new Dart/Flutter projects from Very Good CLI templates — `flutter_app`, `dart_package`, `flutter_plugin`, `dart_cli`, `flame_game`, and more |
| [**Animations**](skills/animations/SKILL.md) | Flutter built-in animations — implicit vs explicit decision tree, Material 3 motion tokens (`Durations`, `Easing`), page transitions with GoRouter, Hero animations, staggered animations, and performance guidelines |
| [**Accessibility**](skills/accessibility/SKILL.md) | WCAG 2.2 compliance with A/AA/AAA conformance level selection across iOS, Android, Web, macOS, Windows, and Linux — semantics, screen reader support, touch targets, focus management, color contrast, text scaling, and motion sensitivity |
| [**Testing**](skills/testing/SKILL.md) | Unit, widget, and golden testing — `mocktail` mocking, `pumpApp` helpers, test structure & naming, coverage patterns, and `dart_test.yaml` configuration |
| [**Navigation**](skills/navigation/SKILL.md) | GoRouter routing — `@TypedGoRoute` type-safe routes, deep linking, redirects, shell routes, and widget testing with `MockGoRouter` |
| [**Internationalization**](skills/internationalization/SKILL.md) | i18n/l10n — ARB files, `context.l10n` patterns, pluralization, RTL/LTR support with directional widgets, and backend localization strategies |
| [**Material Theming**](skills/material-theming/SKILL.md) | Material 3 theming — `ColorScheme`, `TextTheme`, component themes, spacing systems, and light/dark mode support |
| [**Bloc**](skills/bloc/SKILL.md) | State management with Bloc/Cubit — sealed events & states, `BlocProvider`/`BlocBuilder` widgets, event transformers, and testing with `blocTest()` & `mocktail` |
| [**Layered Architecture**](skills/layered-architecture/SKILL.md) | VGV layered architecture — four-layer package structure (Data, Repository, Business Logic, Presentation), dependency rules, data flow, and bootstrap wiring |
| [**Security**](skills/static-security/SKILL.md) | Flutter-specific static security review — secrets management, `flutter_secure_storage`, certificate pinning, `Random.secure()`, `formz` validation, dependency vulnerability scanning with `osv-scanner`, and OWASP Mobile Top 10 guidance |
| [**UI Package**](skills/ui-package/SKILL.md) | Flutter UI package creation — custom widget libraries with `ThemeExtension`-based theming, design tokens, barrel file exports, widget tests, Widgetbook catalog, and consistent API conventions |
| [**License Compliance**](skills/license-compliance/SKILL.md) | Dependency license auditing — categorizes licenses (permissive, weak/strong copyleft, unknown), flags non-compliant or missing licenses, and produces a structured compliance report using Very Good CLI |
| [**Dart/Flutter SDK Upgrade**](skills/dart-flutter-sdk-upgrade/SKILL.md) | Bump Dart and Flutter SDK constraints across packages — CI workflow versions, pubspec.yaml environment constraints, and PR preparation for SDK upgrades |
| [**Very Good Analysis Upgrade**](skills/very-good-analysis-upgrade/SKILL.md) | Upgrade the `very_good_analysis` lint package across Dart/Flutter projects — version bump in `pubspec.yaml`, minimal lint fixes for new rules, and PR preparation |

## Hooks

This plugin includes SessionStart, PreToolUse, and PostToolUse hooks that validate the Very Good CLI, guard against CLI bypass, and automatically run Dart analysis and formatting on `.dart` files.

| Hook | Trigger | Behavior |
| ---- | ------- | -------- |
| **Warn Missing MCP** (`warn-missing-mcp.sh`) | SessionStart | Warns if the Very Good CLI is missing or older than 1.3.0; non-blocking |
| **Check VGV CLI** (`check-vgv-cli.sh`) | PreToolUse (`mcp__very-good-cli__.*`) | Validates the Very Good CLI is installed and ≥ 1.3.0; exits 2 on failure (blocking) |
| **Block CLI Workarounds** (`block-cli-workarounds.sh`) | PreToolUse (`Bash`) | Blocks direct CLI bypass of Very Good CLI commands through the Bash tool; exits 2 on failure (blocking). The redirect targets the Very Good CLI MCP tools, which must be allowlisted — see [Allowlisting the MCP tools](#very-good-cli-mcp-server-very-good-cli) |
| **Analyze** (`analyze.sh`) | PostToolUse (`Edit`/`Write`) | Runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix issues before continuing) |
| **Format** (`format.sh`) | PostToolUse (`Edit`/`Write`) | Runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking — formatting is applied silently) |

### Prerequisites

- **Dart SDK** — must be available on your `PATH`
- **jq** — used to parse the hook payload; hooks are skipped gracefully if `jq` is not installed

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
| Test execution | Run tests and analyze the results |
| Code formatting | Format code using the same formatter and config as `dart format` |

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

**Allowlisting the MCP tools:**

The **Block CLI Workarounds** hook redirects shell commands like `very_good create` to these MCP tools, so the tools must be reachable. With `"skipAutoPermissionPrompt": true` in your settings, a non-allowlisted MCP tool fails silently — no approval dialog, no actionable error — and scaffolding dead-ends with nothing explaining why.

To avoid this, allowlist the tools in `.claude/settings.local.json`:

```json
"permissions": {
  "allow": [
    "mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__create",
    "mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__test",
    "mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__packages_get",
    "mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__packages_check_licenses"
  ]
}
```

Alternatively, run `/permissions` to grant the tools interactively when prompted.

**How it works:**

The `.mcp.json` file at the project root registers the `dart` and `very-good-cli` MCP servers using stdio transport. When Claude Code detects this configuration, it connects to both servers and gains access to the tools above. The skills continue to provide knowledge and best practices while the MCP tools handle execution.

[marketplace_link]: https://github.com/VeryGoodOpenSource/very-good-claude-code-marketplace
[claude_code_link]: https://claude.ai/code
[vgv_link]: https://verygood.ventures
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
