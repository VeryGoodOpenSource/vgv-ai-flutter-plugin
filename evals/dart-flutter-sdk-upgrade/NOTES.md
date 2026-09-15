# dart-flutter-sdk-upgrade eval notes

## Grading

Graded on narration, never on an artifact. The skill's real job is editing
`.github/workflows/*.yml` and `pubspec.yaml`, running `pub get` / `analyze`, and checking
the diff before a PR. None of that can happen here: the fixture is a bare app with no
`.github/`, no monorepo and no lockfile, and the cases grant no Edit, Bash, or MCP tools.
So every case grades the decisions the response narrates — which key it writes in which
file, which version format goes where, what it verifies, what it refuses to put in the PR.

The load-bearing distinction throughout, and the thing the no-plugin arm gets wrong, is that
the same upgrade is written three different ways: CI Flutter is `MAJOR.MINOR.x` (literal
wildcard, no caret), CI Dart is an exact patch under a `dart_sdk` key, and pubspec is
`^MAJOR.MINOR.PATCH`.

Trap for anything added here: do not assert a Dart-for-Flutter version mapping as fact.
The skill resolves it from <https://docs.flutter.dev/install/archive>, and no arm can
fetch that page, so "Flutter 3.41.0 ships Dart 3.11.0" is unknowable rather than wrong.
Where a case needs both numbers to grade a file edit, the prompt supplies both; the one
case that withholds the Dart version grades the lookup itself, not the answer.

These responses are YAML, not Dart, so no syntax grader applies to any case in this
skill.

Graders are written in the original assertion order: routing, mechanical, judged.

## Cases

### dart-flutter-sdk-upgrade-pins-ci-flutter-with-patch-wildcard

**Measures.** CI Flutter is pinned as `3.41.x`, and the response explains that the
wildcard is what resolves to the latest patch.

**Discriminates.** A bare model writes the exact patch or a caret into CI, and treats the
Flutter number as the Dart number. The pasted workflow says `flutter_channel: stable` on
purpose — a workflow that already read `flutter_version: "3.35.x"` would hand both arms
the format the skill exists to teach, and the case would measure copying.

- `ci-flutter-patch-wildcard` — `[^\n^]{0,3}` absorbs the optional quoting, and excluding
  `^` from the class makes `flutter_version: "^3.41.x"` fail. There is deliberately no
  mirroring negative grader on `3.41.0`: a correct answer writes the exact patch in order
  to reject it.
- `flutter-version-is-not-dart-version` — a one-sided guard against conflation, not a
  demand that Dart be discussed. The prompt is CI-only and `flutter_version` takes the
  Flutter number, so a correct minimal answer has nowhere to put a Dart version and never
  mentions one. Two successive rubrics failed that answer anyway: the first required it to
  name the pubspec `sdk:` constraint, and the replacement still failed a response that
  "never draws the distinction at all". The rubric now passes on silence and fails only on
  the conflation itself — the Flutter number asserted as the Dart number, or written into
  a slot the response labels `sdk:` or `dart_sdk:`. That is still what the bare arm does
  when it volunteers a pubspec edit, so the discriminator survives the narrowing. Note
  also that the case tolerates one miss: routing at weight 3 plus three content graders is
  weight 6, so a single content miss scores 5/6 = 0.83 and passes.

### dart-flutter-sdk-upgrade-uses-dart-sdk-key-for-pure-dart-package

**Measures.** A pure Dart package gets the `dart_sdk` key in `dart_package.yml` at an
exact patch, `^3.11.0` in the pubspec, and no `flutter:` environment entry.

**Discriminates.** A bare model reaches for `flutter_version` and `flutter_package.yml`,
or adds a `flutter:` constraint to a package that has no Flutter dependency. The workflow
body is described rather than pasted for that reason: those two names are what the skill
knows and a bare model guesses at.

- `ci-dart-sdk-exact-patch` — `^` is excluded from the class rather than bounded by
  length: with a plain `[^\n]{0,3}` the wrong answer `dart_sdk: "^3.11.0"` matches, since the
  space, the `"` and the `^` are three characters.
