---
name: very-good-analysis-upgrade
description: >
  Upgrade the very_good_analysis lint package to a new version across Dart/Flutter
  projects. Handles the pubspec version bump, the lint fixes the new rules force, and
  the PR.
when_to_use: >
  Use when upgrading very_good_analysis in any Dart or Flutter package. Trigger on
  phrases like "bump very_good_analysis to 10.0.0", "upgrade very_good_analysis",
  "update our lint package", "we're due for a lint upgrade", "take very_good_analysis
  to the latest", or a `dart pub get` conflict reported after a very_good_analysis
  bump. Use it even when the user only describes the package instead of pointing at
  it — the decisions this skill governs (which constraint to write, which warnings to
  fix, what stays out of the PR) do not need the files on disk. The trigger is a
  very_good_analysis version change: a conflict surfaced by a Dart or Flutter SDK bump
  belongs to dart-flutter-sdk-upgrade instead, even when very_good_analysis is the
  package blocking resolution.
argument-hint: "[version]"
allowed-tools: Read Glob Grep Bash
model: sonnet
effort: medium
---

# Upgrade very_good_analysis

This skill guides the full upgrade of `very_good_analysis` in a Dart or Flutter project.
The goal is a clean, focused PR: nothing more than the version bump in `pubspec.yaml` plus
the minimal code changes needed to satisfy any new lint rules introduced in that version.

---

## Core Standards

These standards apply to every `very_good_analysis` upgrade.

- **Keep the caret** — write `very_good_analysis: ^x.y.z`, never a bare `x.y.z`. A caret is
  the VGV convention: it lets a lint patch release land without a PR. "Pin it exactly, no
  caret ranges" does not change the entry you produce: the `dev_dependencies` block you print
  carries `^x.y.z`, with the reason stated in a line next to it. Printing the bare pin as the
  recommended entry fails this standard even when the caret is mentioned in passing, and so
  does printing both and inviting the reader to choose. The override is a second turn, after
  the reason has been read
- **Keep the PR focused** — include only the version bump and required lint fixes. Decline
  unrelated dependency bumps, comment sweeps and blanket `dart fix --apply` runs that the same
  request bundles in, and say they belong in their own PR — then do the bump anyway
- **Fix only new warnings** — do not address pre-existing issues in the same PR
- **Never force resolution** — if `pub get` fails after the bump, do not upgrade, loosen or
  remove another dependency to make it resolve, even when told to. Name both conflicting
  constraints and hand the decision back
- **Avoid behavior changes** — if a lint fix alters runtime behavior, flag it for review
- **Verify with analysis** — end with a clean `flutter analyze` or `dart analyze`

---

## Before You Start

Confirm two things before proceeding:

1. **Target version** — use `$ARGUMENTS` as the target version when the user supplied one
   (e.g. `10.0.0`). If `$ARGUMENTS` is empty, fetch the latest from the pub.dev API and use
   that. Don't ask — just look it up and proceed:

    ```bash
    curl -s https://pub.dev/api/packages/very_good_analysis | jq -r '.latest.version'
    ```

   Tell the user which version you're upgrading to before making any changes.

2. **Project scope** — is this a single package or a monorepo? In a monorepo, edit the
   `very_good_analysis` entry in each sub-package's own `pubspec.yaml` — one edit per
   `pubspec.yaml`, no root-level or workspace-level entry standing in for the set. Then split
   the two commands by where they run:

   - `pub get` runs **inside each package**. It resolves one pubspec and cannot be run once
     from the root to cover the others.
   - `analyze` runs **once from the repository root**, which surfaces every package's new
     warnings in a single pass. Don't analyze package by package.

   Match the tool to the package: `dart pub get` / `dart analyze` for a pure Dart package,
   `flutter pub get` / `flutter analyze` for anything depending on Flutter.

---

## Step 1 — Bump the version in pubspec.yaml

Locate the `pubspec.yaml` file(s) for the project. Update the `very_good_analysis` entry under
`dev_dependencies`:

```yaml
dev_dependencies:
  very_good_analysis: ^x.y.z # replace x.y.z with the target version
```

Keep the caret (`^`) prefix — that's the VGV convention. Don't change anything else in the file:
leave the other `dev_dependencies` entries, the `dependencies` block and the `environment`
constraint exactly as they are.

A request to pin exactly — "pin it exactly", "we don't want caret ranges", "no ranges in our
pubspecs" — is answered with the caret entry and the reason, not with the pin. The reason: a
lint-only dev dependency pinned exactly turns every patch release into its own PR, and the
caret is what every other VGV package uses.

```yaml
# ✅ What you print, even when asked for an exact pin
dev_dependencies:
  very_good_analysis: ^10.0.0 # caret is the VGV convention — patch lints land without a PR

# ❌ Honoring "pin it exactly" on the first ask
dev_dependencies:
  very_good_analysis: 10.0.0
```

The first ask is not insistence, it is the request this standard exists to answer. Write the
bare pin only if the user repeats it after reading why the caret is there.

