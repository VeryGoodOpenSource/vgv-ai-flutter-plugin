# layered-architecture eval notes

## Grading

Most of what this skill produces is structure rather than code: which package a file
belongs in, which direction a dependency points, what the pubspec references. So `llm`
graders carry these cases, and every criterion has to be answerable from the response
text alone, because the judge never sees the prompt. The two prohibition cases are
judge-only by nature, because a refusal emits no code to match.

What cannot be measured here: whether the packages build, whether the path dependencies
resolve, whether the `create dart_package` scaffolding runs.

One trap specific to this file is routing. A prompt phrased as plain code review does not
reliably reach the skill, so prompts here say "data layer package", "monorepo" or "layer
boundaries" on purpose. See the history note on
layered-architecture-keeps-flutter-out-of-data-packages.

Measured under the previous harness, first full run: 6/6 with the plugin against 0/6 without it, negative
control excluded because a model with no plugin passes the negative routing grader for free.

Every case lists graders in this order: routing, mechanical, judged.

## Cases

### layered-architecture-lays-out-four-layers

**Measures.** The four-layer layout from one line of app description: data and repository
as packages, business logic and presentation in `lib/`, and each layer depending only on
the one beneath it.

**Discriminates.** A bare model proposes a single-package `lib/models`, `lib/services`,
`lib/screens` tree with no `packages/` directory at all.

### layered-architecture-keeps-flutter-out-of-data-packages

**Measures.** Whether the `package:flutter` import in a data package is named as the
boundary violation, and removed rather than worked around.

**Discriminates.** A bare model reviews the file on other axes, error handling and the
unchecked `jsonDecode` cast, and treats `debugPrint` as harmless.

**History.** The prompt says "data layer package" and "layer boundaries" on purpose.
Phrased as plain code review it routed to no skill on roughly half of runs, which made
the case flaky rather than wrong: both judged graders passed either way.

### layered-architecture-transforms-models-in-the-repository

**Measures.** Repository-layer code: the data client injected through the constructor,
the API response transformed into an Equatable domain model, and both files placed in the
repository package, which reaches the data package through its barrel export.

**Discriminates.** A bare model hands the API response type back to callers, writes a
plain domain class with no value equality, and imports the client by relative path.

**History.** Asking where each file goes is what makes the layer boundary gradeable.
Under "Output Dart code only" alone, both columns returned one correct-looking snippet
with no package context: the two surviving judged criteria passed in the no-plugin arm
too, and the third, whether the domain model belongs to the repository package, was
unanswerable from the text and failed in the plugin column for that reason. Measured, the
no-plugin arm wrote a plain `class Weather` with no value equality and reached for a
same-directory `import 'weather_api_client.dart';`.

**Grader notes.** `domain-model-extends-equatable` enforces "Domain models extend
Equatable and represent the app's internal data shape." `repository-package-path` grades
placement mechanically now that the prompt asks for paths: the domain model and the
repository live in the repository package, not the data package.
`imports-data-package-barrel` is anchored on `import '` rather than on the bare
`package:weather_api_client/...` form. That anchoring was a workaround for the previous harness, because
the previous harness read a value starting with `package:` as an npm assertion and errored the whole
case. Native has no such rule, and the pattern is kept unchanged only to preserve the
assertion exactly.

### layered-architecture-refuses-domain-model-in-data-layer

**Measures.** The prohibition on domain models in the data layer, and whether the refusal
comes with the response-model / domain-model split.

**Discriminates.** A bare model moves `User` into `user_api_client` as asked, since
sharing one definition does remove duplication.

### layered-architecture-refuses-repository-to-repository-dependency

**Measures.** The no-inter-repository-dependency rule, and the redirect to combining the
two repositories' data at the business logic layer.

**Discriminates.** A bare model adds the path dependency to the pubspec as asked.

### layered-architecture-wires-repositories-in-bootstrap

**Measures.** Bootstrap wiring: clients and repositories constructed in a main
entrypoint, passed into `App`, provided to the tree, and depended on by path rather than
by version.

**Discriminates.** A bare model reaches for a service locator or a global singleton, and
lists the repository packages as hosted pub dependencies.

### layered-architecture-stays-out-of-single-file-work

**Measures.** That a one-line loop fix stays a one-line loop fix. Nothing else catches
this skill firing where it should not.

**Discriminates.** No `packages/`, `_api_client`, `_repository` or `RepositoryProvider`
may appear, no restructuring may be proposed, and the skill must not run.

**History.** Both columns once returned byte-identical correct output here and the judge
scored one 1.0 and the other 0.3, because "does this fix the loop bound" cannot be
answered without the prompt the judge never receives. Task success is the
`fixes-loop-bound` regex for that reason.

## Dropped in the native migration

The `dart-parses` syntax assertion has no native equivalent and was deleted from:

- layered-architecture-transforms-models-in-the-repository