- `pubspec-caret-constraint` — the pubspec form of the same version. `\b` is what keeps
  this off `dart_sdk:` — without it a caret-in-CI answer satisfies both patterns and
  scores full marks.

### dart-flutter-sdk-upgrade-resolves-bundled-dart-version-before-editing

**Measures.** With the Dart version withheld, the response cites Flutter's release
archive and confirms both versions before touching files.

**Discriminates.** A bare model states a bundled Dart version from memory, or reuses the
Flutter number, and starts editing. This is the only case that withholds the Dart
version; no arm can fetch the archive, so the graded behavior is asking rather than
answering.

**History.** A measured run spent the whole answer on the pasted block not matching
`fixture/pubspec.yaml` and never reached the version question. The fixture is
deliberately neutral so it will never match a pasted pubspec; naming the paste as
authoritative removes that harness artifact.

- `cites-release-archive` — the documented source, in either the URL or the named form.

### dart-flutter-sdk-upgrade-declines-dependency-bumps-and-lint-fixes

**Measures.** The prohibition case: the http bump and the analyzer fixes are refused
outright, not caveated, while the SDK constraint edit still lands.

**Discriminates.** A bare model is helpful and ships all three changes in one pubspec, or
caveats the dependency bump while still writing it. Both target versions are supplied so
the in-scope half stays gradeable mechanically.

**History.** `lib/main.dart` does not exist in the neutral fixture, and without the
"another checkout" framing a measured run argued about the missing file and asked to be
sent it — which reads to the blind judge as willingness to fix the warnings, grading the
fixture instead of the refusal.

- `pubspec-flutter-constraint` — proves it still did the in-scope work rather than
  refusing wholesale. `\b` keeps it off keys that end in `flutter`; the caret is required
  because pubspec form is never the CI wildcard.
- `no-http-bump` — the mechanical mirror of the dependency-refusal rubric: the forbidden
  edit must not appear in pubspec form anywhere in the answer.

### dart-flutter-sdk-upgrade-reports-pub-get-conflict-instead-of-resolving

**Measures.** A version-solving failure mid-bump is reported by package and clashing
constraint, and the decision goes back to the user.

**Discriminates.** A bare model unblocks the user by raising `very_good_analysis` and
moving on, which is the mixed diff the skill exists to prevent.

**History.** Same fixture artifact as the declines-dependency-bumps case: the failing
package is named as being elsewhere so the answer grades conflict handling rather than a
hunt for a `very_good_analysis` dependency the neutral fixture does not have.

### dart-flutter-sdk-upgrade-updates-every-pubspec-and-checks-diff-scope

**Measures.** Monorepo plan: every package's pubspec edited individually, the shared CI
workflow once, `pub get` and `analyze` per package, then the diff scope check before
opening the PR.

**Discriminates.** A bare model edits a root pubspec, verifies once at the repo root, and
never checks that the changed-file list holds only workflows and pubspecs.

- `diff-name-only-check` — the documented scope check. Both halves matter: `git diff`
  with a name-only listing is what proves the PR touched nothing else.

### dart-flutter-sdk-upgrade-stays-out-of-dependency-edits

Negative control.

**Measures.** A plain dependency add is answered without the skill and without touching
the SDK constraints.

**Discriminates.** Must NOT appear: the skill firing, `flutter_version` / `dart_sdk` /
`very_good_workflows` / the release archive, or a bumped `sdk:` constraint. Deliberately
adjacent — a pubspec edit with version numbers in it — so a skill that fires on any
pubspec work is caught here.

- `answers-the-question` — task success is graded mechanically, not by the judge: the
  judge never sees the prompt, so "did it add the dependency" is unanswerable from the
  output alone.
- `sdk-constraint-untouched` — the SDK constraints must come back untouched. `\b` so a
  `dart_sdk:` line — itself a leak — cannot satisfy this.

## Dropped in the native migration

Nothing. No case in this skill carried a `dart-parses` assertion.
