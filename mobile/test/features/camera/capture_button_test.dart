import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/camera/presentation/widgets/capture_button.dart';

void main() {
  group('CaptureButton', () {
    testWidgets('triggers onPressed callback when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CaptureButton(
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CaptureButton));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('ignores taps when isCapturing is true', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CaptureButton(
                onPressed: () => pressed = true,
                isCapturing: true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CaptureButton));
      await tester.pump();

      expect(pressed, false);
    });

    testWidgets('displays loading indicator when isCapturing is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CaptureButton(
                onPressed: () {},
                isCapturing: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not display loading indicator when not capturing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CaptureButton(
                onPressed: () {},
                isCapturing: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('has correct size (72x72)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CaptureButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CaptureButton),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.constraints?.maxWidth, 72);
      expect(container.constraints?.maxHeight, 72);
    });

    testWidgets('renders with white circular background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CaptureButton(
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CaptureButton),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.shape, BoxShape.circle);
      expect(decoration?.color, Colors.white);
    });
  });
}
