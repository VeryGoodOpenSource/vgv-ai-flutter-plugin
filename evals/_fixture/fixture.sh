#!/usr/bin/env bash
# Recreates the neutral Flutter skeleton in the run's empty workspace.
#
# THE ONLY COPY. Every case's fixture.sh is a symlink to this file. Edit it here.
#
# KEEP THIS NEUTRAL. The pubspec must not name anything a skill teaches.
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
