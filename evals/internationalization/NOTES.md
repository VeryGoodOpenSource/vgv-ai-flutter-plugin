# internationalization eval notes

## Grading

Graded on the artifact. Cases 3, 4 and 5 ask for Dart; cases 1 and 2 are graded on the
config files and the refusal the response produces.

Half of what this skill covers is Flutter's own documented pipeline and the bare model
already knows it. `flutter_localizations`, `intl`, `l10n.yaml`, `flutter gen-l10n` and
ICU plural syntax all show up in the no-plugin arm, so asserting them measures Claude
rather than the plugin. What the skill adds on top, and what these cases grade, is:

- the `l10n.yaml` fingerprint from `references/setup.md`: `arb-dir: lib/l10n/arb`,
  `nullable-getter: false`, `preferred-supported-locales`. Flutter's own docs use
  `lib/l10n` and set neither of the other two
- the `context.l10n` BuildContext extension over `AppLocalizations.of(context)`
- `EdgeInsetsDirectional` / `matchTextDirection` for RTL
- the two prohibitions: no third-party i18n package, and no `AppLocalizations` inside a
  shared widget package

Prompts are self-contained. The fixture has no source in `lib/`, so a prompt about "my
CartSummary" would earn a refusal and every grader would fail for an unrelated reason.
Paste the widget in rather than adding source to the fixture.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### internationalization-sets-up-l10n-pipeline

**Discriminates.** A bare model writes Flutter's documented setup, ARB files in
`lib/l10n`, no `nullable-getter`, `AppLocalizations.of(context)` in `build`.

**Grader notes.** `arb-dir-under-lib-l10n-arb`, `nullable-getter-false` and
`preferred-supported-locales` are each a plugin fingerprint, not Flutter common
knowledge: Flutter's setup docs use `lib/l10n` and set neither of the other two keys.
`declares-l10n-extension` matches the extension declaration written out verbatim in
`SKILL.md`; its use at the call site is graded separately by
`reads-through-context-l10n`.

### internationalization-refuses-third-party-i18n-package

**Discriminates.** A bare model adds `easy_localization` to the pubspec as asked.

**Grader notes.** `no-easy-localization-dependency` matches a real pubspec dependency
line, not the package name in prose: a response that declines has to name
`easy_localization` in order to decline it.

### internationalization-localizes-hardcoded-strings-with-plural

**Discriminates.** A bare model reads strings with `AppLocalizations.of(context)` at the
call site and writes the plural without placeholder metadata.

**Grader notes.** `uses-context-l10n` and `no-app-localizations-at-call-site` are the
Core Standard from both sides. The extension's own body reads
`AppLocalizations.of(this)`, so declaring it does not trip the negative grader, which is
anchored on the `Text(AppLocalizations.of(context)` call-site form. A bare
`AppLocalizations.of(context)` pattern also fired on prose naming the form to avoid.
`uses-context-l10n` matches `context.l10n` followed by a dot or a semicolon, because this
widget reads three strings and hoisting `final l10n = context.l10n;` once is as correct as
reading through the extension at each call site. An earlier form required the trailing dot
and failed that hoisted answer.
`declares-int-placeholder` is step 2 of the skill's Pluralization workflow: an ARB plural
entry whose placeholder metadata does not declare the count as an int never generates.

### internationalization-uses-directional-insets-for-rtl

**Discriminates.** A bare model swaps the padding and then mirrors the arrow manually.

**Grader notes.** `uses-directional-insets` and `no-left-anchored-insets` are the Core
Standard from both sides. The prompt bars repeating the original, so the negative grader
cannot fire on an echo of the pasted widget, and `EdgeInsets\.only\(` does not match
inside `EdgeInsetsDirectional.only(`, so a correct answer cannot trip it either.
`mirrors-image-with-match-text-direction` comes from `references/directionality.md`:
images do not mirror by default, and swapping the padding while leaving the asset
unmirrored is the half-answer it catches. `no-hand-rolled-icon-mirroring` enforces "Icons
mirror automatically in RTL contexts by default", so hand-rolled mirroring duplicates
what the directional `IconData` already does. `no-match-text-direction-on-icon` catches a
form that does not compile: `matchTextDirection` is a field of `IconData` and a parameter
of `Image`, never a parameter of `Icon`.

### internationalization-keeps-shared-package-widget-l10n-free

**Discriminates.** A bare model adds `AppLocalizations` to `app_ui` exactly as
instructed.

**Grader notes.** `label-is-string-field` and `app-level-context-l10n` grade the
documented alternative mechanically: the shared widget grows a `String` field, and the
app-level call site supplies it through the extension.

### internationalization-stays-out-of-plain-string-utilities

**Discriminates.** No ARB files, `AppLocalizations`, `context.l10n`, `gen-l10n` or text
directionality may appear, and the skill must not be invoked.

**Grader notes.** Task success is graded mechanically by `answers-the-question`, not by
the judge. The judge never sees the prompt, so "did it write the function" is
unanswerable from the output alone.
