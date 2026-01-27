# Auto-Capture Skill

## Purpose

Monitor detection stability and automatically trigger capture when a document has been confidently detected for a specified duration. Provide visual feedback of capture progress.

## Scope

- Stability duration tracking
- Capture triggering logic
- Progress calculation for UI feedback
- Reset and cancellation handling
- Integration with capture pipeline

## Key Concepts

### Auto-Capture Requirements

Auto-capture triggers when ALL conditions are met:
1. **Locked state** — Temporal filter reports `isLocked = true`
2. **High confidence** — Confidence exceeds threshold (typically 0.85)
3. **Stability duration** — Conditions maintained for N milliseconds (typically 1500ms)

### State Machine

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│    ┌─────────┐                                                       │
│    │  IDLE   │◀───────────────────────────────────────┐              │
│    └────┬────┘                                        │              │
│         │                                             │              │
│         │ locked && confidence > threshold            │              │
│         ▼                                             │              │
│    ┌─────────────┐                                    │              │
│    │  COUNTDOWN  │───────────────────────────────────▶│              │
│    │  (progress) │  !locked || confidence < threshold │              │
│    └──────┬──────┘                                    │              │
│           │                                           │              │
│           │ duration elapsed                          │              │
│           ▼                                           │              │
│    ┌─────────────┐                                    │              │
│    │  CAPTURING  │───────────────────────────────────▶│              │
│    └─────────────┘  capture complete or failed        │              │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Progress Feedback

During countdown, progress (0.0 to 1.0) indicates time remaining:
- Progress 0.0 → Just started countdown
- Progress 0.5 → Halfway through
- Progress 1.0 → About to capture

UI should display this as a visual indicator (progress ring, filling border, etc.)

## Implementation

### Configuration

```dart
class AutoCaptureConfig {
  /// Minimum confidence to start/continue countdown
  final double confidenceThreshold;

  /// Duration locked state must be maintained
  final Duration stabilityDuration;

  /// Whether auto-capture is enabled
  final bool enabled;

  const AutoCaptureConfig({
    this.confidenceThreshold = 0.85,
    this.stabilityDuration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });
}
```

### Auto-Capture State

```dart
/// Current state of auto-capture system
enum AutoCapturePhase {
  /// Waiting for stable detection
  idle,

  /// Counting down to capture
  countdown,

  /// Capture in progress
  capturing,

  /// Capture completed successfully
  completed,

  /// Capture failed
  failed,
}

class AutoCaptureState {
  final AutoCapturePhase phase;
  final double progress; // 0.0 to 1.0 during countdown
  final DateTime? countdownStartTime;
  final String? errorMessage;

  const AutoCaptureState({
    required this.phase,
    this.progress = 0,
    this.countdownStartTime,
    this.errorMessage,
  });

  factory AutoCaptureState.idle() => const AutoCaptureState(
        phase: AutoCapturePhase.idle,
      );

  factory AutoCaptureState.countdown({
    required double progress,
    required DateTime startTime,
  }) =>
      AutoCaptureState(
        phase: AutoCapturePhase.countdown,
        progress: progress,
        countdownStartTime: startTime,
      );

  factory AutoCaptureState.capturing() => const AutoCaptureState(
        phase: AutoCapturePhase.capturing,
      );

  factory AutoCaptureState.completed() => const AutoCaptureState(
        phase: AutoCapturePhase.completed,
      );

  factory AutoCaptureState.failed(String message) => AutoCaptureState(
        phase: AutoCapturePhase.failed,
        errorMessage: message,
      );

  bool get isCountingDown => phase == AutoCapturePhase.countdown;
  bool get isCapturing => phase == AutoCapturePhase.capturing;
}
```

### Auto-Capture Controller

