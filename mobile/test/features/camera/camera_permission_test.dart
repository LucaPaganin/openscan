import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/camera/domain/camera_permission_service.dart';
import 'package:openscan/features/camera/presentation/providers/camera_permission_provider.dart';
import 'package:openscan/features/camera/presentation/screens/camera_screen.dart';
import 'package:openscan/features/camera/presentation/widgets/camera_permission_denied_view.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mock implementation of [CameraPermissionService] for testing.
class MockCameraPermissionService implements CameraPermissionService {
  MockCameraPermissionService({
    PermissionStatus initialStatus = PermissionStatus.denied,
  }) : _status = initialStatus;

  final PermissionStatus _status;
  bool _settingsOpened = false;

  @override
  Future<PermissionStatus> checkStatus() async => _status;

  @override
  Future<PermissionStatus> request() async => _status;

  @override
  Future<bool> openSettings() async {
    _settingsOpened = true;
    return true;
  }

  @override
  Future<bool> isGranted() async => _status.isGranted;

  @override
  Future<bool> isDenied() async => _status.isDenied;

  @override
  Future<bool> isPermanentlyDenied() async => _status.isPermanentlyDenied;

  bool get settingsOpened => _settingsOpened;
}

void main() {
  group('CameraPermissionService', () {
    test('checkStatus returns granted when permission is granted', () async {
      final service = MockCameraPermissionService(
        initialStatus: PermissionStatus.granted,
      );

      final status = await service.checkStatus();

      expect(status, PermissionStatus.granted);
    });

    test('checkStatus returns denied when permission is denied', () async {
      final service = MockCameraPermissionService(
        initialStatus: PermissionStatus.denied,
      );

      final status = await service.checkStatus();

      expect(status, PermissionStatus.denied);
    });

    test(
      'checkStatus returns permanentlyDenied when permission is permanently denied',
      () async {
        final service = MockCameraPermissionService(
          initialStatus: PermissionStatus.permanentlyDenied,
        );

        final status = await service.checkStatus();

        expect(status, PermissionStatus.permanentlyDenied);
      },
    );

    test('openSettings returns true and marks settings as opened', () async {
      final service = MockCameraPermissionService();

      expect(service.settingsOpened, false);

      final result = await service.openSettings();

      expect(result, true);
      expect(service.settingsOpened, true);
    });
  });

  group('CameraPermissionDeniedView', () {
    testWidgets('displays permission denied message and Grant Access button', (
      tester,
    ) async {
      var actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraPermissionDeniedView(
              onActionPressed: () => actionPressed = true,
              isPermanentlyDenied: false,
            ),
          ),
        ),
      );

      // Verify the message is displayed
      expect(find.text('Camera Access Required'), findsOneWidget);
      expect(
        find.textContaining('OpenScan needs camera access'),
        findsOneWidget,
      );

      // Verify Grant Access button is displayed
      expect(find.text('Grant Access'), findsOneWidget);
      expect(find.text('Open Settings'), findsNothing);

      // Tap the button and verify callback is triggered
      await tester.tap(find.text('Grant Access'));
      await tester.pump();

      expect(actionPressed, true);
    });

    testWidgets(
      'displays permanently denied message and Open Settings button',
      (tester) async {
        var actionPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CameraPermissionDeniedView(
                onActionPressed: () => actionPressed = true,
                isPermanentlyDenied: true,
              ),
            ),
          ),
        );

        // Verify the permanently denied message is displayed
        expect(find.text('Camera Access Required'), findsOneWidget);
        expect(
          find.textContaining('Please enable it in Settings'),
          findsOneWidget,
        );

        // Verify Open Settings button is displayed
        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Grant Access'), findsNothing);

        // Tap the button and verify callback is triggered
        await tester.tap(find.text('Open Settings'));
        await tester.pump();

        expect(actionPressed, true);
      },
    );
  });

  group('CameraPermissionProvider', () {
    test(
      'maps PermissionStatus.granted to CameraPermissionState.granted',
      () async {
        final mockService = MockCameraPermissionService(
          initialStatus: PermissionStatus.granted,
        );

        final container = ProviderContainer(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        // Wait for the provider to initialize
        await container.read(cameraPermissionProvider.future);

        final state = container.read(cameraPermissionProvider);

        expect(state.value, CameraPermissionState.granted);
      },
    );

    test(
      'maps PermissionStatus.denied to CameraPermissionState.denied',
      () async {
        final mockService = MockCameraPermissionService(
          initialStatus: PermissionStatus.denied,
        );

        final container = ProviderContainer(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        await container.read(cameraPermissionProvider.future);

        final state = container.read(cameraPermissionProvider);

        expect(state.value, CameraPermissionState.denied);
      },
    );

    test(
      'maps PermissionStatus.permanentlyDenied to CameraPermissionState.permanentlyDenied',
      () async {
        final mockService = MockCameraPermissionService(
          initialStatus: PermissionStatus.permanentlyDenied,
        );

        final container = ProviderContainer(
          overrides: [
            cameraPermissionServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        await container.read(cameraPermissionProvider.future);

        final state = container.read(cameraPermissionProvider);

        expect(state.value, CameraPermissionState.permanentlyDenied);
      },
    );
  });

  group('CameraScreen', () {
    testWidgets(
      'shows camera loading view when permission is granted',
      (tester) async {
        final mockService = MockCameraPermissionService(
          initialStatus: PermissionStatus.granted,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cameraPermissionServiceProvider.overrideWithValue(mockService),
            ],
            child: const MaterialApp(home: CameraScreen()),
          ),
        );

        // Pump once to let the permission provider resolve
        await tester.pump();
        await tester.pump();

        // When permission is granted, CameraView is shown which displays
        // loading while initializing camera. In tests, camera can't initialize
        // so we verify the loading state is shown.
        expect(find.text('Initializing camera...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'shows permission denied view when permission is denied',
      (tester) async {
        final mockService = MockCameraPermissionService(
          initialStatus: PermissionStatus.denied,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cameraPermissionServiceProvider.overrideWithValue(mockService),
            ],
            child: const MaterialApp(home: CameraScreen()),
          ),
        );

        // Wait for async provider to complete
        await tester.pumpAndSettle();

        // Verify permission denied view is shown
        expect(find.text('Camera Access Required'), findsOneWidget);
        expect(find.text('Grant Access'), findsOneWidget);
      },
    );

    testWidgets(
      'shows settings prompt when permission is permanently denied',
      (tester) async {
        final mockService = MockCameraPermissionService(
          initialStatus: PermissionStatus.permanentlyDenied,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cameraPermissionServiceProvider.overrideWithValue(mockService),
            ],
            child: const MaterialApp(home: CameraScreen()),
          ),
        );

        // Wait for async provider to complete
        await tester.pumpAndSettle();

        // Verify settings prompt is shown
        expect(find.text('Camera Access Required'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
      },
    );
  });
}
