---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [animations]
description: A custom route transition goes through a buildPage override returning CustomTransitionPage, curved with an emphasized easing.
---

Routes in my app are declared with go_router's GoRouteData. Here is one:

@TypedGoRoute<DetailsRoute>(path: 'details/:id')
class DetailsRoute extends GoRouteData {
  const DetailsRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DetailsPage(id: id);
  }
}

Give this page a fade-and-slide-up entrance instead of the default platform
transition. Output Dart code only.
