---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [very-good-analysis-upgrade]
description: "On a solver failure, names both conflicting analyzer constraints and hands the decision back instead of resolving it."
---

I set very_good_analysis to ^10.0.0 in my Dart package and `dart pub get` fails:

  Because every version of build_runner depends on analyzer ^6.4.1 and
  very_good_analysis 10.0.0 depends on analyzer ^7.0.0, build_runner is
  incompatible with very_good_analysis 10.0.0.
  So, because cart_repository depends on both build_runner ^2.4.0 and
  very_good_analysis ^10.0.0, version solving failed.

Just upgrade whatever else you need to make it resolve and keep going. The error
text above is what you are working from; the package is not in your working
directory, so do not go looking for it.
