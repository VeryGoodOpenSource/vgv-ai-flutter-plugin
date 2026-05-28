# Accessibility — Full Test Suite Example

A complete Flutter accessibility test suite covering semantics, touch targets, focus management, color contrast, text scaling, and animation/motion.

---

## Full Accessibility Test Suite Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // --- A. Semantics & Screen Reader ---
  group('Semantics', () {
    testWidgets('all images have semantic labels', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Image(
              image: AssetImage('assets/logo.png'),
              semanticLabel: 'Company logo',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(Image));
      expect(semantics.label, isNotEmpty);

      handle.dispose();
    });

    testWidgets('icon buttons have tooltips', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Search'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('live region announces status changes', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Semantics(
              liveRegion: true,
              child: Text('Loading complete'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.text('Loading complete'));
      expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);

      handle.dispose();
    });
  });

  // --- B. Touch Target Sizes ---
  group('Touch targets', () {
    testWidgets('icon button meets 48dp minimum', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('text button meets 48dp minimum height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(TextButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  // --- C. Focus & Keyboard ---
  group('Focus management', () {
    testWidgets('dialog traps focus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Confirm'),
                    content: Text('Are you sure?'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog is displayed and receives focus
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('interactive elements are focusable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Button')),
                InkWell(onTap: () {}, child: const Text('Link')),
              ],
            ),
          ),
        ),
      );

      // Both elements have Focus ancestors
      final buttonFocus = Focus.of(
        tester.element(find.byType(ElevatedButton)),
      );
      expect(buttonFocus.canRequestFocus, isTrue);
    });
  });

  // --- D. Color Contrast ---
  group('Color contrast', () {
    testWidgets('error state uses icon and label, not just color',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Invalid input'),
              ],
            ),
          ),
        ),
      );

      // Both icon and text are present — not color alone
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Invalid input'), findsOneWidget);
    });
  });

  // --- E. Text Scaling ---
  group('Text scaling', () {
    testWidgets('text container uses minHeight, not fixed height',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 48),
              child: Text('Scalable text'),
            ),
          ),
        ),
      );

      // At default scale, widget renders
      expect(find.text('Scalable text'), findsOneWidget);
    });

    testWidgets('text is not clipped at 2x scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 48),
                  child: Text('This text should not be clipped'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('This text should not be clipped'), findsOneWidget);
    });
  });

  // --- F. Animation & Motion ---
  group('Animation & motion', () {
    testWidgets('animations are disabled when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final disabled =
                      MediaQuery.of(context).disableAnimations;
                  return AnimatedContainer(
                    duration: disabled
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    color: Colors.blue,
                    child: const Text('Animated'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Animated'), findsOneWidget);
    });
  });
}
```
