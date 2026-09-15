---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [static-security]
description: "The pre-release dependency check named by the skill: osv-scanner over pubspec.lock plus `dart pub outdated`, and an ignored_advisories entry challenged for a written justification."
---

We cut a release tomorrow. Here is the top of pubspec.yaml:

name: acme_app
publish_to: none
environment:
  sdk: ^3.12.0
ignored_advisories:
  - GHSA-4rgh-jx4f-xxxx
dependencies:
  flutter:
    sdk: flutter
  http: 0.13.0
  flutter_downloader: 1.10.4

How do we check this for known vulnerabilities before we cut the build?
