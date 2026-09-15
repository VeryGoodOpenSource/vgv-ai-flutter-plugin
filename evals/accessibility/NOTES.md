# accessibility eval notes

## Grading

Mixed grading. `accessibility-wraps-cupertino-and-announces-on-ios` and
`accessibility-adds-non-drag-alternative-to-dismissible` are graded on the artifact,
because they ask for a widget class. The first four cases are graded on what the response
narrates, the question it asks, the report it writes, the request it declines.

Prompts name no skill, so the routing grader catches a routing failure directly.

Prompts are self-contained. The fixture has no source in `lib/`, so a prompt about "my
SettingsView" earns a refusal and every grader fails for an unrelated reason. The widget
under audit is pasted in.

Phases 1 and 2 of the workflow call `AskUserQuestion`, which neither arm exposes, since
`allowed_tools` is `Read, Glob, Grep, Skill`. So the level-and-platform gate is graded on
the question the response *narrates* in text, not on a tool call, the same treatment the
MCP-backed skills get.

Most cases state the WCAG level and the platforms up front. Without them the skill
correctly stops at Phase 1 and asks, which would leave nothing to grade in the
remediation cases. Exactly one case,
`accessibility-asks-level-and-platform-before-auditing`, omits them on purpose, to grade
the gate.

WCAG criterion IDs are graded mechanically, `2.5.8`, `2.1.1` and so on, because Core
Standards pins a specific ID to each rule, and the without-arm tends to answer in generic
"add a label" prose without citing WCAG 2.2 at all.

Every case orders its assertions routing, then mechanical, then judged. Grader files
carry no order of their own, so that ordering survives only here.

## Cases

### accessibility-asks-level-and-platform-before-auditing

**Measures.** The Phase 1 and Phase 2 gate. Level and platforms are withheld, so the
skill must ask both before auditing. SKILL.md says "Never assume AA" and "Begin every
audit by asking which of the six platforms are targeted".

**Discriminates.** An unaided model assumes AA, audits the widget on the spot, and talks
about iOS and Android only. `AA + selected AAA` is verbatim from the Phase 1 option list
and is not phrasing a bare model volunteers.

**Notes.** `names-linux-platform` grades the six-platform list from Phase 2. Linux is the
tell, because an unaided answer talks about iOS and Android, not about Orca on Linux
desktop.

### accessibility-audits-with-criterion-ids-and-severities

**Measures.** Level and platforms are supplied, so the skill proceeds to Phase 3 and must
emit the report shape from `references/audit-templates.md`, per finding a WCAG ID plus
name plus level, a CRITICAL/MAJOR/MINOR severity from the severity guide, and a
before/after fix. The 16x16 close button is the 2.5.8 Target Size (Minimum) violation,
and its GestureDetector is 2.1.1.

**Discriminates.** An unaided model returns generic "add a label" prose with no WCAG 2.2
IDs, and grades severity as High/Medium/Low or axe-style Serious/Moderate rather than the
skill's three labels.

**History.** Measured at 0.75 with routing and all three regex assertions passing: the
report cited `2.1.1`, `2.5.8` and `CRITICAL`, but the two per-finding rubrics failed, so
some findings carried a bare criterion number or a prose-only fix. The finding shape lived
only in `references/audit-templates.md`, which a Read/Glob/Grep run may never load, and
SKILL.md compressed it into one clause of Phase 3. Phase 3 now carries the finding block
inline with its four per-finding rules, and Core Standards carries a `Finding Format` rule.
Both rubrics were left alone; neither rejects a correct answer.

**Notes.** `uses-critical-severity-label` grades the upper-case severity labels, which are
the skill's own vocabulary, from the severity guide in `references/audit-templates.md`.

### accessibility-declines-gesture-detector-tap-target

**Measures.** The skill's flagship prohibition, "Never use bare GestureDetector for tap
targets ... GestureDetector is pointer-only and unreachable via keyboard or switch
access." The prompt asks for it by name and supplies a plausible excuse, so complying is
the failure mode.

**Discriminates.** An unaided model obliges the request, ships the GestureDetector version
as its recommendation with at most a passing caveat, and never cites 2.1.1 Keyboard as
the criterion being broken.

**Notes.** `names-accessible-tap-widget` is the documented replacement list from the
Gesture Detector core standard.

### accessibility-declines-exclude-semantics-on-actionable-content

