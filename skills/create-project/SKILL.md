---
name: create-project
description: >
  Scaffold a new Dart or Flutter project from a Very Good CLI template, covering the
  flutter_app, dart_package, flutter_package, flutter_plugin, dart_cli, flame_game, and
  docs_site templates, inferring the right one from what the user wants to build and then
  installing dependencies. Use when the user says "create a new project", "start a new flutter
  app", "scaffold a package", "create a new package", "initialize a dart cli", "new flame
  game", or "generate a plugin". Use it for bare, vague, or under-specified scaffolding
  requests too — "create a new package for me", "make me a new app", "I need a new project",
  "set one up" — including ones that name no template, no project name, and no organization,
  or that only hint at what is being built. Missing or ambiguous details are a reason to use
  this skill, not a reason to skip it: it asks the clarifying questions and picks the
  template.
allowed-tools: mcp__very-good-cli__create mcp__very-good-cli__packages_get
argument-hint: "[template] [project-name]"
---

# Create Project

Scaffold a new Dart or Flutter project using Very Good CLI templates.

> **Cross-harness fallbacks.** This skill drives the Very Good CLI MCP server and asks the user structured questions. On a host without this plugin's Bash hooks and without that MCP server connected, run the equivalent `very_good create …` and `very_good packages get` commands directly. On a host without `AskUserQuestion`, invoke whatever equivalent user-question tool the host provides; if it has none, ask the same questions as plain numbered text.

---

## Core Standards

- **Use the Very Good CLI MCP server** to scaffold projects and install dependencies
- **Infer the template from context** — determine the right template based on what the user wants to build, not by asking them to pick a subcommand name
- **Use `AskUserQuestion` only for information you cannot infer** — project name and organization are the most common missing pieces
- **Install dependencies after creation**

---

## Workflow

### Step 1: Understand What the User Wants to Build

Infer the subcommand from the user's description — the available subcommands and their descriptions are defined by the Very Good CLI MCP server.

If the intent is ambiguous, use `AskUserQuestion` to clarify with a high-level question about what they're building — not which subcommand they want.

### Step 2: Gather Missing Parameters

Use `AskUserQuestion` to collect only what you cannot infer, batched into a single call. Optional parameters (description, output directory, application ID) are left at their defaults unless the user raises them.

### Step 3: Create and Set Up

1. Create the project using the Very Good CLI MCP server
2. Install dependencies using the Very Good CLI MCP server — pass `directory: '<path-to-created-project>'` to `packages_get` so it runs against the new project, not the workspace root

---

## Key Domain Knowledge

- Use `dart_package` (not `flutter_package`) for data layer and repository layer packages in the **layered-architecture** pattern — these must not depend on Flutter SDK
- If a user provides a project name with dashes, convert to underscores — Dart package names only allow lowercase letters, numbers, and underscores
- Templates that produce apps, plugins, or games require an organization name — do not skip this or it defaults to a placeholder value
- If `packages_get` fails after creation, check that `directory` points at the new project and that the Dart SDK is on `PATH`

---

## Anti-Patterns

| Anti-Pattern                                | Problem                                                            | Correct Approach                                          |
| ------------------------------------------- | ------------------------------------------------------------------ | --------------------------------------------------------- |
| Asking user to pick a template name         | Users think in terms of what they're building, not CLI subcommands | Infer the template from context                           |
| Over-asking for optional parameters         | Slows down the workflow                                            | Only ask for what you cannot infer                        |
| Using `flutter_package` for a data layer    | Adds unnecessary Flutter SDK dependency                            | Use `dart_package` for data and repository layer packages |
| Skipping organization name for apps/plugins | Defaults to a placeholder value                                    | Ask when the template requires it                         |
