import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/camera/presentation/widgets/camera_controls_bar.dart';
import 'package:openscan/features/camera/presentation/widgets/camera_flip_button.dart';
import 'package:openscan/features/camera/presentation/widgets/flash_toggle_button.dart';

void main() {
  group('FlashToggleButton', () {
    testWidgets('shows flash_off icon when flash is off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashToggleButton(
              flashMode: FlashMode.off,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('shows flash_auto icon when flash is auto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashToggleButton(
              flashMode: FlashMode.auto,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_auto), findsOneWidget);
    });

    testWidgets('shows flash_on icon when flash is always', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashToggleButton(
              flashMode: FlashMode.always,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('shows flash_on icon when flash is torch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashToggleButton(
              flashMode: FlashMode.torch,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Torch mode uses flash_on icon, same as always mode
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashToggleButton(
              flashMode: FlashMode.auto,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FlashToggleButton));
      expect(pressed, true);
    });
  });

  group('CameraFlipButton', () {
    testWidgets('shows flip_camera_ios icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraFlipButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped and canFlip is true',
        (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraFlipButton(
              onPressed: () => pressed = true,
              canFlip: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CameraFlipButton));
      expect(pressed, true);
    });

    testWidgets('does not call onPressed when canFlip is false',
        (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraFlipButton(
              onPressed: () => pressed = true,
              canFlip: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CameraFlipButton));
      expect(pressed, false);
    });

    testWidgets('shows reduced opacity icon when canFlip is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraFlipButton(
              onPressed: () {},
              canFlip: false,
            ),
          ),
        ),
      );

      // The icon color should be white38 when disabled
      final iconFinder = find.byType(Icon);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.white38);
    });

    testWidgets('shows full opacity icon when canFlip is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraFlipButton(
              onPressed: () {},
              canFlip: true,
            ),
          ),
        ),
      );

      final iconFinder = find.byType(Icon);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.white);
    });
  });

  group('CameraControlsBar', () {
    testWidgets('renders all controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              onCapture: () {},
              onFlashToggle: () {},
              onCameraFlip: () {},
              flashMode: FlashMode.auto,
            ),
          ),
        ),
      );

      // Flash toggle button
      expect(find.byType(FlashToggleButton), findsOneWidget);

      // Capture button - find by the container size
      expect(find.byType(GestureDetector), findsWidgets);

      // Camera flip button
      expect(find.byType(CameraFlipButton), findsOneWidget);
    });

    testWidgets('calls onCapture when capture button pressed', (tester) async {
      var captured = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              onCapture: () => captured = true,
              onFlashToggle: () {},
              onCameraFlip: () {},
              flashMode: FlashMode.auto,
            ),
          ),
        ),
      );

      // Find the capture button by its distinctive size (72x72)
      final captureButton = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 72 &&
            widget.constraints?.maxHeight == 72,
      );

      // If not found by Container, try finding by the circular shape
      if (captureButton.evaluate().isEmpty) {
        // Find the center GestureDetector (capture button)
        final gestureDetectors = find.byType(GestureDetector);
        await tester.tap(gestureDetectors.at(1)); // Middle button is capture
      } else {
        await tester.tap(captureButton);
      }

      await tester.pump();
      expect(captured, true);
    });

    testWidgets('calls onFlashToggle when flash button pressed',
        (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              onCapture: () {},
              onFlashToggle: () => toggled = true,
              onCameraFlip: () {},
              flashMode: FlashMode.auto,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FlashToggleButton));
      expect(toggled, true);
    });

    testWidgets('calls onCameraFlip when flip button pressed', (tester) async {
      var flipped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              onCapture: () {},
              onFlashToggle: () {},
              onCameraFlip: () => flipped = true,
              flashMode: FlashMode.auto,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CameraFlipButton));
      expect(flipped, true);
    });

    testWidgets('disables flip button when canFlip is false', (tester) async {
      var flipped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              onCapture: () {},
              onFlashToggle: () {},
              onCameraFlip: () => flipped = true,
              flashMode: FlashMode.auto,
              canFlip: false,
            ),
          ),
        ),
      );

      // Tap should not trigger callback when canFlip is false
      await tester.tap(find.byType(CameraFlipButton));
      expect(flipped, false);
    });

    testWidgets('has semi-transparent black background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              onCapture: () {},
              onFlashToggle: () {},
              onCameraFlip: () {},
              flashMode: FlashMode.auto,
            ),
          ),
        ),
      );

      // Find the ColoredBox that is a direct descendant of CameraControlsBar
      final controlsBarFinder = find.byType(CameraControlsBar);
      final coloredBoxFinder = find.descendant(
        of: controlsBarFinder,
        matching: find.byType(ColoredBox),
      );

      expect(coloredBoxFinder, findsWidgets);

      // Find the ColoredBox with semi-transparent black background
      var foundSemiTransparentBlack = false;
      for (final element in coloredBoxFinder.evaluate()) {
        final coloredBox = element.widget as ColoredBox;
        final color = coloredBox.color;
        final a = (color.a * 255.0).round();
        // The semi-transparent one should have alpha around 128
        if (a > 100 && a < 150) {
          // Verify it's black
          final r = (color.r * 255.0).round();
          final g = (color.g * 255.0).round();
          final b = (color.b * 255.0).round();
          if (r == 0 && g == 0 && b == 0) {
            foundSemiTransparentBlack = true;
            break;
          }
        }
      }

      expect(foundSemiTransparentBlack, true,
          reason: 'Controls bar should have semi-transparent black background');
    });
  });
}
