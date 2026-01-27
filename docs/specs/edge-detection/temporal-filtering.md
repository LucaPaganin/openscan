# Temporal Filtering Skill

## Purpose

Apply temporal smoothing, dead-zone locking, and confidence management to transform raw per-frame detections into a stable, visually coherent overlay. This is where "perceived intelligence" comes from.

## Scope

- Exponential moving average (EMA) smoothing
- Dead-zone to ignore micro-movements
- Confidence tracking and decay
- Lock state management
- Score-based update decisions

## Key Concepts

### Why Temporal Filtering?

Raw detection results vary frame-to-frame due to:
- Camera sensor noise
- Slight hand movements
- Lighting fluctuations
- Algorithm sensitivity

Without filtering, the overlay would jitter constantly. Temporal filtering smooths these variations into coherent motion.

### Exponential Moving Average (EMA)

```
P_smooth = α × P_current + (1 - α) × P_previous
```

Where `α` (alpha) controls responsiveness:
- `α = 1.0` → No smoothing (instant updates)
- `α = 0.5` → Medium smoothing
- `α = 0.2` → Heavy smoothing (recommended)

Lower alpha = smoother but more lag.

### Dead Zone

Ignore movements below a threshold. If the detected quad moved less than 0.5% of frame dimensions, keep the previous position. This prevents micro-jitter without adding lag for real movements.

### Confidence Locking

After detecting a stable quad for N consecutive frames:
1. Enter "locked" state
2. Boost confidence
3. Require larger movement or better score to unlock
4. Signal readiness for auto-capture

## State Machine

```
                    ┌─────────────────┐
                    │                 │
                    │   NO DETECTION  │
                    │   (confidence   │
                    │    decaying)    │
                    │                 │
                    └────────┬────────┘
                             │ detection found
                             ▼
                    ┌─────────────────┐
                    │                 │
        ┌──────────▶│   TRACKING      │◀──────────┐
        │           │   (smoothing    │           │
        │           │    active)      │           │
        │           │                 │           │
        │           └────────┬────────┘           │
        │                    │ stable for N frames│
        │ large              ▼                    │ no detection
        │ movement  ┌─────────────────┐           │
        └───────────│                 │───────────┘
                    │     LOCKED      │
                    │  (high confidence,
                    │   ready for     │
                    │   auto-capture) │
                    │                 │
                    └─────────────────┘
```

## Implementation

### Configuration

```dart
class TemporalFilterConfig {
  /// Smoothing factor (0.0-1.0). Lower = smoother, more lag
  final double alpha;

  /// Movement below this threshold is ignored (normalized units)
  final double deadZoneThreshold;

  /// Frames required to enter locked state
  final int lockFrameCount;

  /// Confidence decay per frame without detection
  final double confidenceDecay;

  /// Score improvement required to update locked quad
  final double scoreImprovementThreshold;

  /// Movement threshold to break lock
  final double lockBreakThreshold;

  const TemporalFilterConfig({
    this.alpha = 0.25,
    this.deadZoneThreshold = 0.005,
    this.lockFrameCount = 5,
    this.confidenceDecay = 0.1,
    this.scoreImprovementThreshold = 0.05,
    this.lockBreakThreshold = 0.1,
  });
}
```

### Filter State

```dart
/// Output from temporal filter
class FilteredQuadState {
  final DetectedQuad? quad;
  final double confidence;
  final bool isLocked;
  final int stableFrameCount;
  final int frameTimestamp;

  const FilteredQuadState({
    this.quad,
    required this.confidence,
    required this.isLocked,
    required this.stableFrameCount,
    required this.frameTimestamp,
  });

  bool get hasValidQuad => quad != null && confidence > 0.5;
  bool get readyForAutoCapture => isLocked && confidence > 0.85;
}
```

### Temporal Filter

