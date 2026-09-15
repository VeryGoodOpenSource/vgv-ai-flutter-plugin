# very-good-analysis-upgrade eval notes

## Grading

This skill's real job is mutating pubspec.yaml, running `pub get` / `analyze`, and
opening a PR. None of that can happen here: the cases grant only Skill, Read, Glob and
Grep, so there is no Bash to run curl, pub or git with, and no package to upgrade. Every
case asks the model to narrate and grades the decisions — which command it would run, in
which order, what it changes in the pubspec, what it leaves alone, what it refuses.

Do not add an assertion that the response *executes* anything. That is unsatisfiable here
and measures the harness.

Prompts paste their own pubspec.yaml and analyzer output. The fixture's pubspec
dev-depends on flutter_lints, not very_good_analysis, so a prompt saying "upgrade it in
this package" earns "it isn't in your pubspec" and every grader below fails for an
unrelated reason. Each prompt states that it is the source of truth.

Not covered: the PR step. With no Bash there is no git, and grading commit-message
wording alone tests phrasing rather than judgment. The PR's load-bearing property — that
it contains nothing but the bump and the lint fixes it forces — is graded in the
scope-creep case instead.

This is one of the ten skills added after the measured baseline, so it has no baseline
row and a first full run is calibration, not a verdict. The comparisons in the History
lines below come from ad-hoc runs during authoring.

Graders are written in the original assertion order: routing, mechanical, judged.

## Cases

### very-good-analysis-upgrade-resolves-target-version-without-asking

**Measures.** Resolves the target version itself via the pub.dev API and lays out the
bump → pub get → analyze → fix → analyze sequence in order.

**Discriminates.** No version is supplied on purpose. SKILL.md's "Before You Start" says
fetch the latest and proceed; a bare model asks which version to target or reaches for
`pub outdated`, and skips the final verifying analyze.

- `pub-dev-api-endpoint` and `latest-version-field` — the version-resolution recipe is
  verbatim in SKILL.md. Graded three ways because it is this case's whole point: the
  endpoint, the field it reads, the choice not to ask.
- `resolves-version-itself` — grades the choice not to ask, phrased as the method the
  response commits to. There is no Bash here, so an earlier wording that asked whether the
  response "determines the target version by querying pub.dev" was unsatisfiable: a correct
  plan states the request it will make and cannot report a number.
- `ordered-plan-with-final-analyze` — grades the five steps by relative order and says so,
  because a correct plan also resolves the version first and opens a PR last. An earlier
  wording tied the final analyze to "before committing", which the prompt never asks about,
  leaving a plan that ends at the clean analyze in neither the PASS nor the FAIL clause.

### very-good-analysis-upgrade-keeps-the-caret-and-changes-nothing-else

**Measures.** Writes `^10.0.0` against an explicit request to pin exactly, says the caret
is the VGV convention, and touches nothing else in the pubspec.

**Discriminates.** "pin it exactly" is the discriminator. SKILL.md Step 1: keep the
caret, don't change anything else in the file. A bare model complies with the pin and
often tidies the neighboring dev deps while it is in there.

- `keeps-the-caret` — fails if the model honored "pin it exactly" and wrote
  `very_good_analysis: 10.0.0`.
- `other-dev-deps-untouched` — proves the other dev dependencies came through untouched.
  The prompt asks for the full block, so a correct answer must reprint this line verbatim.
- `dart-pub-get` — pure Dart package, no flutter dependency, so SKILL.md Step 1's
  parenthetical applies: `dart pub get`, not `flutter pub get`.

### very-good-analysis-upgrade-fixes-only-the-new-lints

**Measures.** Fixes the two new style lints, leaves the two pre-existing ones for their
own PR, and escalates the one whose fix changes runtime behavior.

**Discriminates.** `avoid_dynamic_calls` is what separates the arms. The obvious fix —
casting the receiver — throws a TypeError on a JSON int where the dynamic call returned a
value, so Core Standards says flag it for review. An unaided model casts it and moves on.
No other case in this skill grades that standard.

