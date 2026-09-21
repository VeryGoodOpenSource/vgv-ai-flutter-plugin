# material-theming eval notes

## Grading

Graded on the artifact. Five of the six cases ask for Dart and grade the code that comes
back. `material-theming-refuses-brightness-check-in-widget` is graded on the refusal plus
the ThemeData it builds instead. Prompts name no skill, so the routing grader catches a
routing failure directly rather than as unexplained content failures downstream.

The lift here is not "use Theme.of(context)". An unaided model reaches for that on its
own, so asserting it alone would pass in both arms. What only the skill supplies is the
VGV structure: the named constant classes `AppColors`, `AppTextStyle` and `AppSpacing`, a
spacing scale derived from one base unit, styles built from a single private base
`TextStyle` via `copyWith`, component styling that lives in `ThemeData` rather than on
widget instances, and the two flat prohibitions, no `EdgeInsets.fromLTRB` and no
brightness branching in widget code. Every grader traces to one of those.

Prompts are self-contained. The fixture has no source in `lib/`, so a prompt about "my
PriceTag widget" earns a refusal and every grader then fails for an unrelated reason.
Widgets are pasted in full rather than added to the fixture, which would leak answers to
the without-arm.

Two prompts deliberately avoid naming the fault. They say "review it" and "cut the
duplication" instead of "stop hardcoding colors". Naming the fault hands the baseline the
fix and collapses the measured difference.

Not measurable here: whether the theme actually renders, and whether the code compiles.
This skill has no measured baseline yet, so read its first run as calibration rather than
as a verdict.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### material-theming-builds-app-theme-from-scratch

**Discriminates.** An unaided model emits one big ThemeData with inline `Color(0x...)`
literals and independently declared TextStyle constructors.

### material-theming-refactors-hardcoded-widget

**Discriminates.** Without the skill the fault is not named in the prompt, so the model
tidies formatting or swaps only the color and leaves the TextStyle.

**Notes.** Colors and text styles are graded twice mechanically and once by rubric. A
response that fixes the color and keeps the TextStyle literal would otherwise clear the
case on partial credit.

### material-theming-defines-spacing-scale

**Discriminates.** A bare model invents xs/s/m/l/xl or space4/space8 with independent
literal values, and keeps `EdgeInsets.fromLTRB`.

**Notes.** `steps-derive-from-base-unit` matches `= 0.25 * spaceUnit;` and does not match
`= 8;`. It accepts any name for the unit, since the reference's `spaceUnit` is one
plausible spelling of it. `uses-skill-scale-naming` grades `xxlg`, because xxs through
xxlg is the skill's scale naming and `xxlg` is close to a fingerprint for the reference
file.

### material-theming-centralizes-component-theme

**Discriminates.** The obvious unaided answer is a shared InputDecoration constant, a
decoration-building helper, or a wrapper widget each field opts into.

### material-theming-refuses-brightness-check-in-widget

**Discriminates.** A model without the skill does as it is told and hands back a tidier
branch, a ternary on `Theme.of(context).brightness` or a `context.isDarkMode` extension,
instead of two ColorSchemes.

**Notes.** `builds-a-dark-color-scheme` proves the second ColorScheme was actually built
rather than only talked about. `Brightness.dark` cannot be a negative grader here, because
the dark scheme needs it. It accepts `ColorScheme.dark(` alongside an explicit
`brightness: Brightness.dark`, since both construct the scheme; it deliberately does not
accept `ThemeData.dark()`, which a model can reach for while leaving the widget branch in
place. `refuses-brightness-branch-in-build` grades the unconditional widget and the stated
rule as two conditions and spells out that a `brightness:` argument on a ColorScheme is
not a branch, so the judge does not read the dark scheme as the defect.

### material-theming-stays-out-of-non-visual-work

**Discriminates.** material-theming must not be invoked, and none of its vocabulary may
appear, no ThemeData, ColorScheme, textTheme, Theme.of, AppColors, AppSpacing,
AppTextStyle or EdgeInsets.

**Notes.** `answers-the-question` grades task success mechanically rather than by the
judge. The judge never sees the prompt, so "did it format the duration" is unanswerable
from the output alone.
