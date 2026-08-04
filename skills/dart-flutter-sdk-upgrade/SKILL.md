---
name: dart-flutter-sdk-upgrade
description: >
  VGV-specific reference for bumping Dart and Flutter SDK constraints across packages.
  Covers pubspec.yaml environment constraints, CI workflow Flutter versions, and SDK
  upgrade PR preparation. Flutter CI uses MAJOR.MINOR.x with no caret to resolve to
  the latest patch; pubspec pins the exact patch with a caret (e.g., ^3.50.1).
when_to_use: >
  Use when upgrading the Flutter or Dart SDK version in any VGV repository. Trigger on
  phrases like "bump Flutter to 3.x", "update SDK constraints", "upgrade Dart SDK",
  "update CI Flutter version", "bump SDK version", or "prep the SDK upgrade PR". Also
  use when an SDK bump is already underway and something breaks — "pub get fails after
  I changed the environment block", "version solving failed after bumping the SDK",
  "a dependency requires an older SDK", "get me unblocked on the Flutter upgrade", or
  "which Dart version ships with Flutter 3.x". Own the whole bump, including the
  conflicts it surfaces, even when the blocking package has a skill of its own.
argument-hint: "[flutter-version]"
allowed-tools: Read Glob Grep Edit Write Bash
model: sonnet
effort: medium
---

# VGV Flutter/Dart SDK Upgrade — Quick Reference

One PR per project. Only CI workflow and `pubspec.yaml` changes — no logic, no dependency
version bumps, no test changes.

---

## Core Standards

Apply these standards to ALL SDK upgrade work:

- **Flutter and Dart versions differ** — a Flutter release ships a Dart SDK whose version number is unrelated to it, and the pubspec `sdk:` constraint takes the Dart number, never the Flutter one. Look the pairing up in the release archive at <https://docs.flutter.dev/install/archive>
- **Never state a bundled Dart version from memory** — not from recall, not by inference from the Flutter number, and not from an example in this file. Either the user supplied the Dart version, or you read it off the archive, or you ask. There is no fourth source
- **Flutter CI uses `MAJOR.MINOR.x`** — no caret, `.x` wildcard resolves to latest patch
- **Dart CI uses exact patch** — `MAJOR.MINOR.PATCH`, no caret, no wildcard
- **pubspec pins exact patch** — use `^MAJOR.MINOR.PATCH` with the specific patch version
- **Pure Dart packages** — use the Dart version directly, no Flutter mapping needed. The CI key is `dart_sdk` in `dart_package.yml`, not `flutter_version` in `flutter_package.yml`, and the environment block gets `sdk:` with no `flutter:` line beside it
- **Write the CI block even without the file** — the reusable workflow and its version key are determined by the package type, so a workflow you have not seen is still a known shape. Produce the `with:` block from the CI workflows section below and name the file it belongs in rather than asking for the file first
- **Verify with `pub get` and `analyze`** — don't silently resolve conflicts
- **Decline out-of-scope edits, don't caveat them** — when asked to also bump a
  dependency, fix a lint, or change code, do not produce that edit at all. Deliver the
  SDK constraint and CI changes, report the rest as separate follow-up work

---

## 0. Resolve target version

Flutter bundles a specific Dart release, and the two version numbers are unrelated. A bump to
Flutter 3.35.5 does not make the Dart constraint `^3.35.5`, and the Dart number cannot be
derived from the Flutter number by any rule. Every SDK upgrade therefore starts with two
versions, not one: the Flutter release being targeted, and the Dart release it ships.

**How to find the Dart version:**

1. Open <https://docs.flutter.dev/install/archive>
2. Find the target Flutter stable release
3. Note the Dart version listed alongside it

The Flutter target comes from `$ARGUMENTS` when the user supplied one. If `$ARGUMENTS` is
empty, take the latest Flutter stable from that same page. For pure Dart packages, no mapping
is involved: the Dart version is whatever `$ARGUMENTS` specifies or the latest Dart stable.

**When the archive is out of reach**, which is the common case in a session with no network
access, do not fill the gap from memory. A recalled pairing is wrong often enough to break
`pub get`, and it is wrong silently — the constraint looks plausible in the diff. Say the Dart
version has to come off the archive, name the page as the source, and ask the user to confirm
it. If the user already supplied both numbers, use them as given and say which is which.

State both resolved versions and get confirmation before editing any file.

---

## 1. CI workflows — `.github/workflows/`

VGV packages use `VeryGoodOpenSource/very_good_workflows` reusable workflows. Leave the
`@v1` tag untouched. Flutter packages use `MAJOR.MINOR.x` — no caret, literal `x` as the
patch wildcard so CI resolves to the latest patch automatically. Dart packages pin the exact
patch version. When bumping versions, update MAJOR and/or MINOR as appropriate
(e.g., `3.41.x` → `3.42.x` or `4.0.x`):

**Flutter package:**

```yaml
uses: VeryGoodOpenSource/very_good_workflows/.github/workflows/flutter_package.yml@v1
with:
  flutter_version: "3.41.x" # ← MAJOR.MINOR.x, resolves to latest patch
```