**History.** The pre-existing-versus-new split alone measured nothing: with the prompt
stating outright which two predate the bump, the no-plugin arm made the same call, in the
same words, and passed every content assertion here. The third new lint is what gives
this case lift.

- `const-and-trailing-comma` — one regex covers both style lints:
  prefer_const_constructors wants the `const`, require_trailing_commas wants the comma,
  and both land on the same line. The pattern carries a backslash *and* a single quote,
  so its YAML value is single-quoted with the inner quotes doubled; a double-quoted
  scalar would reject the `\(` escape.
- `leaves-pre-existing-lints` and `exactly-two-edits` — "fix only new warnings" graded
  twice: once on the stated decision, once on the list of what it will change.
- `exactly-two-edits` — phrased as "what the response says it changed" rather than "what
  it changed": the judge never sees the original file, so a rename or reorder is
  invisible to it. Its FAIL clause used to open "FAIL if it also claims a cast", which
  collided with `escalates-dynamic-call-lint`: that grader requires the response to name
  the cast in order to hand it to a human, and the judge read the required mention as a
  claimed edit and failed a correct answer. FAIL now fires only on a third change the
  response says it *applied*, and naming a change in order to decline it is called out as
  a PASS.

### very-good-analysis-upgrade-bumps-each-monorepo-package

**Measures.** One pubspec edit per package, `pub get` inside each package, a single
analyze from the repo root.

**Discriminates.** A bare model writes one root-level change and one root-level pub get,
or analyzes package by package. SKILL.md splits the two commands by where they run.

- `two-pub-gets` — pub get is run per package rather than once at the root. SKILL.md,
  Tips: "`pub get` must be run per-package." It accepts either two separate invocations
  or one mention qualified by each/every/per. Requiring the literal phrase twice failed
  SKILL.md's own phrasing, "run `dart pub get` in each of the three packages".
- `per-package-pubspec-edits` — phrased as what the response prescribes, not what it
  executed: the prompt ends "Don't run anything", so a judge reading "edits" literally
  fails a correct plan.

### very-good-analysis-upgrade-refuses-scope-creep

**Measures.** Splits the reply: declines the http bump, the TODO sweep and the blanket
`dart fix --apply`, then still commits to the bump and its forced fixes.

**Discriminates.** A bare model does the whole bundle in one PR, or bumps http with a
caveat attached. The other failure mode is refusing everything, which the third rubric
catches.

**History.** The first prompt said "I am describing my package from memory" while
describing nothing, so the model refused outright and all three rubrics failed on the
refusal rather than on scope judgment. The pubspec gives it something concrete and the
close asks for PR contents, not edits. Four graders and no cheap regex on "10.0.0" is
deliberate: the prompt states the version, so echoing it proves nothing, and a free
grader would only widen the gap. Note the threshold arithmetic, though: with routing at
weight 3 and three content graders the total weight is 6, so one content miss scores 5/6
= 0.83 and still clears 0.8. This case can pass while failing `refuses-http-bump`, which
is its headline assertion. Weighting that grader would close the hole.

### very-good-analysis-upgrade-surfaces-resolution-conflict

**Measures.** On a solver failure, names both conflicting analyzer constraints and hands
the decision back instead of resolving it.

**Discriminates.** The user explicitly authorizes the forbidden shortcut, and a bare
model takes it — bumping build_runner, relaxing a constraint, or running a blanket major
upgrade. SKILL.md, Tips: never force resolution.

### very-good-analysis-upgrade-stays-out-of-plain-dart-work

Negative control.

**Measures.** That a plain Dart utility request routes nowhere near this skill. Nothing
else catches it firing where it should not.

**Discriminates.** The skill must not fire, and none of its vocabulary may appear: no
very_good_analysis, dev_dependencies, pub get or analyze, and no lint packages, analyzer
config, pubspec edits or dependency upgrades.

- `answers-the-question` — task success is graded mechanically, not by the judge. The
  judge never sees the prompt, so "did it write the function" is unanswerable from the
  output alone.

## Dropped in the native migration

The `dart-parses` syntax assertion has no native equivalent and was deleted from:

- very-good-analysis-upgrade-fixes-only-the-new-lints
