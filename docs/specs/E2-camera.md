# Epic 2: Camera Module

## Epic Overview

**Goal**: Implement camera functionality with live preview and manual capture. This epic establishes the core scanning interface that all subsequent image processing features will build upon.

**Duration**: 1 Sprint (1 week)

**Epic Owner**: Luca (Scrum Master)

**Phase**: 1 (Flutter MVP — No Backend Required)

**Dependencies**: E1 (Project Setup) must be complete

---

## Success Criteria

By the end of this epic:
- [ ] Camera preview displays full-screen on the Camera tab
- [ ] App requests and handles camera permissions correctly (iOS + Android)
- [ ] User can capture a photo by tapping a capture button
- [ ] Captured image is temporarily stored and accessible for next steps
- [ ] Camera works on both iOS simulator/device and Android emulator/device
- [ ] Flash toggle works (on/off/auto)
- [ ] Camera switches between front/back (back is default)
- [ ] All tests pass with success and failure scenarios

---

## User Stories

### US-2.1: Camera Permissions

**As a** user  
**I want** the app to request camera access  
**So that** I can use the scanner functionality

**Acceptance Criteria**:
- App requests camera permission on first launch of Camera screen
- If granted: camera preview starts immediately
- If denied: show friendly message explaining why camera is needed, with button to open Settings
- If previously denied: detect this state and show Settings prompt
- Permission state persists correctly across app restarts

**iOS Configuration** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>OpenScan needs camera access to scan your documents</string>
```

**Android Configuration** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

**Dependencies**:
```yaml
dependencies:
  permission_handler: ^11.3.0
```

**Tests Required**:
- ✅ When permission granted, camera preview initializes successfully
- ✅ When permission denied, error state displays with Settings button

---

### US-2.2: Camera Preview

**As a** user  
**I want** to see a live camera preview  
**So that** I can position my document correctly before capturing

**Acceptance Criteria**:
- Full-screen camera preview on Camera tab (respecting safe areas)
- Preview uses back camera by default
- Preview maintains correct aspect ratio (no stretching)
- Preview is responsive to device orientation (portrait primary, landscape supported)
- Smooth frame rate (minimum 30fps)
- Preview pauses when app goes to background, resumes on foreground

**Dependencies**:
```yaml
dependencies:
  camera: ^0.10.5+9
```

**Implementation Notes**:

```dart
// lib/features/camera/presentation/screens/camera_screen.dart

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for camera resource management
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    await _controller!.initialize();
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return CameraPreview(controller: _controller!);
  }
}
```

**Tests Required**:
- ✅ Camera initializes with back camera when available
- ✅ Camera falls back to first available camera when back camera unavailable

---

### US-2.3: Capture Button

**As a** user  
**I want** a capture button on the camera screen  
**So that** I can take a photo of my document

**Acceptance Criteria**:
- Large, circular capture button centered at bottom of screen
- Button shows visual feedback on press (scale/opacity animation)
- Haptic feedback on capture (if device supports)
- Button is disabled while capture is in progress (prevents double-tap)
- Capture triggers shutter sound (respecting device silent mode)

**UI Specifications**:
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│      [Camera Preview]           │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│                                 │
│    [Flash]   [ ◉ ]   [Flip]    │
│                                 │
└─────────────────────────────────┘

Capture button: 
- Size: 72x72 dp
- Color: White with slight shadow
- Inner circle: 60x60 dp
- Press animation: scale to 0.9
```

**Implementation**:
```dart
// lib/features/camera/presentation/widgets/capture_button.dart

class CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCapturing;

  const CaptureButton({
    super.key,
    required this.onPressed,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onPressed,
      child: AnimatedScale(
        scale: isCapturing ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Tests Required**:
- ✅ Capture button triggers onPressed callback when tapped
- ✅ Capture button ignores taps when isCapturing is true

---

### US-2.4: Image Capture

**As a** user  
**I want** to capture the current camera frame  
**So that** I can process it as a scanned document

**Acceptance Criteria**:
- Pressing capture button takes a photo
- Photo is saved to temporary storage (not gallery)
- Capture completes within 500ms on modern devices
- After capture, image path is available for next processing step
- Failed capture shows error toast/snackbar

**Implementation**:
```dart
// lib/features/camera/domain/capture_service.dart

class CaptureService {
  final CameraController controller;
  
  CaptureService(this.controller);
  
  Future<CapturedImage> capture() async {
    if (!controller.value.isInitialized) {
      throw CameraNotInitializedException();
    }
    
    if (controller.value.isTakingPicture) {
      throw CaptureInProgressException();
    }
    
    try {
      final XFile file = await controller.takePicture();
      return CapturedImage(
        path: file.path,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw CaptureFailedException(e.toString());
    }
  }
}

// lib/features/camera/domain/models/captured_image.dart

class CapturedImage {
  final String path;
  final DateTime timestamp;
  
