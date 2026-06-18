---
name: create-project
description: Scaffold a new Dart or Flutter project from a Very Good CLI template. Supports flutter_app, dart_package, flutter_package, flutter_plugin, dart_cli, flame_game, and docs_site templates.
when_to_use: Use when user says "create a new project", "start a new flutter app", "scaffold a package", "initialize a dart cli", "new flame game", or "generate a plugin".
allowed-tools: mcp__very-good-cli__create mcp__very-good-cli__packages_get
argument-hint: "[template] [project-name]"
model: haiku
---

# Create Project

Scaffold a new Dart or Flutter project using Very Good CLI templates.

---

## Core Standards

- **Use the Very Good CLI MCP server** to scaffold projects and install dependencies
- **Infer the template from context** — determine the right template based on what the user wants to build, not by asking them to pick a subcommand name
- **Use `AskUserQuestion` only for information you cannot infer** — project name and organization are the most common missing pieces
- **Install dependencies after creation**

---

## Workflow

### Step 1: Understand What the User Wants to Build

Infer the subcommand from the user's description — the available subcommands and their descriptions are defined by the Very Good CLI MCP server. Do NOT ask users to pick a subcommand name — figure it out from context.

If the intent is ambiguous, use `AskUserQuestion` to clarify with a high-level question about what they're building — not which subcommand they want.

### Step 2: Gather Missing Parameters

Use `AskUserQuestion` to collect only what you cannot infer. Batch questions into a single call when possible. Do NOT ask for optional parameters (description, output directory, application ID, etc.) unless the user brings them up.

### Step 3: Create and Set Up

1. Create the project using the Very Good CLI MCP server
2. Install dependencies using the Very Good CLI MCP server — pass `directory: '<path-to-created-project>'` to `packages_get` so it runs against the new project, not the workspace root

---

## Key Domain Knowledge

- Use `dart_package` (not `flutter_package`) for data layer and repository layer packages in the **layered-architecture** pattern — these must not depend on Flutter SDK
- If a user provides a project name with dashes, convert to underscores — Dart package names only allow lowercase letters, numbers, and underscores
- Templates that produce apps, plugins, or games require an organization name — do not skip this or it defaults to a placeholder value

---

## Examples

### User says "Create a new Flutter app"

1. Infer: `flutter_app`
2. Ask for project name and organization
3. Create and install dependencies

### User says "I need a package for my weather API client, put it in packages/"

1. Infer: "API client" → pure Dart → `dart_package`, name `weather_api_client`, output `packages/`
2. Everything is clear — no questions needed
3. Create and install dependencies

### User says "I want to build something for iOS and Android with bluetooth"

1. Ambiguous: app or plugin? Ask to clarify
2. Gather remaining parameters based on answer
3. Create and install dependencies

### User says "Create a new package"

1. Ambiguous: Flutter or pure Dart? Ask to clarify
2. Ask for project name
3. Create and install dependencies

---

## Troubleshooting

### Invalid project name error

- Names must be valid Dart package names: lowercase letters, numbers, underscores only
- Dashes are not allowed — convert `my-app` to `my_app`

### Dependencies fail to install after creation

- Verify the Dart SDK is installed and on PATH
- Pass `directory: '<path-to-created-project>'` to `packages_get` so it targets the new project

---

## Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
| --- | --- | --- |
| Asking user to pick a template name | Users think in terms of what they're building, not CLI subcommands | Infer the template from context |
| Over-asking for optional parameters | Slows down the workflow | Only ask for what you cannot infer |
| Using `flutter_package` for a data layer | Adds unnecessary Flutter SDK dependency | Use `dart_package` for data and repository layer packages |
| Skipping organization name for apps/plugins | Defaults to a placeholder value | Ask when the template requires it |
