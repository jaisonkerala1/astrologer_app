import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astrologer_app/shared/widgets/animated_button.dart';

void main() {
  group('AnimatedButton', () {
    testWidgets('renders correctly with text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(AnimatedButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Click Me',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Text might still be in the tree but obscured or next to it, 
      // but usually standard buttons replace text with loader or show next to it.
      // Looking at the implementation:
      // if (widget.isLoading) ... CircularProgressIndicator ...
      // else if (widget.icon != null) ...
      // Text is always rendered in the Row after the conditional part.
      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Click Me',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedButton));
      await tester.pumpAndSettle(); // Allow animation to complete

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when isLoading is true', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              text: 'Click Me',
              isLoading: true,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedButton));
      await tester.pump(const Duration(milliseconds: 200));

      expect(pressed, isFalse);
    });
  });
}