  const CapturedImage({
    required this.path,
    required this.timestamp,
  });
}
```

**Exception Classes** (`lib/core/errors/camera_exceptions.dart`):
```dart
class CameraNotInitializedException implements Exception {
  final String message = 'Camera is not initialized';
}

class CaptureInProgressException implements Exception {
  final String message = 'Capture already in progress';
}

class CaptureFailedException implements Exception {
  final String message;
  CaptureFailedException(this.message);
}
```

**Tests Required**:
- ✅ `capture()` returns CapturedImage with valid path when successful
- ✅ `capture()` throws CameraNotInitializedException when controller not initialized

---

### US-2.5: Flash Control

**As a** user  
**I want** to control the camera flash  
**So that** I can scan documents in low-light conditions

**Acceptance Criteria**:
- Flash toggle button in camera controls bar
- Three states: Off → Auto → On → Off (cycle)
- Icon updates to reflect current state
- Flash state persists during session (resets to Auto on app restart)
- Flash fires on capture when enabled

**Icons**:
- Off: `Icons.flash_off`
- Auto: `Icons.flash_auto`
- On: `Icons.flash_on`

**Implementation**:
```dart
// lib/features/camera/presentation/providers/flash_mode_provider.dart

import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flash_mode_provider.g.dart';

@riverpod
class FlashModeNotifier extends _$FlashModeNotifier {
  @override
  FlashMode build() => FlashMode.auto;
  
  void cycle() {
    state = switch (state) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
  }
  
  void setMode(FlashMode mode) => state = mode;
}
```

**Tests Required**:
- ✅ Flash mode cycles correctly: off → auto → on → off
- ✅ Flash mode defaults to auto on initialization

---

### US-2.6: Camera Flip

**As a** user  
**I want** to switch between front and back cameras  
**So that** I can use either camera if needed

**Acceptance Criteria**:
- Flip button in camera controls bar
- Toggles between front and back camera
- Smooth transition (brief loading indicator acceptable)
- Preserves flash setting when switching (if supported)
- Back camera is default on app launch

**Implementation**:
```dart
// lib/features/camera/presentation/providers/camera_provider.dart

@riverpod
class CameraNotifier extends _$CameraNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  
  @override
  Future<CameraController?> build() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return null;
    
    // Find back camera, default to first
    _currentCameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (_currentCameraIndex == -1) _currentCameraIndex = 0;
    
