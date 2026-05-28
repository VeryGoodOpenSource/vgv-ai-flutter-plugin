# Accessibility — Extended Examples

Detailed code examples for each accessibility category: semantics and screen readers, touch target sizes, focus and keyboard navigation, color contrast, text scaling, and animation and motion.

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

### Live Region for Async Status Updates

```dart
import 'package:flutter/material.dart';

enum UploadStatus { idle, uploading, success, error }

class UploadStatusIndicator extends StatelessWidget {
  const UploadStatusIndicator({
    required this.status,
    super.key,
  });

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
      UploadStatus.success =>
        const Icon(Icons.check_circle, color: Colors.green),
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
        children: [
          icon,
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
```

---

## Touch Target Sizes — Extended Examples

### Expanding Small Icons to Meet Minimum Size

```dart
import 'package:flutter/material.dart';

/// Wraps any small widget in a minimum 48x48 touch target.
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
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
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
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 16),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
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

---

## Color Contrast — Extended Examples

### Building a Contrast-Safe Theme

```dart
import 'package:flutter/material.dart';

/// All color pairings maintain WCAG AA contrast ratios.
ThemeData buildAccessibleTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1565C0),       // Blue 800
    onPrimary: Color(0xFFFFFFFF),     // White — 8.6:1 on primary
    secondary: Color(0xFF00695C),     // Teal 800
    onSecondary: Color(0xFFFFFFFF),   // White — 7.1:1 on secondary
    error: Color(0xFFB71C1C),         // Red 900
    onError: Color(0xFFFFFFFF),       // White — 7.8:1 on error
    surface: Color(0xFFFFFFFF),       // White
    onSurface: Color(0xFF212121),     // Grey 900 — 16:1 on white
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
import 'package:flutter/material.dart';

class AccessibleStatusBadge extends StatelessWidget {
  const AccessibleStatusBadge({
    required this.status,
    super.key,
  });

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      TaskStatus.pending => (Icons.hourglass_empty, 'Pending', Colors.orange),
      TaskStatus.active => (Icons.play_circle, 'Active', Colors.blue),
      TaskStatus.complete => (Icons.check_circle, 'Complete', Colors.green),
      TaskStatus.error => (Icons.error, 'Error', Colors.red),
    };

    // Color is NEVER the sole indicator — icon + label always present
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

### Adaptive Card Layout

```dart
import 'package:flutter/material.dart';

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
            // No fixed height — text grows freely
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // ConstrainedBox with minHeight, never fixed height
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
  AccessiblePageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration {
    // When called before the route is installed, navigator may be null.
    // Default to the standard duration; didChangeDependencies will
    // handle the disableAnimations check once the context is available.
    return const Duration(milliseconds: 300);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return child; // No transition — instant page change
    }
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
```

### Hero Animation with Reduced-Motion Support

```dart
import 'package:flutter/material.dart';

class AccessibleHero extends StatelessWidget {
  const AccessibleHero({
    required this.tag,
    required this.child,
    super.key,
  });

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations) {
      return child; // Skip Hero animation entirely
    }

    return Hero(
      tag: tag,
      child: child,
    );
  }
}
```
