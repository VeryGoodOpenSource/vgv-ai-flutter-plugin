/**
 * Checks that every fenced ```dart block in the response is syntactically valid.
 *
 * Uses `dart format --output=none`, which parses without resolving. Snippets
 * reference classes absent from the fixture, so semantic analysis would fail every
 * case. This proves syntax only.
 *
 * A bare statement like `ArticleRoute(id).go(context);` is valid Dart but not a
 * compilation unit, so a failing block is retried wrapped in a function body.
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
  const direct = path.join(dir, `block-${index}.dart`);
  fs.writeFileSync(direct, source);
  try {
    execFileSync(DART_BIN, ['format', '--output=none', direct], { stdio: 'ignore' });
    return true;
  } catch {
    // Retry as a statement fragment.
    const wrapped = path.join(dir, `block-${index}.fragment.dart`);
    fs.writeFileSync(wrapped, `void _fragment() async {\n${source}\n}\n`);
    try {
      execFileSync(DART_BIN, ['format', '--output=none', wrapped], { stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  }
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
