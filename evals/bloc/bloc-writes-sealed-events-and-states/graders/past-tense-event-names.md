---
type: llm
---

Judge only the concrete event subclasses: the classes that extend the sealed event base
class. Ignore the sealed base class itself (for example `LoginEvent`), every state class,
and the bloc class. None of those are judged here.

PASS if every concrete event subclass name starts with the bloc's subject and ends in a
past-tense verb. `LoginSubmitted`, `LoginLogoutRequested`, `LoginFormSubmitted` and
`LoginEmailChanged` all pass. A name does not need three separate word parts, and the
verb does not have to end in `-ed`.

FAIL only if at least one concrete event subclass name is imperative, such as
`SubmitLogin`, or present-tense, such as `LoginSubmit`, or omits the bloc's subject, such
as `Submitted` or `LogoutRequested`.