    return _initController(_cameras[_currentCameraIndex]);
  }
  
  Future<CameraController> _initController(CameraDescription camera) async {
    _controller?.dispose();
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    return _controller!;
  }
  
  Future<void> flipCamera() async {
    if (_cameras.length < 2) return;
    
    state = const AsyncLoading();
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    
    try {
      final controller = await _initController(_cameras[_currentCameraIndex]);
      state = AsyncData(controller);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
  
  bool get canFlip => _cameras.length > 1;
}
```

**Tests Required**:
- ✅ `flipCamera()` switches to next camera in list
- ✅ `flipCamera()` does nothing when only one camera available

---

### US-2.7: Camera Controls Bar

**As a** user  
**I want** camera controls organized in a clear interface  
**So that** I can easily access flash, capture, and flip functions

**Acceptance Criteria**:
- Controls bar at bottom of camera screen
- Semi-transparent dark background for visibility
- Layout: [Flash] — [Capture] — [Flip]
- Controls are touch-friendly (minimum 48x48 tap targets)
- Respects safe area (notch, home indicator)

**UI Specifications**:
```
┌─────────────────────────────────────────┐
│          Camera Preview                 │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │  ⚡      │     ◉     │      🔄     │ │
│ │ Flash    │  Capture  │     Flip    │ │
│ └─────────────────────────────────────┘ │
│         (Safe Area Padding)             │
└─────────────────────────────────────────┘

Bar height: 120dp + safe area
Background: Colors.black.withOpacity(0.5)
```

**Implementation**:
```dart
// lib/features/camera/presentation/widgets/camera_controls_bar.dart

class CameraControlsBar extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onFlashToggle;
  final VoidCallback onCameraFlip;
  final FlashMode flashMode;
  final bool isCapturing;
  final bool canFlip;

  const CameraControlsBar({
    super.key,
    required this.onCapture,
    required this.onFlashToggle,
    required this.onCameraFlip,
    required this.flashMode,
    this.isCapturing = false,
    this.canFlip = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flash button
              IconButton(
                onPressed: onFlashToggle,
                icon: Icon(_flashIcon, color: Colors.white, size: 28),
                tooltip: 'Toggle flash',
              ),
              
              // Capture button
              CaptureButton(
                onPressed: onCapture,
                isCapturing: isCapturing,
              ),
              
              // Flip button
              IconButton(
                onPressed: canFlip ? onCameraFlip : null,
                icon: Icon(
                  Icons.flip_camera_ios,
                  color: canFlip ? Colors.white : Colors.white38,
                  size: 28,
                ),
                tooltip: 'Switch camera',
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _flashIcon => switch (flashMode) {
    FlashMode.off => Icons.flash_off,
    FlashMode.auto => Icons.flash_auto,
    FlashMode.always => Icons.flash_on,
    _ => Icons.flash_auto,
  };
}
```

**Tests Required**:
- ✅ Controls bar renders all three buttons
- ✅ Flip button is disabled when canFlip is false

---

## Technical Specifications

### Camera Resolution Strategy

```dart
// Use high resolution for document scanning quality
// ResolutionPreset.high = 1280x720 minimum
// This balances quality with processing speed

ResolutionPreset.high  // Default
ResolutionPreset.max   // Optional for high-end devices
```

### File Storage Location

Captured images go to temporary storage:
```dart
// iOS: NSTemporaryDirectory
// Android: getCacheDir()

// Path format: {temp_dir}/capture_{timestamp}.jpg
```

### Memory Management

- Dispose camera controller when screen is not visible
- Clear temporary captures older than 24 hours on app launch
- Release image memory after processing completes

---

## State Management

### Providers Structure

```
lib/features/camera/
├── presentation/
│   └── providers/
│       ├── camera_provider.dart       # Camera controller state
│       ├── flash_mode_provider.dart   # Flash mode state
│       └── capture_state_provider.dart # Capture in progress state
```

### Capture State

```dart
// lib/features/camera/presentation/providers/capture_state_provider.dart

@riverpod
class CaptureState extends _$CaptureState {
  @override
  AsyncValue<CapturedImage?> build() => const AsyncData(null);
  
  Future<void> capture(CaptureService service) async {
    state = const AsyncLoading();
    try {
      final image = await service.capture();
      state = AsyncData(image);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  void reset() => state = const AsyncData(null);
}
```

---

## Error Handling

| Error | User Message | Recovery Action |
|-------|--------------|-----------------|
| Camera permission denied | "Camera access is required to scan documents" | Show Settings button |
| No cameras available | "No camera found on this device" | Disable camera features |
| Camera initialization failed | "Could not start camera. Please try again." | Retry button |
| Capture failed | "Could not capture image. Please try again." | Auto-dismiss toast, user can retry |

---

## Definition of Done

- [ ] Camera preview displays correctly on iOS
- [ ] Camera preview displays correctly on Android
- [ ] Permission request flow works (grant and deny paths)
- [ ] Capture button takes photo and returns image path
- [ ] Flash toggle cycles through modes and affects capture
- [ ] Camera flip switches between available cameras
- [ ] App handles background/foreground transitions
- [ ] All tests pass (minimum 2 scenarios per component)
- [ ] No lint warnings
- [ ] Code committed with conventional commit messages

---

## Out of Scope

The following are explicitly NOT part of this epic:
- Edge detection overlay (Epic 4)
- Auto-capture functionality (Epic 9)
- Image processing/filters (Epic 7)
- Saving to gallery (Epic 3)
- Document cropping UI (Epic 5)

---

## Implementation Order

Suggested order for Claude Code:

1. Add camera and permission_handler dependencies to `pubspec.yaml`
2. Configure iOS permissions in `Info.plist`
3. Configure Android permissions in `AndroidManifest.xml`
4. Create camera exception classes
5. Create CapturedImage model
6. Implement permission handling logic
7. Implement camera provider with initialization
8. Create camera preview widget
9. Implement flash mode provider
10. Create flash toggle button
11. Implement capture service
12. Create capture button widget
13. Implement camera flip functionality
14. Create camera controls bar
15. Assemble camera screen with all components
16. Update router to use real camera screen (replace placeholder)
17. Write tests for all components
18. Run `flutter analyze` and fix any issues

---

## Notes for Claude Code

When implementing this epic:

1. **Test on real device if possible** — Camera behaves differently on simulators
2. **Handle the iOS Simulator** — It has no camera, so mock or show placeholder
3. **Android Emulator** — Can simulate camera with scene, but test permission flow
4. **Follow CLAUDE.md** — Especially the two-scenario testing requirement
5. **Dispose resources** — Camera is resource-intensive; always clean up
6. **Run build_runner** — After creating Riverpod providers: `dart run build_runner build`

---

## Confirmed Decisions

- **Default camera**: Back
- **Default flash**: Auto
- **Resolution**: High (ResolutionPreset.high)
- **Temporary storage**: App cache directory
- **Audio**: Disabled (not needed for document scanning)