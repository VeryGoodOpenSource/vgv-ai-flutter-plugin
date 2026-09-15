# ui-package eval notes

## Grading

No MCP server is available to these cases, so the scaffolding half of this skill cannot
execute: `mcp__very-good-cli__create` is unreachable, and the response says so and hands
the user a command instead. Do not assert that a response *calls* the tool — that is
unsatisfiable here and would measure the harness. The scaffolding case grades the
decision instead: which template, through which CLI, and the layout it produces.

The file-mutation half of the widget workflow is unmeasurable for the same reason. The
skill's `allowed-tools` includes `Edit`, but the fixture has no UI package to edit, so
these cases ask the model to list the files and paths it would create and grade those.

Every prompt names the UI package explicitly. That is how a user would phrase it anyway,
and without it routing is a coin flip and every downstream assertion cascades. The
skill's `description` originally covered only "create a ui package", which sent the
widget-test case to the testing skill instead; it now covers work inside an existing UI
package too.

The skill overlaps material-theming on purpose — SKILL.md delegates ThemeData setup to
it. The routing grader only requires ui-package to be among the skills invoked, so a run
that uses both still passes.

None of these cases has been run. ui-package is one of the ten skills added after the
measured baseline, so treat the first numbers as calibration, not a verdict.

Graders are written in the original assertion order: routing, mechanical, judged.

## Cases

### ui-package-scaffolds-with-app-ui-package-template

**Measures.** Scaffolding through the Very Good CLI `app_ui_package` template, and the
lib/src + single-barrel layout that template ships.

**Discriminates.** A bare model builds the package by hand or runs `flutter create
--template=package`, and puts public widgets at the top of lib/.

**History.** A negative check on the literal string `flutter create` was here and was
removed: the first rubric names `flutter create --template=package` as the wrong path, so
a correct answer routinely writes that string in order to reject it, and the negative
failed the right answer. Same trap as `flutter test` in green-gate.

The template name is the whole point of this case: `app_ui_package` appears only in this
SKILL.md, and create-project's template list does not contain it either.

### ui-package-adds-widget-with-barrel-export-and-test

**Measures.** The whole add-a-widget workflow: one widget per file under
lib/src/widgets, a barrel export, a mirrored widget test, and a Widgetbook use case with
the build_runner regeneration.

**Discriminates.** A bare model writes the widget file and stops — no barrel export, no
mirrored test path, no Widgetbook, which is named nowhere outside this skill's
references. The barrel file is deliberately not pasted into the prompt; showing it would
hand the no-plugin arm the convention under test. Naming AppButton and AppCard is enough
for the class-prefix standard to be gradeable.

- `widget-file-path` — one widget per file, named after the widget in snake_case, under
  src/. `\w` covers underscores, so app_badge.dart and app_unread_badge.dart both match.
- `barrel-export` — the barrel-export step. The bounded gap following `export` absorbs both
  the relative form and the `package:storefront_ui/` form; a single wildcard rejected the
  latter.
- `mirrored-test-path` — "Every widget has a corresponding widget test", at the mirrored
  test path.
- `mentions-widgetbook` — reference.md's widget workflow ends with a Widgetbook use case
  and a build_runner regeneration. Nothing outside the skill's references mentions
  Widgetbook.

### ui-package-declines-hand-rolled-button

**Measures.** The refusal to rebuild a Material primitive: compose the Material button
widgets, read colors from the theme, and type the callback.

**Discriminates.** A bare model builds the GestureDetector + DecoratedBox it was asked
for, keeps Color(0xFF6750A4) in build, and leaves the `final Function onTap` the prompt
handed it untouched.

- `uses-material-button` — the documented alternative, graded mechanically alongside the
  first rubric.
- `typed-callback` — "Expose callbacks with ValueChanged<T> or VoidCallback — do not use
  raw Function." The prompt hands the model `final Function onTap` to see if it keeps it.

**History.** `no-hardcoded-color-in-build` failed a routed run at 0.86. Its FAIL clause
reached past the widget — "colors come from anywhere other than the theme, such as a
private color constant declared in the package" — and reference.md teaches exactly that
constant: `static const _seedColor = Color(0xFF6750A4)` inside `AppTheme`. A correct
answer that moves the hex to the seed tripped the FAIL while satisfying the PASS. The
rubric now names the widget class as the only subject, puts theme setup explicitly out of
scope, and accepts a widget that declares no colors at all and inherits them from the
ambient theme, which the old PASS ("colors are read from Theme.of(context).colorScheme")
did not cover.

### ui-package-refuses-parallel-theme-system

**Measures.** Custom tokens as a ThemeExtension registered on ThemeData and read through
a BuildContext extension, holding only what Material lacks.

**Discriminates.** A bare model delivers the requested StorefrontTheme InheritedWidget,
redeclares primary/onSurface in it, and writes the StorefrontTheme.of(context) lookup the
prompt asked for.

- `registers-on-theme-data` — registering the extension on ThemeData is what replaces the
  InheritedWidget at the app root, and it is the step a response that only renames the
  class misses.
- `build-context-extension` — reference.md's AppThemeBuildContext, the documented
  replacement for the StorefrontTheme.of(context) lookup. `\w*` so an unnamed extension
  counts too.

### ui-package-tests-widget-through-pump-app-helper

**Measures.** Widget tests pumped through the package's reusable pumpApp helper, which
carries the package theme.

**Discriminates.** The unaided answer builds tester.pumpWidget(MaterialApp(...)) inline
in every test; pumpApp exists only in this skill's reference.md.

### ui-package-refuses-imports-from-src

**Measures.** That everything under a package's src/ is private, that consumers import
the one barrel file, and that the barrel re-exports material.dart so no second Material
import is needed.

**Discriminates.** A bare model may land on a barrel file, but it does not know the
barrel re-exports material.dart. Endorsing the per-file imports, or calling it a matter
of taste, also fails.

- `barrel-import-path` — the pattern matches the barrel path without a leading
  `package:`. That omission was forced by a parsing rule in the previous harness that no longer applies
  here; the pattern is kept unchanged so the numbers stay comparable.
- `barrel-re-exports-material` — the prompt's second clause exists to make this
  answerable: asked only "is that fine?", a correct response declines the deep import and
  never mentions the re-export.

### ui-package-stays-out-of-plain-dart-work

Negative control.

**Measures.** That plain Dart work with no widget and no theme leaves the skill dormant.
Nothing else catches it firing where it should not.

**Discriminates.** ui-package must not be invoked, and none of its vocabulary may
appear: no ThemeExtension, app_ui_package, Widgetbook, pumpApp, barrel file, or
context.appColors / context.appSpacing accessors.

- `answers-the-question` — task success is graded mechanically, not by the judge. The
  judge never sees the prompt, so "did it format the Duration" is unanswerable from the
  output alone.

## Dropped in the native migration

The `dart-parses` syntax assertion has no native equivalent and was deleted from:

- ui-package-adds-widget-with-barrel-export-and-test
- ui-package-declines-hand-rolled-button
- ui-package-refuses-parallel-theme-system
- ui-package-tests-widget-through-pump-app-helper
