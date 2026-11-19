# Version Solving Conflicts

`pub get` failing after an SDK bump is the normal outcome, not a sign the bump was wrong. This
file covers reading the failure and reporting it. The decision itself does not change: name the
conflict and hand it back, never resolve it by moving another dependency.

## Reading the output

Version solving output names the constraint it could not satisfy. Read it from the bottom up —
the last line is usually the actual conflict, and the lines above it are the search path pub
took to get there.

```text
Because acme_app depends on very_good_analysis >=6.0.0 <7.0.0 which requires SDK version
>=3.5.0 <3.9.0, version solving failed.
```

Three pieces matter, and a useful report has all three:

1. **The blocking package** and the version pub resolved or tried to resolve
2. **The constraint it carries** that clashes, which is often an SDK constraint rather than a
   dependency version
3. **The new constraint** from this bump that it clashes with

From the example above: `very_good_analysis` at `^6.0.0` caps the Dart SDK below `3.9.0`, and
the bump asks for a Dart SDK at or above that. That is the whole finding.

## The three shapes

| Shape                              | What the output shows                                                   | Who owns the fix                                          |
| ---------------------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------- |
| Direct dependency caps the SDK     | A package in `dependencies` or `dev_dependencies` requires an older SDK | The user, in a dependency-bump PR of its own              |
| Transitive dependency caps the SDK | The named package is not in any pubspec                                 | The user, by raising whichever direct dependency pulls it |
| No published version satisfies     | Every version of a package is rejected                                  | The package's maintainer, so the bump is blocked upstream |

The middle one is the one most often misread. When the blocking package is nowhere in the
pubspec, do not add a constraint for it to force resolution. Trace which direct dependency
brought it in and report that instead:

```bash
flutter pub deps --style=tree   # or: dart pub deps --style=tree
```

## What to report

Give the user the four lines they need to open the follow-up PR, and nothing that looks like a
decision you already made on their behalf:

```text
Flutter <target> / Dart <target> does not resolve in packages/cart_repository.

  Blocking package: very_good_analysis ^6.0.0
  Its constraint:   Dart SDK >=3.5.0 <3.9.0
  This bump needs:  Dart SDK ^<target>
  Where it lives:   dev_dependencies in packages/cart_repository/pubspec.yaml

Raising very_good_analysis is a separate PR. This one stays blocked until that lands.
```

In a monorepo, run the check in every package before reporting: a bump can resolve in four
packages and fail in the fifth, and the user needs the whole set rather than the first failure.

## What not to do

- **Do not raise, loosen, or remove the blocking dependency.** A mixed diff cannot be bisected
  when something breaks later, which is the entire reason SDK bumps ship alone
- **Do not delete `pubspec.lock` and retry.** It changes what resolved without recording why,
  and the conflict returns on the next clean checkout
- **Do not widen the new SDK constraint to make it fit.** Writing `>=3.5.0 <4.0.0` instead of
  the pinned caret hides the conflict rather than resolving it, and the CI pin no longer matches
  what the pubspec allows
- **Do not run `pub upgrade --major-versions`.** It resolves the conflict by rewriting
  constraints the PR is not allowed to touch

If the user directs one of these anyway after reading the report, say which of the guarantees
above it gives up, then do it.
