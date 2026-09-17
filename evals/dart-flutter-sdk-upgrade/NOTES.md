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

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### dart-flutter-sdk-upgrade-pins-ci-flutter-with-patch-wildcard

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

**Discriminates.** A bare model states a bundled Dart version from memory, or reuses the
Flutter number, and starts editing. This is the only case that withholds the Dart
version; no arm can fetch the archive, so the graded behavior is asking rather than
answering.

### dart-flutter-sdk-upgrade-declines-dependency-bumps-and-lint-fixes

**Discriminates.** A bare model is helpful and ships all three changes in one pubspec, or
caveats the dependency bump while still writing it. Both target versions are supplied so
the in-scope half stays gradeable mechanically.

### dart-flutter-sdk-upgrade-reports-pub-get-conflict-instead-of-resolving

**Discriminates.** A bare model unblocks the user by raising `very_good_analysis` and
moving on, which is the mixed diff the skill exists to prevent.

### dart-flutter-sdk-upgrade-updates-every-pubspec-and-checks-diff-scope

**Discriminates.** The plan has four parts: every package's pubspec edited individually,
the shared CI workflow once, `pub get` and `analyze` per package, then the diff scope
check before opening the PR. A bare model edits a root pubspec, verifies once at the repo
root, and never checks that the changed-file list holds only workflows and pubspecs.

- `diff-name-only-check` — the documented scope check. Both halves matter: `git diff`
  with a name-only listing is what proves the PR touched nothing else.

### dart-flutter-sdk-upgrade-stays-out-of-dependency-edits

Negative control.

**Discriminates.** Must NOT appear: the skill firing, `flutter_version` / `dart_sdk` /
`very_good_workflows` / the release archive, or a bumped `sdk:` constraint. Deliberately
adjacent — a pubspec edit with version numbers in it — so a skill that fires on any
pubspec work is caught here.

- `answers-the-question` — task success is graded mechanically, not by the judge: the
  judge never sees the prompt, so "did it add the dependency" is unanswerable from the
  output alone.
- `sdk-constraint-untouched` — the SDK constraints must come back untouched. `\b` so a
  `dart_sdk:` line — itself a leak — cannot satisfy this.