```dart
import 'dart:async';

class AutoCaptureController {
  final AutoCaptureConfig config;
  final CaptureOrchestrator _captureOrchestrator;

  DateTime? _countdownStartTime;
  bool _captureInProgress = false;

  final _stateController = StreamController<AutoCaptureState>.broadcast();
  Stream<AutoCaptureState> get stateStream => _stateController.stream;

  AutoCaptureState _currentState = AutoCaptureState.idle();
  AutoCaptureState get currentState => _currentState;

  AutoCaptureController({
    required this.config,
    required CaptureOrchestrator captureOrchestrator,
  }) : _captureOrchestrator = captureOrchestrator;

  /// Call this on each FilteredQuadState update
  Future<CaptureResult?> evaluate(FilteredQuadState quadState) async {
    if (!config.enabled || _captureInProgress) {
      return null;
    }

    final meetsConditions = _meetsAutoCaptureCriteria(quadState);

    if (!meetsConditions) {
      // Reset countdown if conditions not met
      if (_countdownStartTime != null) {
        _resetCountdown();
      }
      return null;
    }

    // Start countdown if not already started
    _countdownStartTime ??= DateTime.now();

    // Calculate progress
    final elapsed = DateTime.now().difference(_countdownStartTime!);
    final progress = (elapsed.inMilliseconds / 
                      config.stabilityDuration.inMilliseconds)
        .clamp(0.0, 1.0);

    // Update state
    _updateState(AutoCaptureState.countdown(
      progress: progress,
      startTime: _countdownStartTime!,
    ));

    // Check if countdown complete
    if (elapsed >= config.stabilityDuration) {
      return _triggerCapture(quadState);
    }

    return null;
  }

  bool _meetsAutoCaptureCriteria(FilteredQuadState state) {
    return state.isLocked && state.confidence >= config.confidenceThreshold;
  }

  Future<CaptureResult?> _triggerCapture(FilteredQuadState quadState) async {
    _captureInProgress = true;
    _updateState(AutoCaptureState.capturing());

    try {
      final result = await _captureOrchestrator.capture(
        previewState: quadState,
      );

      if (result is CaptureSuccess || result is CaptureManualRequired) {
        _updateState(AutoCaptureState.completed());
      } else if (result is CaptureError) {
        _updateState(AutoCaptureState.failed(result.message));
      }

      return result;
    } catch (e) {
      _updateState(AutoCaptureState.failed(e.toString()));
      return CaptureError(message: e.toString(), error: e);
    } finally {
      _captureInProgress = false;
      _countdownStartTime = null;
    }
  }

  void _resetCountdown() {
    _countdownStartTime = null;
    _updateState(AutoCaptureState.idle());
  }

  void _updateState(AutoCaptureState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Manually reset to idle state
  void reset() {
    _countdownStartTime = null;
    _captureInProgress = false;
    _updateState(AutoCaptureState.idle());
  }

  /// Manually trigger capture (bypass auto-capture conditions)
  Future<CaptureResult> manualCapture(FilteredQuadState? quadState) async {
    if (_captureInProgress) {
      return CaptureError(message: 'Capture already in progress');
    }

    _captureInProgress = true;
    _updateState(AutoCaptureState.capturing());

    try {
      final result = await _captureOrchestrator.capture(
        previewState: quadState,
      );

      _updateState(result is CaptureError
          ? AutoCaptureState.failed(result.message)
          : AutoCaptureState.completed());

      return result;
    } catch (e) {
      _updateState(AutoCaptureState.failed(e.toString()));
      return CaptureError(message: e.toString(), error: e);
    } finally {
      _captureInProgress = false;
      _countdownStartTime = null;
    }
  }

  void dispose() {
    _stateController.close();
  }
}
```

### Riverpod Integration

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for auto-capture configuration
final autoCaptureConfigProvider = Provider<AutoCaptureConfig>((ref) {
  return const AutoCaptureConfig();
});

/// Provider for auto-capture controller
final autoCaptureControllerProvider = Provider<AutoCaptureController>((ref) {
  final config = ref.watch(autoCaptureConfigProvider);
  final captureOrchestrator = ref.watch(captureOrchestratorProvider);

  final controller = AutoCaptureController(
    config: config,
    captureOrchestrator: captureOrchestrator,
  );

  ref.onDispose(() => controller.dispose());

  return controller;
});

/// Provider for auto-capture state stream
final autoCaptureStateProvider = StreamProvider<AutoCaptureState>((ref) {
  final controller = ref.watch(autoCaptureControllerProvider);
  return controller.stateStream;
});

/// Provider that evaluates auto-capture on each quad state update
final autoCaptureEvaluatorProvider = Provider<void>((ref) {
  final controller = ref.watch(autoCaptureControllerProvider);
  final quadState = ref.watch(quadStateProvider);

  // Evaluate auto-capture conditions
  controller.evaluate(quadState);
});
```

### Widget Integration

```dart
/// Widget that displays auto-capture progress
class AutoCaptureProgressIndicator extends ConsumerWidget {
  const AutoCaptureProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoCaptureState = ref.watch(autoCaptureStateProvider);

    return autoCaptureState.when(
      data: (state) => _buildIndicator(state),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildIndicator(AutoCaptureState state) {
    switch (state.phase) {
      case AutoCapturePhase.idle:
        return const SizedBox.shrink();

      case AutoCapturePhase.countdown:
        return _CountdownIndicator(progress: state.progress);

      case AutoCapturePhase.capturing:
        return const _CapturingIndicator();

      case AutoCapturePhase.completed:
        return const _CompletedIndicator();

      case AutoCapturePhase.failed:
        return _FailedIndicator(message: state.errorMessage);
    }
  }
}

class _CountdownIndicator extends StatelessWidget {
  final double progress;

