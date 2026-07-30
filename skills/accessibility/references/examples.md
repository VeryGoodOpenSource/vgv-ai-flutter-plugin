# Accessibility — Extended Examples

Detailed Flutter code examples for every category in the skill: semantics and screen reader, touch targets and dragging alternatives, focus and keyboard navigation (including the new WCAG 2.2 focus-not-obscured rules), color contrast, text scaling, animation and motion, and forms / authentication / help.

The examples in this file cover every WCAG 2.2 criterion the skill checks. Read this file when applying a fix during Phase 4.

---

## Semantics & Screen Reader — Extended Examples

### Custom Semantics for Complex Widgets

```dart
import 'package:flutter/material.dart';

/// A rating bar that provides a single semantic description
/// instead of exposing individual star icons.
class AccessibleRatingBar extends StatelessWidget {
  const AccessibleRatingBar({
    required this.rating,
    required this.maxRating,
    super.key,
  });

  final int rating;
  final int maxRating;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rating: $rating out of $maxRating stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
            );
          }),
        ),
      ),
    );
  }
}
```

### Cupertino Widgets Need Explicit Semantics

Cupertino widgets ship with weaker semantic defaults than their Material equivalents. Always wrap them.

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AccessibleCupertinoSwitch extends StatelessWidget {
  const AccessibleCupertinoSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: value,
      enabled: true,
      child: ExcludeSemantics(
        child: CupertinoSwitch(value: value, onChanged: onChanged),
      ),
    );
  }
}

class AccessibleCupertinoSlider extends StatelessWidget {
  const AccessibleCupertinoSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: value.toStringAsFixed(0),
      slider: true,
      child: ExcludeSemantics(
        child: CupertinoSlider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
```

### MergeSemantics: correct and incorrect usage

```dart
// CORRECT — merge a static label/value pair into one announcement
MergeSemantics(
  child: Row(
    children: [Text(label), Text(value)],
  ),
)

// WRONG — merging an interactive child folds away its role
MergeSemantics(
  child: Row(
    children: [Text(item.name), IconButton(onPressed: _delete, icon: const Icon(Icons.delete))],
  ),
)

// CORRECT — merge only the static content, keep the button independently focusable
Row(
  children: [
    MergeSemantics(child: Row(children: [Text(item.name), Text(item.subtitle)])),
    IconButton(onPressed: _delete, icon: const Icon(Icons.delete), tooltip: 'Delete ${item.name}'),
  ],
)
```

### Live Region for Async Status Updates

```dart
import 'package:flutter/material.dart';

enum UploadStatus { idle, uploading, success, error }

class UploadStatusIndicator extends StatelessWidget {
  const UploadStatusIndicator({required this.status, super.key});

  final UploadStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      UploadStatus.idle => const SizedBox.shrink(),
      UploadStatus.uploading => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      UploadStatus.success => const Icon(Icons.check_circle, color: Colors.green),
      UploadStatus.error => const Icon(Icons.error, color: Colors.red),
    };

    final label = switch (status) {
      UploadStatus.idle => '',
      UploadStatus.uploading => 'Uploading...',
      UploadStatus.success => 'Upload complete',
      UploadStatus.error => 'Upload failed',
    };

    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}
```

For one-shot announcements:

```dart
SemanticsService.announce('Item added to cart', TextDirection.ltr);
```

---

## Touch Targets & Dragging Alternatives — Extended Examples

### Expanding Small Icons to Meet Minimum Size

```dart
import 'package:flutter/material.dart';

/// Wraps any small widget in a minimum 48x48 touch target.
/// 48 is the VGV recommended minimum. The WCAG 2.2 AA floor (2.5.8) is 24.
class AccessibleTapTarget extends StatelessWidget {
  const AccessibleTapTarget({
    required this.onTap,
    required this.semanticLabel,
    required this.child,
    super.key,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// Usage
AccessibleTapTarget(
  onTap: _onClose,
  semanticLabel: 'Close dialog',
  child: const Icon(Icons.close, size: 16),
)
```

### Dismissible With a Non-Drag Alternative (WCAG 2.2 2.5.7)

```dart
class AccessibleDismissibleListItem extends StatelessWidget {
  const AccessibleDismissibleListItem({
    required this.item,
    required this.onDelete,
    super.key,
  });

  final Item item;
  final ValueChanged<Item> onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(color: Colors.red.shade400),
      onDismissed: (_) => onDelete(item),
      child: ListTile(
        title: Text(item.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete ${item.name}',
          onPressed: () => onDelete(item),
        ),
      ),
    );
  }
}
```

### Reorderable List With Up/Down Buttons (WCAG 2.2 2.5.7)

```dart
class AccessibleReorderableList extends StatelessWidget {
  const AccessibleReorderableList({
    required this.items,
    required this.onReorder,
    super.key,
  });

