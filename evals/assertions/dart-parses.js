/**
 * Checks that every fenced ```dart block in the response is syntactically valid.
 *
 * Uses `dart format --output=none`, which parses without resolving. Snippets
 * reference classes absent from the fixture, so semantic analysis would fail every
 * case. This proves syntax only.
 *
 * A block is tried three ways before it is called a failure, because a snippet can be
 * legitimate Dart without being a compilation unit:
 *
 *   1. as-is                      — `class Foo {}`
 *   2. wrapped in a function body — `ArticleRoute(id).go(context);`
 *   3. wrapped as an expression   — a widget tree pasted with no trailing semicolon,
 *                                   e.g. `AppButton(label: 'Save', onPressed: _save)`
 *
 * Attempt 3 was added after a measured run: three cases failed on responses whose Dart
 * was fine, because a bare widget expression is neither a compilation unit nor a
 * statement, so attempts 1 and 2 both reject it. Without it the assertion punishes a
 * perfectly normal way to show a widget.
 *
 * A missing `dart` binary fails rather than passing quietly.
 */
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const DART_BIN = process.env.VGV_EVAL_DART_BIN || 'dart';
const FENCE = /```dart\s*\n([\s\S]*?)```/gi;

function parses(source, dir, index) {
  // Strip one trailing semicolon for the expression attempt only, so a statement does
  // not become `final _expr = x();;`, which is not valid Dart.
  const asExpression = source.trim().replace(/;$/, '');

  const attempts = [
    ['direct', source],
    ['fragment', `void _fragment() async {\n${source}\n}\n`],
    ['expression', `final _expr = ${asExpression};\n`],
    // A single named argument as it appears inside a constructor call, e.g.
    // `style: FilledButton.styleFrom(...)`. Measured: a real response showed exactly
    // this and the three shapes above all rejected it. Wrapping in a call accepts a
    // named argument or an argument list, including a trailing comma, and still
    // rejects unbalanced delimiters and stray keywords.
    ['argument', `final _arg = _f(\n${asExpression}\n);\n`],
  ];

  for (const [kind, contents] of attempts) {
    const file = path.join(dir, `block-${index}.${kind}.dart`);
    fs.writeFileSync(file, contents);
    try {
      execFileSync(DART_BIN, ['format', '--output=none', file], { stdio: 'ignore' });
      return true;
    } catch {
      // Try the next shape.
    }
  }
  return false;
}

module.exports = (output) => {
  const blocks = [...String(output).matchAll(FENCE)].map((match) => match[1]);

  if (blocks.length === 0) {
    return {
      pass: false,
      score: 0,
      reason: 'No ```dart block in the response, so there is nothing to parse.',
    };
  }

  let dir;
  try {
    dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vgv-dart-parses-'));
  } catch (error) {
    return { pass: false, score: 0, reason: `Could not create a temp dir: ${error.message}` };
  }

  try {
    execFileSync(DART_BIN, ['--version'], { stdio: 'ignore' });
  } catch {
    fs.rmSync(dir, { recursive: true, force: true });
    return {
      pass: false,
      score: 0,
      reason: `'${DART_BIN}' is not on PATH, so the generated Dart could not be parsed.`,
    };
  }

  try {
    const failed = blocks
      .map((source, index) => (parses(source, dir, index) ? null : index + 1))
      .filter((index) => index !== null);

    if (failed.length === 0) {
      return { pass: true, score: 1, reason: `All ${blocks.length} dart block(s) parse.` };
    }
    return {
      pass: false,
      score: 0,
      reason: `${failed.length} of ${blocks.length} dart block(s) did not parse: block ${failed.join(', ')}.`,
    };
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
};
