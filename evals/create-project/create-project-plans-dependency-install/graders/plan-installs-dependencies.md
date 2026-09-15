---
type: llm
---

The response describes the steps for creating a new Flutter project. Judge the steps it
describes, whether they are presented as work already done, as commands handed to the user
to run, or as steps that would run in an environment with shell access. A response that
says it cannot execute the steps itself is still judged on the steps it lists.

PASS if the described steps include installing dependencies after the project is created,
for example a `very_good packages get` or `flutter pub get` step that follows the creation
step.

FAIL if the described steps contain no dependency install after the creation step. It
does not matter what else follows creation: a plan that goes straight from creating the
project to running or editing it, with no install anywhere, fails.
