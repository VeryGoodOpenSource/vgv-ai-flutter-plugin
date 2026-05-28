---
name: vgv-very-good-analysis-upgrade
description: Upgrade very_good_analysis lint package to new version across Dart/Flutter projects. Handles version bump, lint fixes, and PR creation.
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

- **Keep the PR focused** — include only the version bump and required lint fixes
- **Fix only new warnings** — do not address pre-existing issues in the same PR
- **Avoid behavior changes** — if a lint fix alters runtime behavior, flag it for review
- **Verify with analysis** — end with a clean `flutter analyze` or `dart analyze`

---

## Before You Start

Confirm two things before proceeding:

1. **Target version** — if the user didn't specify a version, fetch the latest from the pub.dev API
   and use that. Don't ask — just look it up and proceed:

    ```bash
    curl -s https://pub.dev/api/packages/very_good_analysis | jq -r '.latest.version'
    ```

   Tell the user which version you're upgrading to before making any changes.

2. **Project scope** — is this a single package or a monorepo? In a monorepo, each sub-package
   with its own `pubspec.yaml` needs its own bump (and potentially its own PR).

---

## Step 1 — Bump the version in pubspec.yaml

Locate the `pubspec.yaml` file(s) for the project. Update the `very_good_analysis` entry under
`dev_dependencies`:

```yaml
dev_dependencies:
  very_good_analysis: ^x.y.z # replace x.y.z with the target version
```

Keep the caret (`^`) prefix — that's the VGV convention. Don't change anything else in the file.

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
bump. You can often run `flutter analyze` from the repo root to surface all warnings at once,
but `pub get` must be run per-package.

**analysis_options.yaml**: `very_good_analysis` ships its own `analysis_options.yaml` that is
included by the project's own options file. You generally don't need to touch the project's
`analysis_options.yaml` — the bump in `pubspec.yaml` is sufficient to pull in the new rules.

**Breaking rule changes**: Occasionally a new version disables a rule that was previously
enabled, or changes its severity. That might cause previously-flagged issues to disappear,
which is fine — don't re-introduce them.

**flutter pub get fails**: If dependency resolution fails after the bump (version conflicts),
investigate the conflict before proceeding. Don't force-upgrade other dependencies just to
make the bump work — surface the conflict to the user.

---

## Additional Resources

See [reference.md](reference.md) for a quick-reference table of common lint rules introduced by `very_good_analysis` upgrades and their typical fixes (`prefer_const_constructors`, `use_super_parameters`, `unnecessary_late`, `avoid_dynamic_calls`, `require_trailing_commas`, `unnecessary_null_checks`).
