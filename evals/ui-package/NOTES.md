# ui-package eval notes

## Grading

`create` is mocked, so the scaffolding half executes.
`ui-package-scaffolds-with-app-ui-package-template` calls the tool and asserts both the
template it carried and where it put the package, and
`ui-package-stays-out-of-plain-dart-work` asserts the tool did not fire. Read the with-arm score on the scaffolding case, never Δ: a mocked tool
is absent in the no-plugin arm, so its graders fail for free. `evals/README.md`, "Mocking
the MCP servers", has the detail. That case measured 11 to 15 turns, which is why every
tool-driving case carries `max_turns: 20` and `timeout_seconds: 900`.

The file-mutation half of the widget workflow is still unmeasurable. The skill's
`allowed-tools` includes `Edit`, and the fixture seeds only a plain `Counter` class, so
there is no UI package on disk to edit; those cases ask the model to list the files and
paths it would create and grade those.

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

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### ui-package-scaffolds-with-app-ui-package-template

**Discriminates.** A bare model builds the package by hand or runs `flutter create
--template=package`, and puts public widgets at the top of lib/.

### ui-package-adds-widget-with-barrel-export-and-test

**Discriminates.** The workflow is one widget per file under lib/src/widgets, a barrel
export, a mirrored widget test, and a Widgetbook use case with the build_runner
regeneration. A bare model writes the widget file and stops, with no barrel export, no
mirrored test path, and no Widgetbook, which is named nowhere outside this skill's
references. Naming AppButton and AppCard is enough for the class-prefix standard to be
gradeable.

**Note.** The barrel file is deliberately not pasted into the prompt. Showing it would
hand the no-plugin arm the convention under test.

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

**Grader notes.** No negative check on the literal string `flutter create`. The first
rubric names `flutter create --template=package` as the wrong path, so a correct answer
routinely writes that string in order to reject it, and the negative failed the right
answer. Same trap as `flutter test` in green-gate.

### ui-package-declines-hand-rolled-button

**Discriminates.** A bare model builds the GestureDetector + DecoratedBox it was asked
for, keeps Color(0xFF6750A4) in build, and leaves the `final Function onTap` the prompt
handed it untouched.

- `uses-material-button` — the documented alternative, graded mechanically alongside the
  first rubric.
- `typed-callback` — "Expose callbacks with ValueChanged<T> or VoidCallback — do not use
  raw Function." The prompt hands the model `final Function onTap` to see if it keeps it.

### ui-package-refuses-parallel-theme-system

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

**Discriminates.** The unaided answer builds tester.pumpWidget(MaterialApp(...)) inline
in every test; pumpApp exists only in this skill's reference.md.

### ui-package-refuses-imports-from-src

**Discriminates.** Three rules: everything under a package's src/ is private, consumers
import the one barrel file, and the barrel re-exports material.dart so no second Material
import is needed. A bare model may land on a barrel file, but it does not know the barrel
re-exports material.dart. Endorsing the per-file imports, or calling it a matter of taste,
also fails.

- `barrel-import-path` — the pattern matches the barrel path without a leading
  `package:`. That omission was forced by a parsing rule in the previous harness that no longer applies
  here; the pattern is kept unchanged so the numbers stay comparable.
- `barrel-re-exports-material` — the prompt's second clause exists to make this
  answerable: asked only "is that fine?", a correct response declines the deep import and
  never mentions the re-export.

### ui-package-stays-out-of-plain-dart-work

Negative control.

**Discriminates.** ui-package must not be invoked, and none of its vocabulary may
appear: no ThemeExtension, app_ui_package, Widgetbook, pumpApp, barrel file, or
context.appColors / context.appSpacing accessors.

- `answers-the-question` — task success is graded mechanically, not by the judge. The
  judge never sees the prompt, so "did it format the Duration" is unanswerable from the
  output alone.
