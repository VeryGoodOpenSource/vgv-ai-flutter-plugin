---
name: ui-package
description: Best practices for building a Flutter UI package on top of Material — custom components, ThemeExtension-based theming, consistent APIs, and widget tests. Supports app_ui_package template.
when_to_use: Use when creating a UI package, and whenever working inside one — adding or reviewing a widget, wiring design tokens, exporting through the barrel file, or writing tests for a widget that lives in a UI package. Trigger on "create a ui package", "add a widget to our ui package", "add a design token", "export it from the barrel", "write tests for this widget in my ui package", and on any request naming a package whose job is shared widgets and design tokens.
allowed-tools: Read Glob Grep Edit Write mcp__very-good-cli__create
model: sonnet
---

# UI Package

Best practices for creating a Flutter UI package — a reusable widget library that builds on top of `package:flutter/material.dart`, extending it with app-specific components, custom design tokens via `ThemeExtension`, and a consistent API surface.

> **Theming foundation:** This skill focuses on UI package structure, widget APIs, and testing. For foundational Material 3 theming (`ColorScheme`, `TextTheme`, component themes, spacing constants, light/dark mode), see the **Material Theming** skill (`/material-theming`). The two skills are complementary — Material Theming covers how to set up and use `ThemeData`; this skill covers how to extend it with `ThemeExtension` tokens and package reusable widgets around it.

## Core Standards

Apply these standards to ALL UI package work:

- **Scaffold from the `app_ui_package` template** — create the package with the Very Good CLI MCP tool, `subcommand: 'app_ui_package'`. Never `flutter_package`, never `dart_package`, never `flutter create --template=package`; those produce a bare package with none of the theme, barrel, test-helper, or Widgetbook scaffolding below
- **Build on Material** — depend on `flutter/material.dart` and compose Material widgets; do not rebuild primitives that Material already provides
- **One widget per file** — each public widget lives in its own file named after the widget in snake_case (e.g., `app_button.dart`)
- **Barrel file for public API** — expose all public widgets and theme classes through a single barrel file (e.g., `lib/my_ui.dart`) that also re-exports `material.dart`, so one import gives a consumer both Material's widgets and the package's own and no second Material import is needed
- **`lib/src/` is private** — consumers import the barrel and nothing else; a per-file import such as `package:my_ui/src/widgets/app_button.dart` reaches into private implementation and breaks on any internal rename. Tree shaking already drops unused widgets, so the barrel costs nothing
- **Extend theming with `ThemeExtension`** — use Material's `ThemeData`, `ColorScheme`, and `TextTheme` as the base (see Material Theming skill); add app-specific tokens (spacing, custom colors) via `ThemeExtension<T>`, register every one of them on `ThemeData.extensions`, and read them through a `BuildContext` extension (`context.appColors`, `context.appSpacing`)
- **Every widget has a corresponding widget test** — behavioral tests verify interactions, callbacks, and state changes, pumped through the package's `pumpApp` helper rather than an inline `MaterialApp`
- **Decline anti-patterns with working code** — when a request asks for something in the Anti-Patterns table, say why it is wrong and deliver the corrected implementation in the same response. Do not stop at the objection, and do not ask permission to do it the documented way
- **Prefix all public classes** — use a consistent prefix (e.g., `App`, `Vg`) to avoid naming collisions with Material widgets
- **Use `const` constructors everywhere possible** — all widget constructors must be `const` when feasible
- **Document every public member** — every public class, constructor parameter, and method has a dartdoc comment

## Package Structure

```text
my_ui/
├── lib/
│   ├── my_ui.dart              # Barrel file — re-exports material.dart + all public API
│   └── src/
│       ├── theme/
│       │   ├── app_theme.dart        # AppTheme class with light/dark ThemeData builders
│       │   ├── app_colors.dart       # AppColors ThemeExtension for custom color tokens
│       │   ├── app_spacing.dart      # AppSpacing ThemeExtension for spacing tokens
│       │   └── app_text_styles.dart  # Optional: extra text styles beyond Material's TextTheme
│       ├── widgets/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── app_card.dart
│       │   └── ...
│       └── extensions/
│           └── build_context_extensions.dart  # context.appColors, context.appSpacing shortcuts
├── test/
│   ├── src/
│   │   ├── theme/
│   │   │   └── app_theme_test.dart
│   │   └── widgets/
│   │       ├── app_button_test.dart
│   │       └── ...
│   └── helpers/
│       └── pump_app.dart         # Test helper wrapping widgets in MaterialApp + theme
├── widgetbook/                   # Widgetbook catalog submodule (sandbox + showcase)
│   └── ...
└── pubspec.yaml
```

## Building Widgets

### Widget API Guidelines

- Compose Material widgets — use `FilledButton`, `OutlinedButton`, `TextField`, `Card`, etc. as building blocks
- Accept only the minimum required parameters — avoid "kitchen sink" constructors
- Use named parameters for everything except `key` and `child`/`children`
- Provide sensible defaults derived from the theme when a parameter is not supplied
- Expose callbacks with `ValueChanged<T>` or `VoidCallback` — do not use raw `Function`
- Use `Widget?` for optional slot-based composition (leading, trailing icons, etc.)

## Anti-Patterns

| Anti-Pattern | Correct Approach |
| ------------ | ---------------- |
| Rebuilding widgets Material already provides (e.g., custom button from `GestureDetector` + `DecoratedBox`) | Compose Material widgets (`FilledButton`, `OutlinedButton`) and style them |
| Creating a parallel theme system with custom `InheritedWidget` | Use Material's `ThemeData` as the base and `ThemeExtension` for custom tokens |
| Hardcoding `Color(0xFF...)` in widget code | Use `Theme.of(context).colorScheme` for standard colors and `context.appColors` for custom tokens |
| Duplicating Material's `ColorScheme` roles in a custom class | Only create `ThemeExtension` tokens for values Material does not cover (e.g., success, warning, info) |
| Using `dynamic` or `Object` for callback types | Use `VoidCallback`, `ValueChanged<T>`, or specific function typedefs |
| Exposing internal implementation files directly | Use a barrel file; keep all files under `src/` private |

## Creating the Package

Scaffold with the Very Good CLI MCP `create` tool:

| Parameter          | Value                                                              |
| ------------------ | ------------------------------------------------------------------ |
| `subcommand`       | `app_ui_package` — always, for every UI package                    |
| `name`             | the package name in snake_case (e.g., `storefront_ui`)             |
| `output_directory` | the monorepo directory holding shared packages (e.g., `packages/`) |

`app_ui_package` is the template that ships the `lib/src/theme` extensions, the barrel
file, the `pumpApp` helper, and the Widgetbook catalog. Do not substitute
`flutter_package` on the grounds that it takes no organization name — neither template
does, and `flutter_package` gives you an empty package you then rebuild by hand.

See [reference.md](reference.md) for the `ThemeExtension` class table (`AppColors`, `AppSpacing`, `AppTheme`, the `BuildContext` extension), the `pumpApp` test helper, a barrel file example, the Widgetbook catalog concepts and `build_runner` commands, and step-by-step workflows for adding a widget or a custom token.