**Measures.** The second prohibition, "Never use ExcludeSemantics on non-decorative
content", plus the MergeSemantics correctness rule from `references/examples.md`, to merge
the static label and value pair only and keep the interactive child independently
focusable.

**Discriminates.** An unaided model either complies with the ExcludeSemantics request or
merges the whole Row, folding the button's role away.

**History.** The pasted row used to hold a single `Text('Total: 42.00 USD')`, which made
the case unmeasurable two ways. Nothing was there to group, so the alternative rubric
asked for a pattern the widget could not carry, and the with-plugin arm diagnosed the
premise as false, asked for the parent widget and failed that rubric. The refusal alone is
also baseline behavior. The without-arm declined ExcludeSemantics, gave the reason and
cited 4.1.2 unaided. The row now carries a real label and value pair, the exact shape
`references/examples.md` marks CORRECT. The criterion-ID regex is gone because it was a
measured free point in both arms, and criterion IDs are already graded in three other
cases here.

**Notes.** `fix-uses-merge-semantics` includes the opening paren, so the fix has to arrive
as code. The without-arm named MergeSemantics in prose, as a possible cause rather than
the fix.

### accessibility-wraps-cupertino-and-announces-on-ios

**Measures.** iOS-specific remediation on two skill facts, the Cupertino Semantics core
standard ("Cupertino widgets ship with weaker semantic defaults ... Always wrap them in
Semantics(label:, value:, button:)") and the iOS reference's gotcha that `liveRegion: true`
does not auto-announce on iOS, Flutter issue #45968, so SemanticsService.announce is
required as well.

**Discriminates.** An unaided model adds liveRegion and treats it as sufficient, and
either leaves the CupertinoSwitch bare or swaps it for a Material Switch instead of
wrapping it.

### accessibility-adds-non-drag-alternative-to-dismissible

**Measures.** WCAG 2.2 criterion 2.5.7, "Every dragging-based function must offer a
non-drag alternative on the same screen. `Dismissible` needs an explicit delete button."
The pattern in `references/examples.md` keeps the Dismissible and adds a tooltipped
IconButton in the ListTile's trailing slot.

**Discriminates.** Only the criterion ID separates the arms here. A bare model reaches the
Dismissible-plus-trailing-IconButton shape on its own but does not name the criterion it
is remediating. The skill does, everywhere.

**History.** Measured: every assertion except the `2.5.7` regex passed with no plugin
loaded. An earlier version with only `IconButton` plus the rubric let a response that
deleted the swipe and shipped a button alone score 0.8 and pass, so `keeps-the-dismissible`
grades that property a second time. "Output Dart code only" still leaves a doc comment on
the widget class for the criterion ID to live in.

**Notes.** `keeps-the-dismissible` exists because the reference pattern keeps the
Dismissible and adds the button beside it, so the swipe must survive the fix.
`labels-the-alternative-control` exists because an icon-only control needs a Tooltip or
Semantics label of its own, from the Icon Buttons core standard and WCAG 4.1.2.
`cites-2-5-7-dragging-movements` is the one assertion the without-arm misses, since Core
Standards pins 2.5.7 to drag alternatives and `references/examples.md` titles the pattern
with it.

### accessibility-stays-out-of-plain-dart-work

**Measures.** Routing restraint. A pure Dart string formatter with no widgets in sight
must not pull the skill in. Nothing else catches a skill firing where it should not.

**Discriminates.** What must not appear is the skill firing at all, and any Semantics,
semanticLabel, WCAG, screen-reader or accessibility vocabulary in an mm:ss formatter.

**Notes.** `answers-the-question` grades task success mechanically rather than by the
judge. The judge never sees the prompt, so "did it answer the question" is unanswerable
from the output alone.

## Dropped in the native migration

Native plugin evals have no custom-code graders, so the `dart-parses` syntax check has no
equivalent. It was deleted with no replacement. Two cases lost it:

- `accessibility-wraps-cupertino-and-announces-on-ios`
- `accessibility-adds-non-drag-alternative-to-dismissible`

Three further cases carried a note explaining why they omitted `dart-parses` on purpose,
namely that their answers are before/after fragments and a bare widget expression with no
trailing semicolon does not parse even wrapped in a function body:
`accessibility-audits-with-criterion-ids-and-severities`,
`accessibility-declines-gesture-detector-tap-target` and
`accessibility-declines-exclude-semantics-on-actionable-content`. No case carries the
check now, so that explanation is stale and is recorded here rather than per case.
