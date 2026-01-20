import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/app.dart';
import 'package:openscan/features/camera/domain/camera_permission_service.dart';
import 'package:openscan/features/camera/presentation/providers/camera_permission_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mock implementation of [CameraPermissionService] for widget tests.
class MockCameraPermissionService implements CameraPermissionService {
  MockCameraPermissionService({
    PermissionStatus initialStatus = PermissionStatus.granted,
  }) : _status = initialStatus;

  final PermissionStatus _status;

  @override
  Future<PermissionStatus> checkStatus() async => _status;

  @override
  Future<PermissionStatus> request() async => _status;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<bool> isGranted() async => _status.isGranted;

  @override
  Future<bool> isDenied() async => _status.isDenied;

  @override
  Future<bool> isPermanentlyDenied() async => _status.isPermanentlyDenied;
}

void main() {
  // Create a mock service that returns granted permission for all widget tests.
  final mockPermissionService = MockCameraPermissionService(
    initialStatus: PermissionStatus.granted,
  );

  group('OpenScanApp', () {
    testWidgets('renders app with Camera screen as initial route', (
      WidgetTester tester,
    ) async {
      // Build our app wrapped in ProviderScope and trigger a frame.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(
              mockPermissionService,
            ),
          ],
          child: const OpenScanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the app renders with the Camera screen.
      expect(find.text('Camera'), findsAtLeast(1));
      // With granted permission, we see the placeholder message.
      expect(find.text('Camera Access Granted'), findsOneWidget);
    });

    testWidgets('bottom navigation shows three tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(
              mockPermissionService,
            ),
          ],
          child: const OpenScanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify bottom navigation has all three tabs.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });

    testWidgets('navigating to Gallery tab shows Gallery screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(
              mockPermissionService,
            ),
          ],
          child: const OpenScanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Gallery navigation destination (second one).
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();

      // Verify Gallery screen is shown.
      expect(find.text('View scanned documents'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsAtLeast(1));
    });

    testWidgets('navigating to Settings tab shows Settings screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(
              mockPermissionService,
            ),
          ],
          child: const OpenScanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Settings navigation destination (third one).
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();

      // Verify Settings screen is shown with theme toggle.
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('theme toggle in Settings changes app theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(
              mockPermissionService,
            ),
          ],
          child: const OpenScanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings (third tab).
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();

      // Initially should be in light mode.
      expect(find.text('Light theme enabled'), findsOneWidget);

      // Toggle dark mode.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Should now be in dark mode.
      expect(find.text('Dark theme enabled'), findsOneWidget);
    });

    testWidgets('navigation preserves state when switching tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(
              mockPermissionService,
            ),
          ],
          child: const OpenScanApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to Settings (third tab) and toggle theme.
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify dark mode is enabled.
      expect(find.text('Dark theme enabled'), findsOneWidget);

      // Navigate away to Camera (first tab) and back to Settings.
      await tester.tap(find.byType(NavigationDestination).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();

      // Theme state should be preserved (using Riverpod state).
      expect(find.text('Dark theme enabled'), findsOneWidget);
    });
  });
}
