import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openscan/app.dart';

void main() {
  group('OpenScanApp', () {
    testWidgets('renders app with OpenScan title', (WidgetTester tester) async {
      // Build our app wrapped in ProviderScope and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: OpenScanApp(),
        ),
      );

      // Verify that the app renders with the OpenScan title.
      expect(find.text('OpenScan'), findsAtLeast(1));
    });

    testWidgets('theme toggle button changes theme mode', (
      WidgetTester tester,
    ) async {
      // Build our app wrapped in ProviderScope.
      await tester.pumpWidget(
        const ProviderScope(
          child: OpenScanApp(),
        ),
      );

      // Initially should be in light mode - find dark mode icon (toggle to dark).
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.text('Theme: Light'), findsOneWidget);

      // Tap the theme toggle button.
      await tester.tap(find.byIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      // Should now be in dark mode - find light mode icon (toggle to light).
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.text('Theme: Dark'), findsOneWidget);
    });
  });
}