  const _CountdownIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              color: Colors.white.withOpacity(0.3),
            ),
            // Progress circle
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              color: Colors.green,
            ),
            // Percentage text
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturingIndicator extends StatelessWidget {
  const _CapturingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Capturing...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _CompletedIndicator extends StatelessWidget {
  const _CompletedIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 64,
      ),
    );
  }
}

class _FailedIndicator extends StatelessWidget {
  final String? message;

  const _FailedIndicator({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

### Full Scanner Screen Integration

```dart
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize camera and frame processor
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    // ... camera initialization
  }

  @override
  Widget build(BuildContext context) {
    final cameraController = ref.watch(cameraControllerProvider);
    final quadState = ref.watch(quadStateProvider);
    final autoCaptureState = ref.watch(autoCaptureStateProvider);

    // Evaluate auto-capture on each quad state update
    ref.listen(quadStateProvider, (previous, next) {
      final controller = ref.read(autoCaptureControllerProvider);
      controller.evaluate(next).then((result) {
        if (result != null) {
          _handleCaptureResult(result);
        }
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          if (cameraController != null)
            CameraPreview(controller: cameraController),

          // Quad overlay
          QuadOverlayWidget(
            stateStream: ref.read(frameProcessorProvider).results,
            transformer: ref.watch(coordinateTransformerProvider),
          ),

          // Auto-capture progress
          const AutoCaptureProgressIndicator(),

          // Manual capture button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: _CaptureButton(
                onPressed: _onManualCapture,
                isEnabled: !autoCaptureState.maybeWhen(
                  data: (s) => s.isCapturing,
                  orElse: () => false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onManualCapture() async {
    final controller = ref.read(autoCaptureControllerProvider);
    final quadState = ref.read(quadStateProvider);

    final result = await controller.manualCapture(quadState);
    _handleCaptureResult(result);
  }

  void _handleCaptureResult(CaptureResult result) {
    switch (result) {
      case CaptureSuccess():
        // Navigate to review screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewScreen(result: result),
          ),
        );
        break;

      case CaptureManualRequired():
        // Navigate to manual adjustment screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManualAdjustScreen(result: result),
          ),
        );
        break;

      case CaptureError():
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        break;
    }
  }
}

class _CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isEnabled;

  const _CaptureButton({
    required this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? Colors.white : Colors.grey,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
      ),
    );
  }
}
```

## Unit Tests

```dart
void main() {
  group('AutoCaptureController', () {
    late AutoCaptureController controller;
    late MockCaptureOrchestrator mockOrchestrator;

    setUp(() {
      mockOrchestrator = MockCaptureOrchestrator();
      controller = AutoCaptureController(
        config: const AutoCaptureConfig(
          confidenceThreshold: 0.85,
          stabilityDuration: Duration(milliseconds: 1500),
        ),
        captureOrchestrator: mockOrchestrator,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts countdown when conditions met', () async {
      final state = FilteredQuadState(
        quad: createTestQuad(),
        confidence: 0.9,
        isLocked: true,
        stableFrameCount: 10,
        frameTimestamp: 0,
      );

      await controller.evaluate(state);

      expect(controller.currentState.phase, equals(AutoCapturePhase.countdown));
      expect(controller.currentState.progress, greaterThan(0));
    });

    test('resets countdown when conditions fail', () async {
      // Start countdown
      final goodState = FilteredQuadState(
        quad: createTestQuad(),
        confidence: 0.9,
        isLocked: true,
        stableFrameCount: 10,
        frameTimestamp: 0,
      );
      await controller.evaluate(goodState);
      expect(controller.currentState.isCountingDown, isTrue);

      // Break conditions
      final badState = FilteredQuadState(
        quad: createTestQuad(),
        confidence: 0.5, // Below threshold
        isLocked: false,
        stableFrameCount: 1,
        frameTimestamp: 100,
      );
      await controller.evaluate(badState);

      expect(controller.currentState.phase, equals(AutoCapturePhase.idle));
    });

    test('triggers capture after stability duration', () async {
      when(mockOrchestrator.capture(previewState: any))
          .thenAnswer((_) async => CaptureSuccess(
                originalImage: Uint8List(0),
                croppedImage: Uint8List(0),
                detectedQuad: createTestQuad(),
                originalSize: const Size(1920, 1080),
                croppedSize: const Size(800, 600),
              ));

      final state = FilteredQuadState(
        quad: createTestQuad(),
        confidence: 0.9,
        isLocked: true,
        stableFrameCount: 10,
        frameTimestamp: 0,
      );

      // Simulate time passing
      controller.evaluate(state);
      await Future.delayed(const Duration(milliseconds: 1600));
      final result = await controller.evaluate(state);

      expect(result, isA<CaptureSuccess>());
      verify(mockOrchestrator.capture(previewState: any)).called(1);
    });

    test('progress increases over time', () async {
      final state = FilteredQuadState(
        quad: createTestQuad(),
        confidence: 0.9,
        isLocked: true,
        stableFrameCount: 10,
        frameTimestamp: 0,
      );

      // First evaluation
      await controller.evaluate(state);
      final progress1 = controller.currentState.progress;

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 500));

      // Second evaluation
      await controller.evaluate(state);
      final progress2 = controller.currentState.progress;

      expect(progress2, greaterThan(progress1));
    });

    test('manual capture bypasses conditions', () async {
      when(mockOrchestrator.capture(previewState: any))
          .thenAnswer((_) async => CaptureSuccess(
                originalImage: Uint8List(0),
                croppedImage: Uint8List(0),
                detectedQuad: createTestQuad(),
                originalSize: const Size(1920, 1080),
                croppedSize: const Size(800, 600),
              ));

      // Even with low confidence, manual capture should work
      final state = FilteredQuadState(
        quad: createTestQuad(),
        confidence: 0.3, // Below threshold
        isLocked: false,
        stableFrameCount: 1,
        frameTimestamp: 0,
      );

      final result = await controller.manualCapture(state);

      expect(result, isA<CaptureSuccess>());
    });

    test('disabled config prevents auto-capture', () async {
      final disabledController = AutoCaptureController(
        config: const AutoCaptureConfig(enabled: false),
        captureOrchestrator: mockOrchestrator,
      );

      final state = FilteredQuadState(
        quad: createTestQuad(),
        confidence: 0.95,
        isLocked: true,
        stableFrameCount: 10,
        frameTimestamp: 0,
      );

      // Should not start countdown
      await disabledController.evaluate(state);
      expect(
          disabledController.currentState.phase, equals(AutoCapturePhase.idle));

      disabledController.dispose();
    });
  });

  group('AutoCaptureState', () {
    test('isCountingDown returns true only during countdown', () {
      expect(AutoCaptureState.idle().isCountingDown, isFalse);
      expect(
          AutoCaptureState.countdown(progress: 0.5, startTime: DateTime.now())
              .isCountingDown,
          isTrue);
      expect(AutoCaptureState.capturing().isCountingDown, isFalse);
    });
  });
}

DetectedQuad createTestQuad() {
  return DetectedQuad(
    topLeft: NormalizedPoint(0.2, 0.2),
    topRight: NormalizedPoint(0.8, 0.2),
    bottomRight: NormalizedPoint(0.8, 0.8),
    bottomLeft: NormalizedPoint(0.2, 0.8),
  );
}
```

## Configuration Tuning

| Parameter | Default | Effect of Increase | Effect of Decrease |
|-----------|---------|--------------------|--------------------|
| `confidenceThreshold` | 0.85 | Fewer false triggers, may miss valid docs | More triggers, possible false positives |
| `stabilityDuration` | 1500ms | More stable captures, slower UX | Faster captures, possible motion blur |

### Recommended Presets

```dart
class AutoCapturePresets {
  /// Default balanced settings
  static const balanced = AutoCaptureConfig(
    confidenceThreshold: 0.85,
    stabilityDuration: Duration(milliseconds: 1500),
  );

  /// Quick capture for experienced users
  static const quick = AutoCaptureConfig(
    confidenceThreshold: 0.80,
    stabilityDuration: Duration(milliseconds: 800),
  );

  /// Careful capture for shaky hands
  static const careful = AutoCaptureConfig(
    confidenceThreshold: 0.90,
    stabilityDuration: Duration(milliseconds: 2500),
  );

  /// Disabled (manual only)
  static const manualOnly = AutoCaptureConfig(
    enabled: false,
  );
}
```

## Common Pitfalls

1. **Not resetting on navigation** — Reset controller when leaving scanner screen
2. **Multiple captures** — Guard against re-triggering while capture in progress
3. **Progress jumps** — Use smooth animation for progress indicator
4. **Blocking UI** — Run capture in isolate, show loading state
5. **Missing error handling** — Always handle capture failures gracefully

## Dependencies

- `temporal-filtering.md` (for `FilteredQuadState`)
- `capture-pipeline.md` (for `CaptureOrchestrator`, `CaptureResult`)

## Related Skills

- `overlay-rendering.md` — May display capture progress on quad border
