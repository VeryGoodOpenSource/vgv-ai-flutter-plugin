# Staggered Animations

Stagger multiple animations on a single controller using `Interval`. Each interval defines the fraction of the controller's duration during which the animation is active.

## Enter Animation with Staggered Fade + Slide + Scale

```dart
class _StaggeredEntryState extends State<StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Durations.long2,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Easing.standard),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Easing.emphasized),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Easing.emphasized),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
```

## Staggered List Items

Animate list items sequentially by offsetting each item's delay:

```dart
class StaggeredListItem extends StatefulWidget {
  const StaggeredListItem({
    required this.index,
    required this.itemCount,
    required this.animation,
    required this.child,
    super.key,
  });

  final int index;
  final int itemCount;
  final Animation<double> animation;
  final Widget child;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem> {
  late final CurvedAnimation _curvedAnimation;

  @override
  void initState() {
    super.initState();
    final start = (widget.index / widget.itemCount).clamp(0.0, 1.0);
    final end = ((widget.index + 1) / widget.itemCount).clamp(0.0, 1.0);
    _curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(start, end, curve: Easing.emphasized),
    );
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_curvedAnimation),
        child: widget.child,
      ),
    );
  }
}
```

Usage with a parent controller:

```dart
class _StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Durations.extralong2,
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          StaggeredListItem(
            index: i,
            itemCount: items.length,
            animation: _controller,
            child: items[i],
          ),
      ],
    );
  }
}
```
