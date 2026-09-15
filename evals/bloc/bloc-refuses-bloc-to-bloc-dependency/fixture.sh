#!/usr/bin/env bash
# Recreates the neutral Flutter skeleton in the run's empty workspace.
#
# CANONICAL COPY. Every case directory holds an identical copy because
# `context.scaffold_script` rejects any path containing `..`. Never edit a case's
# copy: edit this file and run evals/_fixture/sync.sh.
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
