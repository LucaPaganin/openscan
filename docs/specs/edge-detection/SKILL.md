# OpenScan Edge Detection — Skill Index

## Overview

This skill provides real-time document edge detection for a Flutter document scanning app. The system displays a stabilized quadrilateral overlay during camera preview and triggers auto-capture when a document is confidently detected.

## When to Use This Skill

Use this skill when implementing:
- Real-time document boundary detection
- Camera preview overlays with visual feedback
- Auto-capture based on stability detection
- Perspective correction for captured documents

## Architecture Summary

```
Camera (30fps) → FrameSampler (8fps) → Detection Isolate → Temporal Filter → UI Overlay
                                              ↓
                                    [Downscale → Blur → Canny → Contours → Score]
```

**Key Principle**: Preview detection prioritizes speed and stability over accuracy. The perceived intelligence comes from temporal filtering, not per-frame precision.

## Sub-Skills

Load these skills based on what you're implementing:

| Task | Required Skills |
|------|-----------------|
| Implementing quad geometry | `geometry-validation.md` |
| Setting up isolate pipeline | `isolate-pipeline.md` |
| OpenCV detection logic | `contour-detection.md` |
| Smoothing & stability | `temporal-filtering.md` |
| Rendering overlay | `coordinate-transform.md` + `overlay-rendering.md` |
| Capture & crop | `capture-pipeline.md` |
| Auto-capture trigger | `auto-capture.md` |

## Critical Constraints

### Performance Boundaries
- Frame processing: **< 30ms**
- UI thread: **never blocked** by CV operations
- Memory: **no leaks** over prolonged sessions

### Design Rules
1. **Never** process full-resolution frames during preview
2. **Never** update overlay position without temporal smoothing
3. **Never** use adaptive thresholding in real-time (too slow)
4. **Always** run CV operations in a separate isolate
5. **Always** validate quad geometry before display

## File Structure

```
lib/
├── features/
│   └── scanner/
│       ├── domain/
│       │   ├── detected_quad.dart        # geometry-validation.md
│       │   └── quad_score.dart           # contour-detection.md
│       ├── data/
│       │   ├── frame_processor.dart      # isolate-pipeline.md
│       │   ├── preview_pipeline.dart     # contour-detection.md
│       │   ├── temporal_filter.dart      # temporal-filtering.md
│       │   └── capture_pipeline.dart     # capture-pipeline.md
│       └── presentation/
│           ├── quad_overlay_widget.dart  # overlay-rendering.md
│           ├── coordinate_transformer.dart # coordinate-transform.md
│           └── auto_capture_controller.dart # auto-capture.md
test/
├── unit/
│   ├── detected_quad_test.dart
│   ├── temporal_filter_test.dart
│   └── quad_scoring_test.dart
└── integration/
    └── frame_sequence_test.dart
```

## Implementation Order

Follow this sequence for incremental, testable development:

1. **geometry-validation.md** — Core data structures, fully unit-testable
2. **isolate-pipeline.md** — Frame sampling and isolate communication
3. **contour-detection.md** — OpenCV pipeline in isolate
4. **temporal-filtering.md** — Smoothing layer
5. **coordinate-transform.md** — Camera-to-canvas math
6. **overlay-rendering.md** — Visual feedback
7. **capture-pipeline.md** — Full-res processing
8. **auto-capture.md** — Trigger logic

## Configuration

All tunable parameters are centralized:

```dart
class EdgeDetectionConfig {
  // Frame sampling
  final int targetFps;                    // 8
  
  // Processing resolution  
  final int targetProcessingWidth;        // 480
  
  // Canny thresholds
  final double cannyLow;                  // 50
  final double cannyHigh;                 // 150
  
  // Contour filtering
  final double minAreaRatio;              // 0.15
  final double maxAreaRatio;              // 0.85
  
  // Temporal filtering
  final double smoothingAlpha;            // 0.25
  final double deadZoneThreshold;         // 0.005
  final int lockFrameCount;               // 5
  
  // Auto-capture
  final double captureConfidenceThreshold; // 0.85
  final Duration captureStabilityDuration; // 1500ms
}
```

## Testing Requirements

Every component must have:
1. **Unit tests** with synthetic inputs
2. **Edge case coverage** (null, empty, boundary values)
3. **Performance assertions** where applicable

See individual skill files for specific test requirements.

## Anti-Patterns to Avoid

| Don't | Do Instead |
|-------|------------|
| Process every camera frame | Sample at 8-10 fps |
| Run OpenCV on UI thread | Use isolates |
| Update overlay every frame | Apply temporal smoothing |
| Expect perfect detection | Design for graceful degradation |
| Use ML for basic edge detection | Use classical CV (Canny + contours) |

## Related Documentation

- `FEATURE_OVERVIEW.md` — Functional requirements and user flows
- Flutter `camera` plugin docs
- `opencv_dart` package documentation
