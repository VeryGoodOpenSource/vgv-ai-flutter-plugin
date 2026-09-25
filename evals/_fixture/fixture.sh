#!/usr/bin/env bash
# Recreates the neutral Flutter skeleton in the run's empty workspace.
#
# THE ONLY COPY. Every case's fixture.sh is a symlink to this file. Edit it here.
#
# KEEP THIS NEUTRAL. Neither the pubspec nor the seeded source may name anything a
# skill teaches: no widget, no bloc, no mocktail, no golden, no pumpApp. The source
# exists so a case that drives the MCP tools has something real on disk, nothing more.
set -euo pipefail
mkdir -p lib test
cat > lib/counter.dart <<'DART'
/// Keeps a running total.
class Counter {
  int _value = 0;

  int get value => _value;

  void add(int amount) => _value += amount;
}
DART
cat > test/counter_test.dart <<'DART'
import 'package:eval_fixture_app/counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('add increases the value', () {
    final counter = Counter();
    counter.add(3);
    expect(counter.value, 3);
  });
}
DART
cat > pubspec.yaml <<'YAML'
name: eval_fixture_app
description: Scratch Flutter app used as working-directory context for behavior evals.
publish_to: none
version: 1.0.0

environment:
  sdk: ^3.12.0

dependencies:
  cupertino_icons: ^1.0.8
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
YAML