**Pure Dart package** — note the key is `dart_sdk`, not `flutter_version`. Use the Dart
version, not the Flutter version:

```yaml
uses: VeryGoodOpenSource/very_good_workflows/.github/workflows/dart_package.yml@v1
with:
  dart_sdk: "3.11.0" # ← exact Dart version (not Flutter version)
```

If a file uses `flutter_channel: stable` instead of a pinned version,
pin the version — VGV always pins Flutter versions in CI workflows.

### When the workflow file is not in hand

A VGV package's CI is one job calling one of the two reusable workflows above, so the block that
needs changing is fully determined by the package type. When the workflow lives in another
checkout, or the user described it instead of pasting it, write the `with:` block from the
shapes above rather than stalling on the file. Say which workflow and which key you are
targeting — `dart_package.yml` with `dart_sdk` for a pure Dart package, `flutter_package.yml`
with `flutter_version` for a Flutter one — and present it as the block to merge into the
existing job.

Two things are not invented that way. Do not fabricate the surrounding `name:`, `on:` or `jobs:`
keys when you have not seen them, and do not guess a version number. Show the `with:` block and
name the file it belongs in.

```yaml
# Pure Dart package, target Dart 3.11.0 — the block to merge into your existing job
uses: VeryGoodOpenSource/very_good_workflows/.github/workflows/dart_package.yml@v1
with:
  dart_sdk: "3.11.0"
```

---

## 2. `pubspec.yaml` environment constraints

Format is `^MAJOR.MINOR.PATCH` (caret, exact patch). Unlike CI, pubspec pins a specific
patch version — the one the user specifies or the current stable at the time of the bump.

**Flutter package** (has `flutter:` under `dependencies`):

```yaml
environment:
  sdk: ^<dart-version> # ← the Dart version the target Flutter release ships
  flutter: ^<flutter-version> # ← the target Flutter release itself
```

The two placeholders are deliberate. Filling them in requires the archive lookup from step 0,
and the numbers are never the same: for a bump to Flutter 3.35.5 the `flutter:` constraint is
`^3.35.5` and the `sdk:` constraint is whatever Dart version the archive lists beside 3.35.5.
Writing the Flutter number into `sdk:` is the single most common error in this change.

**Pure Dart package** (no Flutter SDK dependency):

```yaml
environment:
  sdk: ^3.11.0 # ← Dart version only
  # no flutter: line
```

In a monorepo, update each package's `pubspec.yaml` individually. The shared CI workflow
only needs updating once.

---

## 3. Verify

Run from each package directory. **Use Dart/Flutter MCP tools if available; otherwise Bash.**

```bash
flutter pub get   # or: dart pub get  (for pure Dart packages)
flutter analyze   # or: dart analyze
```

If `pub get` fails with dependency conflicts, report them — don't silently resolve by
upgrading packages. Name the blocking package, its version, and the SDK constraint that
clashes with the new one, then hand the decision back to the user: raising that
dependency is its own PR, not part of this one. If `analyze` surfaces new errors
introduced by the SDK bump, report them rather than fixing them in this PR.

See [references/version-conflicts.md](references/version-conflicts.md) for reading version
solving output, the three shapes a conflict takes, tracing a transitive blocker, and the
report format to hand back.

---

## 4. Out-of-scope requests

Users routinely ask for the SDK bump plus extras in one breath — "while you're in the
pubspec, bump this package too", "and fix the new analyzer warnings so CI is green".
Refuse the extras outright. A caveat attached to the forbidden edit is not a refusal:
writing the new dependency version into the pubspec while noting that it doesn't belong
there still ships the mixed PR.

So when the request is "bump to the new Flutter, raise the `http` constraint, and fix the two
analyzer warnings", the pubspec you return changes the environment block and nothing else:

```yaml
environment:
  sdk: ^<dart-version> # ← changed, Dart version from the archive
  flutter: ^<flutter-version> # ← changed, the target Flutter release

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0 # ← left alone, dependency bumps are a separate PR
```

Then say plainly what you did not do and where it goes instead:

- the dependency bump belongs in its own PR — a mixed diff can't be bisected when
  something breaks
- the analyzer warnings get reported, not fixed — list the file, line, and rule so they
  can be handled outside this change

Offer the follow-up as a separate PR. Do not offer to fold it into this one.

---

## 5. PR scope check

Before committing, confirm the diff contains only:

- `.github/workflows/*.yml`
- `pubspec.yaml` (one or more)

```bash
git diff HEAD --name-only
```

Suggested commit/PR message:

```text
chore: bump Flutter to <flutter-version> / Dart to <dart-version>

- Update flutter_version in .github/workflows/ to MAJOR.MINOR.x (CI resolves latest patch)
- Update dart_sdk in .github/workflows/ to the exact Dart patch
- Update environment sdk/flutter constraints in pubspec.yaml

No logic or code changes.
```

Both numbers appear in the subject line because a reviewer scanning history needs to see which
Dart release came with the bump. Fill them from step 0, never from recall.