  final List<Item> items;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: items.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;
        return ListTile(
          key: ValueKey(item.id),
          title: Text(item.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Move up',
                onPressed: isFirst ? null : () => onReorder(index, index - 1),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                tooltip: 'Move down',
                // ReorderableListView's onReorder uses index + 1 when moving down
                onPressed: isLast ? null : () => onReorder(index, index + 2),
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
        );
      },
    );
  }
}
```

### Slider With Keyboard Stepping (WCAG 2.2 2.5.7)

Material's `Slider` already responds to arrow keys. Custom slider widgets must do the same.

```dart
class AccessibleSlider extends StatelessWidget {
  const AccessibleSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          tooltip: 'Decrease ${label.toLowerCase()}',
          onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
        ),
        Expanded(
          child: Semantics(
            label: label,
            value: value.toStringAsFixed(0),
            slider: true,
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Increase ${label.toLowerCase()}',
          onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
        ),
      ],
    );
  }
}
```

---

## Focus & Keyboard — Extended Examples

### Custom Focus Traversal for a Form

```dart
import 'package:flutter/material.dart';

class AccessibleForm extends StatelessWidget {
  const AccessibleForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 16),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(height: 24),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Focus Not Obscured: ensureVisible on Sticky-Header Layouts (WCAG 2.2 2.4.11)

```dart
class FocusEnsureVisibleField extends StatefulWidget {
  const FocusEnsureVisibleField({
    required this.label,
    required this.stickyHeaderHeight,
    super.key,
  });

  final String label;
  final double stickyHeaderHeight;

  @override
  State<FocusEnsureVisibleField> createState() => _FocusEnsureVisibleFieldState();
}

class _FocusEnsureVisibleFieldState extends State<FocusEnsureVisibleField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (_focusNode.hasFocus) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Reserve space below the sticky header so the focused field clears it.
      padding: EdgeInsets.only(top: widget.stickyHeaderHeight + 8),
      child: TextField(
        focusNode: _focusNode,
        decoration: InputDecoration(labelText: widget.label),
      ),
    );
  }
}
```

### Focus Appearance at AAA (WCAG 2.2 2.4.13)

```dart
class FocusAppearanceWrap extends StatefulWidget {
  const FocusAppearanceWrap({
    required this.onPressed,
    required this.child,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  State<FocusAppearanceWrap> createState() => _FocusAppearanceWrapState();
}

class _FocusAppearanceWrapState extends State<FocusAppearanceWrap> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusableActionDetector(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            border: Border.all(
              width: _focused ? 2 : 0,
              color: _focused ? scheme.primary : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
```

---

## Color Contrast — Extended Examples

### Contrast-Safe Theme

```dart
import 'package:flutter/material.dart';

ThemeData buildAccessibleTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1565C0),       // Blue 800
    onPrimary: Color(0xFFFFFFFF),     // White, 8.6:1 on primary
    secondary: Color(0xFF00695C),     // Teal 800
    onSecondary: Color(0xFFFFFFFF),   // White, 7.1:1 on secondary
    error: Color(0xFFB71C1C),         // Red 900
    onError: Color(0xFFFFFFFF),       // White, 7.8:1 on error
    surface: Color(0xFFFFFFFF),       // White
    onSurface: Color(0xFF212121),     // Grey 900, 16:1 on white
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    ),
  );
}
```

### Status Indicators Without Color Dependency