```dart
class TemporalQuadFilter {
  final TemporalFilterConfig config;

  // Internal state
  DetectedQuad? _rawQuad;       // Latest raw detection
  DetectedQuad? _smoothedQuad;  // Smoothed output
  double _previousScore = 0;
  double _confidence = 0;
  int _stableFrameCount = 0;
  bool _isLocked = false;
  int _framesWithoutDetection = 0;

  TemporalQuadFilter({required this.config});

  /// Update filter with new detection (or null if none)
  FilteredQuadState update(
    DetectedQuad? newQuad,
    double newScore,
    int timestamp,
  ) {
    // Case 1: No detection this frame
    if (newQuad == null) {
      return _handleNoDetection(timestamp);
    }

    // Case 2: First detection
    if (_smoothedQuad == null) {
      return _handleFirstDetection(newQuad, newScore, timestamp);
    }

    // Case 3: Subsequent detection
    return _handleSubsequentDetection(newQuad, newScore, timestamp);
  }

  FilteredQuadState _handleNoDetection(int timestamp) {
    _framesWithoutDetection++;

    // Decay confidence
    _confidence = (_confidence - config.confidenceDecay).clamp(0.0, 1.0);

    // Break lock after extended absence
    if (_framesWithoutDetection > 10) {
      _isLocked = false;
      _stableFrameCount = 0;
    }

    // Keep showing last known quad (with fading confidence)
    return FilteredQuadState(
      quad: _smoothedQuad,
      confidence: _confidence,
      isLocked: _isLocked,
      stableFrameCount: _stableFrameCount,
      frameTimestamp: timestamp,
    );
  }

  FilteredQuadState _handleFirstDetection(
    DetectedQuad newQuad,
    double newScore,
    int timestamp,
  ) {
    _rawQuad = newQuad;
    _smoothedQuad = newQuad;
    _previousScore = newScore;
    _confidence = newScore;
    _stableFrameCount = 1;
    _framesWithoutDetection = 0;

    return FilteredQuadState(
      quad: _smoothedQuad,
      confidence: _confidence,
      isLocked: false,
      stableFrameCount: _stableFrameCount,
      frameTimestamp: timestamp,
    );
  }

  FilteredQuadState _handleSubsequentDetection(
    DetectedQuad newQuad,
    double newScore,
    int timestamp,
  ) {
    _framesWithoutDetection = 0;

    // Calculate movement from previous
    final movement = newQuad.distanceTo(_rawQuad!);
    final isStable = movement < config.deadZoneThreshold * 3;

    // Decide whether to accept new detection
    final shouldUpdate = _shouldUpdateQuad(newQuad, newScore, movement);

    if (!shouldUpdate) {
      // Keep previous quad
      return FilteredQuadState(
        quad: _smoothedQuad,
        confidence: _confidence,
        isLocked: _isLocked,
        stableFrameCount: _stableFrameCount,
        frameTimestamp: timestamp,
      );
    }

    // Apply smoothing
    final smoothedQuad = _applySmoothing(newQuad, movement);

    // Update stability tracking
    _updateStabilityState(isStable);

    // Update confidence
    _updateConfidence(newScore);

    // Store state
    _rawQuad = newQuad;
    _smoothedQuad = smoothedQuad;
    _previousScore = newScore;

    return FilteredQuadState(
      quad: _smoothedQuad,
      confidence: _confidence,
      isLocked: _isLocked,
      stableFrameCount: _stableFrameCount,
      frameTimestamp: timestamp,
    );
  }

  bool _shouldUpdateQuad(DetectedQuad newQuad, double newScore, double movement) {
    // If locked, require significant improvement or large movement
    if (_isLocked) {
      final scoreImprovement = newScore - _previousScore;
      
      // Large movement breaks lock
      if (movement > config.lockBreakThreshold) {
        _isLocked = false;
        return true;
      }

      // Only update if score significantly improves
      return scoreImprovement > config.scoreImprovementThreshold;
    }

    // Not locked: always update
    return true;
  }

  DetectedQuad _applySmoothing(DetectedQuad newQuad, double movement) {
    // Dead zone: if movement is tiny, don't move at all
    if (movement < config.deadZoneThreshold) {
      return _smoothedQuad!;
    }

    // Exponential smoothing toward new position
    return _smoothedQuad!.lerp(newQuad, config.alpha);
  }

  void _updateStabilityState(bool isStable) {
    if (isStable) {
      _stableFrameCount++;
      if (_stableFrameCount >= config.lockFrameCount) {
        _isLocked = true;
      }
    } else {
      _stableFrameCount = 1;
      _isLocked = false;
    }
  }

  void _updateConfidence(double newScore) {
    // Blend current confidence with new score
    _confidence = (_confidence * 0.7 + newScore * 0.3).clamp(0.0, 1.0);

    // Boost confidence when locked
    if (_isLocked) {
      _confidence = (_confidence + 0.1).clamp(0.0, 1.0);
    }
  }

  /// Reset filter state
  void reset() {
    _rawQuad = null;
    _smoothedQuad = null;
    _previousScore = 0;
    _confidence = 0;
    _stableFrameCount = 0;
    _isLocked = false;
    _framesWithoutDetection = 0;
  }
}
```

