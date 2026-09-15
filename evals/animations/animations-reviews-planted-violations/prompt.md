---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [animations]
description: Review mode over four planted violations, the hardcoded duration and curve, the wrong ticker mixin, the per-frame rebuild, and the animated width.
---

Review the animation code in this widget and list what is wrong with it.

class _PromoCardState extends State<PromoCard>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 375),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 200 + (_controller.value * 120),
          child: Opacity(
            opacity: Curves.easeInOutCubic.transform(_controller.value),
            child: const ExpensiveChart(),
          ),
        );
      },
    );
  }
}