```dart
class AccessibleStatusBadge extends StatelessWidget {
  const AccessibleStatusBadge({required this.status, super.key});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      TaskStatus.pending => (Icons.hourglass_empty, 'Pending', Colors.orange),
      TaskStatus.active => (Icons.play_circle, 'Active', Colors.blue),
      TaskStatus.complete => (Icons.check_circle, 'Complete', Colors.green),
      TaskStatus.error => (Icons.error, 'Error', Colors.red),
    };

    // Color is never the sole indicator. Icon + label always present.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

enum TaskStatus { pending, active, complete, error }
```

---

## Text Scaling — Extended Examples

### Adaptive Card Layout (Holds at 2x Android, 3x iOS)

```dart
class AdaptiveInfoCard extends StatelessWidget {
  const AdaptiveInfoCard({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No fixed height. Text grows freely.
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // ConstrainedBox with minHeight, never fixed height.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Animation & Motion — Extended Examples

### Animated Page Transition Respecting Reduced Motion

```dart
import 'package:flutter/material.dart';

class AccessiblePageRoute<T> extends MaterialPageRoute<T> {
  AccessiblePageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return child; // Instant page change
    }
    return super.buildTransitions(context, animation, secondaryAnimation, child);
  }
}
```

### Hero Animation With Reduced-Motion Support

```dart
class AccessibleHero extends StatelessWidget {
  const AccessibleHero({required this.tag, required this.child, super.key});

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }
    return Hero(tag: tag, child: child);
  }
}
```

---

## Forms, Authentication, and Help — Extended Examples

### Redundant Entry: Prefill From Bloc State (WCAG 2.2 3.3.7)

```dart
class CheckoutEmailField extends StatelessWidget {
  const CheckoutEmailField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      buildWhen: (prev, next) => prev.email != next.email,
      builder: (context, state) {
        return TextField(
          controller: TextEditingController(text: state.email),
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (v) => context.read<CheckoutBloc>().add(EmailChanged(v)),
        );
      },
    );
  }
}
```

### Accessible Authentication: Allow Paste, Support Password Managers (WCAG 2.2 3.3.8)

```dart
class AccessiblePasswordField extends StatelessWidget {
  const AccessiblePasswordField({required this.controller, super.key});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      // Default is true. Do not override to false. Paste must work.
      enableInteractiveSelection: true,
      autofillHints: const [AutofillHints.password],
      decoration: const InputDecoration(labelText: 'Password'),
    );
  }
}
```

### Consistent Help: Shared Help Action (WCAG 2.2 3.2.6)

```dart
/// Use this widget on every Scaffold's appBar.actions so the help button
/// always appears in the same relative position across screens.
class ConsistentHelpAction extends StatelessWidget {
  const ConsistentHelpAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'Help',
      onPressed: () => Navigator.of(context).pushNamed('/help'),
    );
  }
}
```

---

## Test Helpers

### Asserting a Semantic Label Is Present

```dart
testWidgets('Close button announces its purpose', (tester) async {
  await tester.pumpWidget(const _Subject());
  expect(find.bySemanticsLabel('Close dialog'), findsOneWidget);
});
```

### Asserting Target Size at AA (WCAG 2.2 2.5.8)

```dart
testWidgets('Icon buttons are >= 24 dp on each axis', (tester) async {
  await tester.pumpWidget(const _Subject());
  final size = tester.getSize(find.byIcon(Icons.close).hitTestable());
  expect(size.width, greaterThanOrEqualTo(24));
  expect(size.height, greaterThanOrEqualTo(24));
});
```

### Asserting Drag Operations Have Alternatives (WCAG 2.2 2.5.7)

```dart
testWidgets('Dismissible exposes a delete button', (tester) async {
  await tester.pumpWidget(const _Subject());
  expect(find.byTooltip('Delete Item one'), findsOneWidget);
});
```

### Asserting Animations Respect disableAnimations

```dart
testWidgets('Hero is skipped when disableAnimations is true', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(accessibleNavigation: true, disableAnimations: true),
      child: const _Subject(),
    ),
  );
  expect(find.byType(Hero), findsNothing);
});
```