### Integration with Pipeline

```dart
/// Combined pipeline with temporal filtering
class PreviewDetectionPipeline {
  final ContourDetectionPipeline _detection;
  final TemporalQuadFilter _filter;

  PreviewDetectionPipeline({
    required ContourDetectionConfig detectionConfig,
    required TemporalFilterConfig filterConfig,
  })  : _detection = ContourDetectionPipeline(config: detectionConfig),
        _filter = TemporalQuadFilter(config: filterConfig);

  FilteredQuadState process(FrameData frame) {
    // Run detection
    final candidates = _detection.process(
      frame.yPlane,
      frame.width,
      frame.height,
    );

    // Extract best candidate
    DetectedQuad? bestQuad;
    double bestScore = 0;
    if (candidates.isNotEmpty) {
      bestQuad = candidates.first.quad;
      bestScore = candidates.first.score;
    }

    // Apply temporal filtering
    return _filter.update(bestQuad, bestScore, frame.timestamp);
  }

  void reset() {
    _detection.reset();
    _filter.reset();
  }
}
```

## Unit Tests

```dart
void main() {
  group('TemporalQuadFilter', () {
    late TemporalQuadFilter filter;

    setUp(() {
      filter = TemporalQuadFilter(
        config: TemporalFilterConfig(
          alpha: 0.25,
          deadZoneThreshold: 0.005,
          lockFrameCount: 5,
        ),
      );
    });

    group('Exponential smoothing', () {
      test('alpha=0.25 smooths correctly', () {
        final p1 = NormalizedPoint(0, 0);
        final p2 = NormalizedPoint(1, 1);

        final smoothed = p1.lerp(p2, 0.25);

        expect(smoothed.x, closeTo(0.25, 0.001));
        expect(smoothed.y, closeTo(0.25, 0.001));
      });

      test('multiple updates converge toward target', () {
        final target = createQuad(0.5, 0.5);
        final start = createQuad(0.2, 0.2);

        // First detection at start position
        filter.update(start, 0.8, 1000);

        // Multiple updates at target position
        FilteredQuadState? state;
        for (int i = 0; i < 20; i++) {
          state = filter.update(target, 0.8, 1000 + i * 100);
        }

        // Should have converged close to target
        expect(
          state!.quad!.center.distanceTo(target.center),
          lessThan(0.02),
        );
      });
    });

    group('Dead zone', () {
      test('ignores micro-movements', () {
        final quad1 = createQuad(0.5, 0.5);
        final quad2 = createQuad(0.501, 0.501); // 0.001 movement

        filter.update(quad1, 0.8, 1000);
        final state = filter.update(quad2, 0.8, 1100);

        // Should stay at original position
        expect(state.quad!.center.x, closeTo(0.5, 0.001));
      });

      test('allows larger movements', () {
        final quad1 = createQuad(0.5, 0.5);
        final quad2 = createQuad(0.6, 0.6); // 0.1 movement

        filter.update(quad1, 0.8, 1000);
        final state = filter.update(quad2, 0.8, 1100);

        // Should have moved toward new position
        expect(state.quad!.center.x, greaterThan(0.5));
      });
    });

    group('Confidence locking', () {
      test('locks after stable frames', () {
        final quad = createQuad(0.5, 0.5);

        FilteredQuadState? state;
        for (int i = 0; i < 10; i++) {
          state = filter.update(quad, 0.9, 1000 + i * 100);
        }

        expect(state!.isLocked, isTrue);
        expect(state.stableFrameCount, greaterThanOrEqualTo(5));
      });

      test('locked state resists small score improvements', () {
        final quad1 = createQuad(0.5, 0.5);
        final quad2 = createQuad(0.52, 0.52);

        // Establish lock
        for (int i = 0; i < 10; i++) {
          filter.update(quad1, 0.8, 1000 + i * 100);
        }

        // Small improvement with slight movement
        final state = filter.update(quad2, 0.82, 2000);

        // Should stay locked at original position
        expect(state.isLocked, isTrue);
        expect(state.quad!.center.x, closeTo(0.5, 0.01));
      });

      test('large movement breaks lock', () {
        final quad1 = createQuad(0.5, 0.5);
        final quad2 = createQuad(0.8, 0.8); // Large jump

        // Establish lock
        for (int i = 0; i < 10; i++) {
          filter.update(quad1, 0.8, 1000 + i * 100);
        }

        // Large movement
        final state = filter.update(quad2, 0.8, 2000);

        expect(state.isLocked, isFalse);
      });
    });

    group('Confidence decay', () {
      test('confidence decays without detection', () {
        final quad = createQuad(0.5, 0.5);

        filter.update(quad, 0.9, 1000);
        final initial = filter.update(quad, 0.9, 1100);

        // No detection for several frames
        FilteredQuadState? state;
        for (int i = 0; i < 5; i++) {
          state = filter.update(null, 0, 1200 + i * 100);
        }

        expect(state!.confidence, lessThan(initial.confidence));
      });

      test('quad persists during confidence decay', () {
        final quad = createQuad(0.5, 0.5);

        filter.update(quad, 0.9, 1000);

        // No detection
        final state = filter.update(null, 0, 1100);

        // Quad should still be present
        expect(state.quad, isNotNull);
        expect(state.quad!.center.x, closeTo(0.5, 0.01));
      });
    });

    group('readyForAutoCapture', () {
      test('requires locked state and high confidence', () {
        final quad = createQuad(0.5, 0.5);

        FilteredQuadState? state;
        for (int i = 0; i < 15; i++) {
          state = filter.update(quad, 0.95, 1000 + i * 100);
        }

        expect(state!.isLocked, isTrue);
        expect(state.confidence, greaterThan(0.85));
        expect(state.readyForAutoCapture, isTrue);
      });

      test('not ready if confidence too low', () {
        final quad = createQuad(0.5, 0.5);

        FilteredQuadState? state;
        for (int i = 0; i < 15; i++) {
          state = filter.update(quad, 0.6, 1000 + i * 100); // Lower score
        }

        expect(state!.isLocked, isTrue);
        expect(state.readyForAutoCapture, isFalse);
      });
    });
  });
}

DetectedQuad createQuad(double cx, double cy) {
  const size = 0.3;
  return DetectedQuad(
    topLeft: NormalizedPoint(cx - size, cy - size),
    topRight: NormalizedPoint(cx + size, cy - size),
    bottomRight: NormalizedPoint(cx + size, cy + size),
    bottomLeft: NormalizedPoint(cx - size, cy + size),
  );
}
```

## Tuning Guide

| Symptom | Parameter | Adjustment |
|---------|-----------|------------|
| Overlay jitters | `alpha` | Decrease (e.g., 0.15) |
| Overlay lags behind | `alpha` | Increase (e.g., 0.4) |
| Overlay jumps on tiny movements | `deadZoneThreshold` | Increase |
| Lock triggers too easily | `lockFrameCount` | Increase |
| Lock never triggers | `lockFrameCount` | Decrease |
| Lock breaks too easily | `lockBreakThreshold` | Increase |
| Overlay fades too fast | `confidenceDecay` | Decrease |

## Common Pitfalls

1. **Applying smoothing to raw detection** — Smooth the *displayed* quad, not the detection input.

2. **High alpha for responsiveness** — Users perceive jitter more than lag. Prefer smooth.

3. **No dead zone** — Even perfectly stable cameras have sensor noise.

4. **Locking on first stable frame** — Require multiple stable frames to avoid false locks.

5. **Forgetting confidence decay** — Without decay, stale quads persist forever.

## Dependencies

- `geometry-validation.md` (for `DetectedQuad`, `NormalizedPoint`)

## Related Skills

- `contour-detection.md` — Provides raw detections to filter
- `auto-capture.md` — Uses locked state to trigger capture
