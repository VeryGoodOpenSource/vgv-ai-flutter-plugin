# static-security eval notes

## Grading

Mixed grading. Where the skill emits code (`dart_crypt` hashing, `formz` inputs,
`local_auth`) the artifact is graded; where it emits a report (the audit case, the
dependency-scan case) only the narrated decisions are.

The bare model is already security-aware. It flags a hardcoded key, a
`badCertificateCallback` bypass and a token in `SharedPreferences` on its own, so "did it
notice" is worthless here. What it does NOT reach is the skill's specific remedies:
backend-served secrets rather than `--dart-define`, the Critical / Warning / Note triage
tiers, `package:dart_crypt` for passwords, `package:formz` for input,
`package:local_auth` for biometrics, `osv-scanner` for the lockfile. Those are what these
cases grade.

There is no negative grader on `String.fromEnvironment` or `invokeMethod`, even though
the skill forbids both. Its own incorrect examples quote them verbatim while explaining
why they are wrong, so a faithful response contains the string. Those two prohibitions
are judged instead.

Prompts name no skill, so the routing grader catches a routing failure directly. Prompts
are self-contained: the fixture has no source in `lib/`, so the file under review is
pasted into the prompt.

static-security is one of the ten skills added after the measured baseline, so none of
these cases has ever been run. Treat the first run as calibration.

Every case lists graders in this order: routing, mechanical, judged.

## Cases

### static-security-refuses-dart-define-for-secrets

**Measures.** The skill refuses to move a hardcoded key to `--dart-define` and requires
the secret to be served from a backend at runtime.

**Discriminates.** The baseline writes the requested `--dart-define` change and attaches
a caveat, or suggests `.env` / obfuscation / string splitting.

**Grader notes.** `declines-dart-define` is the prohibition itself, from `SKILL.md`:
`--dart-define` / `String.fromEnvironment` "are not a safe alternative to backend-served
secrets." `explains-binary-plaintext` grades the same property on the reason rather than
the refusal.

### static-security-audits-file-with-severity-tiers

**Measures.** A whole-file audit reports findings in the skill's three severity tiers and
gives the skill's fixes: `flutter_secure_storage` for the token, `Random.secure()` for
the session id, backend for the key.

**Discriminates.** The bare model finds the same problems but grades them High / Medium /
Low or by CVSS, and offers `--dart-define` for the key.

**History.** The severity rubric alone was not enough: with five assertions a
High/Medium/Low report failed only that rubric and still averaged 0.8, so the tier check
is also graded mechanically.

**Grader notes.** The middle tier is the tell. `uses-warning-tier` has no trailing `\b` on
`Warning` so a "Warnings" heading counts; `no-medium-tier` uses `\bMedium\b` so it will
not fire on `Durations.medium2`-style text. `severity-tier-vocabulary` grades the triage
vocabulary from the `## Severity Triage` section of `SKILL.md`, which the unaided model
replaces with High/Medium/Low or CVSS. `backend-served-key` is a second grading of the
secrets prohibition, on an audit rather than a refusal.

### static-security-hashes-passwords-with-dart-crypt

**Measures.** Password storage is rewritten onto `package:dart_crypt` with SHA-512-crypt
and verified through `.match(`, per `references/crypto.md`.

**Discriminates.** The unaided model answers bcrypt or argon2, right in general but not
what this skill teaches, so the three regex graders carry the lift.

### static-security-validates-input-with-formz

**Measures.** Form validation goes through a `FormzInput` subclass per field, and submit
reads validated values off state instead of a controller.

**Discriminates.** The baseline hand-rolls a `RegExp` check in the widget or reaches for
a `TextFormField` validator, which leaves the raw controller text as the value that
reaches the API.

**Grader notes.** `formz-input-subclass` and `imports-formz` come from `SKILL.md`: "Use
package:formz for all form validation. Define a FormzInput subclass per field."

### static-security-refuses-platform-channel-biometrics

**Measures.** The skill refuses a hand-written `MethodChannel` for biometrics and routes
the gate through `package:local_auth` instead.

**Discriminates.** The baseline writes the `com.acme/biometrics` MethodChannel as asked.

**Grader notes.** `names-local-auth` and `uses-local-authentication` come from
`references/crypto.md`: "Use package:local_auth ... Do not invoke platform channels
directly."

### static-security-scans-dependencies-before-release

**Measures.** The pre-release dependency check named by the skill: `osv-scanner` over
`pubspec.lock` plus `dart pub outdated`, and an `ignored_advisories` entry challenged for
a written justification.

**Discriminates.** The bare model answers `dart pub outdated` and generic advice, and
accepts the `ignored_advisories` entry as listed.

**Grader notes.** `uses-osv-scanner` and `scans-pubspec-lock` come from `SKILL.md`: "Scan
pubspec.lock with osv-scanner before every release". The lockfile target specifically is
the part the bare model does not produce. `runs-pub-outdated` accepts either prefix: the
pasted pubspec depends on Flutter, and `SKILL.md`'s own verify guidance says to match the
tool to the package, so `flutter pub outdated` is the correct spelling here even though
the checklist writes the `dart` form. Pinning this to `dart` graded the prefix rather than
the step.

### static-security-stays-out-of-plain-formatting-work

**Measures.** A plain string-formatting task does not activate the skill.

**Discriminates.** Nothing else catches a skill firing where it should not. The response
must carry no security review at all: no secure storage, `formz`, `Random.secure`,
`osv-scanner`, `local_auth`, certificate pinning, and no threat-model prose.

**Grader notes.** Task success is graded mechanically by `answers-the-question`, not by
the judge. The judge never sees the prompt, so "did it write the formatter" is
unanswerable from the output alone.

## Dropped in the native migration

The `dart-parses` syntax assertion has no native equivalent and was deleted from:

- static-security-hashes-passwords-with-dart-crypt
- static-security-validates-input-with-formz
- static-security-refuses-platform-channel-biometrics
