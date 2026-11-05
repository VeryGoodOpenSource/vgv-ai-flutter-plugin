---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [internationalization]
description: "Moving off the synthetic flutter_gen package follows the synced VGE localization standard: output-dir lib/l10n/gen, with a header that keeps format and coverage off the generated files."
---

I upgraded my app to the latest Flutter and it stopped compiling. Every screen imports `package:flutter_gen/gen_l10n/app_localizations.dart`, and that import no longer resolves. This is my current l10n.yaml, treat it as the file on disk:

arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false

The app package is called my_app. Fix the localization config and show me what a screen should import from now on. Show every file I need to change or add.