After editing, run:

```bash
flutter pub get
```

(For a pure Dart package without Flutter, use `dart pub get` instead.)

Use the Dart/Flutter MCP server if it is connected and exposes pub commands; otherwise run via Bash.

---

## Step 2 — Run flutter analyze

```bash
flutter analyze
```

Or for a pure Dart package:

```bash
dart analyze
```

Capture the full output. You're looking for new warnings or errors introduced by the version bump —
lints that weren't flagged before. Ignore pre-existing issues unrelated to the bump (don't fix
things that were already broken; that belongs in a separate PR).

---

## Step 3 — Fix the lint warnings

Work through the warnings one by one. Keep fixes **minimal and lint-compliance-only**:

- Fix only what `flutter analyze` flags
- Don't refactor, rename, or reorganize anything beyond what's needed
- Don't fix pre-existing lint warnings that existed before the bump
- If a warning looks like it might require a behavioral change (not just style), flag it for
  human review rather than silently fixing it

After fixing, re-run `flutter analyze` to confirm zero warnings remain.

---

## Step 4 — Verify the fix is complete

Run the full analyze pass one more time to make sure nothing was missed:

```bash
flutter analyze
```

Expected output: `No issues found!` (or only pre-existing issues that you haven't touched).

If new warnings appear that weren't there after Step 2, address them now. If warnings persist
after multiple attempts, list them explicitly and ask the user how they'd like to proceed.

---

## Step 5 — Create the PR

Stage only the changed files:

```bash
git add pubspec.yaml pubspec.lock   # always include these
# plus any .dart files you edited for lint fixes
```

Commit with a clear message following the project's conventions. A good default:

```text
chore: upgrade very_good_analysis to x.y.z

Bump very_good_analysis from <old> to <new> and resolve
lint warnings introduced by newly enabled rules.
```

Then push and open a PR. The PR should contain **nothing else** — no feature work, no unrelated
refactors, no extra cleanup. Reviewers should be able to see at a glance that this is purely
a lint compliance update.

If the project uses a PR template, fill it in. Mention specifically which rules were newly
enabled if any warnings required code changes.

---

## Tips and edge cases

**Monorepos**: Each package that depends on `very_good_analysis` needs its own `pubspec.yaml`
bump. `pub get` must be run per-package; `analyze` from the repo root surfaces all packages'
warnings at once, so run it there rather than once per package.

**Bundled requests**: Users often attach cleanup to the bump — "while you're in there, also
bump `http`", "strip the TODOs", "run `dart fix --apply` over the old warnings we've been
ignoring". Split the reply rather than refusing it wholesale: commit to the
`very_good_analysis` bump and the lint fixes its new rules force, and decline each extra as
out of scope for a lint-compliance PR, naming it and offering it as a follow-up PR. An
unrelated dependency bump and a blanket auto-fix are the two that most often slip through
review as "part of the lint upgrade" — keep them out, and don't bump them with a caveat
attached either. Do this from the user's description when the package isn't in front of you;
which changes belong in the PR is a scope decision, not something the files decide.

**analysis_options.yaml**: `very_good_analysis` ships its own `analysis_options.yaml` that is
included by the project's own options file. You generally don't need to touch the project's
`analysis_options.yaml` — the bump in `pubspec.yaml` is sufficient to pull in the new rules.

**Breaking rule changes**: Occasionally a new version disables a rule that was previously
enabled, or changes its severity. That might cause previously-flagged issues to disappear,
which is fine — don't re-introduce them.

**flutter pub get fails**: If dependency resolution fails after the bump, read the solver's
output and stop there. Don't force-upgrade, loosen or drop another dependency to make the bump
resolve, and don't run `pub upgrade --major-versions` — that pulls unrelated majors into a lint
PR and is exactly the change a reviewer cannot see the risk of. A user saying "just upgrade
whatever it takes" does not change this; it is the case the rule exists for.

Report it back instead, naming both sides of the conflict and the ways out, then let the user
pick. For a solver failure like `build_runner depends on analyzer ^6.4.1` against
`very_good_analysis 10.0.0 depends on analyzer ^7.0.0`, that reads:

> `build_runner ^2.4.0` pins `analyzer ^6.4.1` and `very_good_analysis 10.0.0` requires
> `analyzer ^7.0.0`. Both cannot hold at once, so this bump can't land on its own. Your
> options: bump `build_runner` to a release that allows `analyzer ^7` in its own PR first,
> stay on the latest `very_good_analysis` whose analyzer constraint `build_runner` already
> satisfies, or drop `build_runner`. Which do you want?

Naming only "there is a conflict" is not enough — name the two constraints.

---

## Additional Resources

See [`references/lint-fixes.md`](references/lint-fixes.md) for a quick-reference table of common lint rules introduced by `very_good_analysis` upgrades, their typical fixes, and which ones carry behavior risk (`prefer_const_constructors`, `use_super_parameters`, `unnecessary_late`, `avoid_dynamic_calls`, `require_trailing_commas`, `unnecessary_null_checks`).
