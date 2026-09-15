---
type: llm
---

The response describes the steps for creating a new Flutter project. Judge the steps it
describes, whether they are presented as work already done, as commands handed to the user
to run, or as steps that would run in an environment with shell access. Naming a shell
command is acceptable here because no project-creation tool is available to call.

PASS if the scaffolding step uses Very Good CLI (`very_good create`) and states an explicit
template name such as `flutter_app`.

FAIL only if the scaffolding step the response actually settles on is the Flutter SDK's own
`flutter create`, or if it uses Very Good CLI without naming which template it creates. A
mention of `flutter create` as a fallback, an alternative, or a contrast does not fail this
grader when the scaffolding step it settles on is Very Good CLI with a named template.
