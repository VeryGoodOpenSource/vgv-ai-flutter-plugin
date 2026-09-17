#!/usr/bin/env bash
# Recreates the neutral Flutter skeleton in the run's empty workspace.
#
# THE ONLY COPY. Every case's fixture.sh is a symlink to this file, because
# `context.scaffold_script` rejects any path containing `..` but resolves a symlink
# inside the case directory. Edit this file and every case follows.
#
# KEEP THIS NEUTRAL - context, not answers. An empty workspace is its own confound:
# with no project in sight the model asks for code instead of writing it. But the
# pubspec must not list bloc, flutter_bloc, equatable, mocktail or very_good_analysis
# either. An earlier version did, and the no-plugin baseline inferred the conventions
# the cases exist to measure, collapsing bloc's measured lift from +10 points to +1.
set -euo pipefail
mkdir -p lib test
touch lib/.gitkeep test/.gitkeep
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
