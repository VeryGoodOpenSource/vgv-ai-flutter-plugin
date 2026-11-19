# Repeating and Looping Animations

## Continuous Rotation (Loading Indicator)

```dart
class _SpinnerState extends State<Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
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
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: child,
        );
      },
      child: const Icon(Icons.refresh),
    );
  }
}
```

## Pulse Animation (Repeat with Reverse)

```dart
@override
void initState() {
  super.initState();
  _controller = AnimationController(
    duration: Durations.long2,
    vsync: this,
  )..repeat(reverse: true);

  _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Easing.standard,
    ),
  );
}
```
