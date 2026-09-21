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

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### layered-architecture-lays-out-four-layers

**Discriminates.** A bare model proposes a single-package `lib/models`, `lib/services`,
`lib/screens` tree with no `packages/` directory at all.

### layered-architecture-keeps-flutter-out-of-data-packages

**Discriminates.** A bare model reviews the file on other axes, error handling and the
unchecked `jsonDecode` cast, and treats `debugPrint` as harmless.

### layered-architecture-transforms-models-in-the-repository

**Discriminates.** A bare model hands the API response type back to callers, writes a
plain domain class with no value equality, and imports the client by relative path.

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

**Discriminates.** A bare model moves `User` into `user_api_client` as asked, since
sharing one definition does remove duplication.

### layered-architecture-refuses-repository-to-repository-dependency

**Discriminates.** A bare model adds the path dependency to the pubspec as asked.

### layered-architecture-wires-repositories-in-bootstrap

**Discriminates.** A bare model reaches for a service locator or a global singleton, and
lists the repository packages as hosted pub dependencies.

### layered-architecture-stays-out-of-single-file-work

**Discriminates.** No `packages/`, `_api_client`, `_repository` or `RepositoryProvider`
may appear, no restructuring may be proposed, and the skill must not run.
