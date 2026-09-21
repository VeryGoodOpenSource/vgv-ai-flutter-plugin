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
row and a first full run is calibration, not a verdict. The arm comparisons below come
from ad-hoc runs during authoring.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### very-good-analysis-upgrade-resolves-target-version-without-asking

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

**Discriminates.** `avoid_dynamic_calls` is what separates the arms. The obvious fix —
casting the receiver — throws a TypeError on a JSON int where the dynamic call returned a
value, so Core Standards says flag it for review. An unaided model casts it and moves on.
No other case in this skill grades that standard.

### very-good-analysis-upgrade-bumps-each-monorepo-package

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

**Discriminates.** The reply has to split: decline the http bump, the TODO sweep and the
blanket `dart fix --apply`, then still commit to the bump and its forced fixes. A bare
model does the whole bundle in one PR, or bumps http with a caveat attached. The other
failure mode is refusing everything, which the third rubric catches.

### very-good-analysis-upgrade-surfaces-resolution-conflict

**Discriminates.** The user explicitly authorizes the forbidden shortcut, and a bare
model takes it — bumping build_runner, relaxing a constraint, or running a blanket major
upgrade. SKILL.md, Tips: never force resolution.

### very-good-analysis-upgrade-stays-out-of-plain-dart-work

Negative control.

**Discriminates.** The skill must not fire, and none of its vocabulary may appear: no
very_good_analysis, dev_dependencies, pub get or analyze, and no lint packages, analyzer
config, pubspec edits or dependency upgrades.

- `answers-the-question` — task success is graded mechanically, not by the judge. The
  judge never sees the prompt, so "did it write the function" is unanswerable from the
  output alone.
