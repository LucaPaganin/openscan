# Example Prompts for Claude Code

Copy-paste these prompts to implement OpenScan features efficiently.

---

## Phase 1: Core Geometry (No dependencies)

### Prompt 1.1 — NormalizedPoint & DetectedQuad

```
Read docs/skills/edge-detection/geometry-validation.md

Implement:
1. lib/features/scanner/domain/normalized_point.dart
2. lib/features/scanner/domain/detected_quad.dart
3. test/unit/normalized_point_test.dart
4. test/unit/detected_quad_test.dart

Include all geometry methods from the skill file. Run tests to verify.
```

---

## Phase 2: Isolate Infrastructure

### Prompt 2.1 — Frame Processor Setup

```
Read:
- docs/skills/edge-detection/geometry-validation.md (for types)
- docs/skills/edge-detection/isolate-pipeline.md

Implement:
1. lib/features/scanner/data/frame_data.dart (FrameData, DetectionResult)
2. lib/features/scanner/data/frame_processor.dart (isolate spawn, communication)
3. test/unit/frame_processor_test.dart

Focus on isolate lifecycle and frame throttling. Skip actual CV processing for now (return null detection).
```

---

## Phase 3: Detection Pipeline

### Prompt 3.1 — Contour Detection

```
Read:
- docs/skills/edge-detection/geometry-validation.md (for types)
- docs/skills/edge-detection/contour-detection.md

Implement:
1. lib/features/scanner/data/contour_detection_config.dart
2. lib/features/scanner/data/quad_scorer.dart
3. lib/features/scanner/data/contour_detection_pipeline.dart
4. test/unit/quad_scorer_test.dart

This runs inside the isolate. Use opencv_dart for CV operations.
```

### Prompt 3.2 — Temporal Filter

```
Read:
- docs/skills/edge-detection/geometry-validation.md (for DetectedQuad)
- docs/skills/edge-detection/temporal-filtering.md

Implement:
1. lib/features/scanner/data/temporal_filter_config.dart
2. lib/features/scanner/data/filtered_quad_state.dart
3. lib/features/scanner/data/temporal_quad_filter.dart
4. test/unit/temporal_quad_filter_test.dart

Test smoothing math, dead-zone, and confidence locking independently.
```

---

## Phase 4: UI Layer

### Prompt 4.1 — Coordinate Transformer

```
Read:
- docs/skills/edge-detection/geometry-validation.md (for NormalizedPoint)
- docs/skills/edge-detection/coordinate-transform.md

Implement:
1. lib/features/scanner/presentation/coordinate_transformer.dart
2. test/unit/coordinate_transformer_test.dart

Test all orientations (0°, 90°, 180°, 270°) and front camera mirroring.
```

### Prompt 4.2 — Overlay Widget

```
Read:
- docs/skills/edge-detection/coordinate-transform.md (for transformer interface)
- docs/skills/edge-detection/overlay-rendering.md

Implement:
1. lib/features/scanner/presentation/quad_overlay_painter.dart
2. lib/features/scanner/presentation/quad_overlay_widget.dart

Use CustomPainter. Include fade animation and color states (orange/blue/green).
```

---

## Phase 5: Capture Flow

### Prompt 5.1 — Capture Pipeline

```
Read:
- docs/skills/edge-detection/geometry-validation.md
- docs/skills/edge-detection/capture-pipeline.md

Implement:
1. lib/features/scanner/application/capture_result.dart
2. lib/features/scanner/application/capture_detection_pipeline.dart
3. lib/features/scanner/application/manual_crop_processor.dart
4. test/unit/capture_pipeline_test.dart

Runs in isolate. Include perspective transform.
```

### Prompt 5.2 — Auto-Capture Controller

```
Read:
- docs/skills/edge-detection/temporal-filtering.md (for FilteredQuadState)
- docs/skills/edge-detection/capture-pipeline.md (for CaptureResult)
- docs/skills/edge-detection/auto-capture.md

Implement:
1. lib/features/scanner/application/auto_capture_config.dart
2. lib/features/scanner/application/auto_capture_state.dart
3. lib/features/scanner/application/auto_capture_controller.dart
4. test/unit/auto_capture_controller_test.dart

Test countdown, reset on condition break, and manual capture bypass.
```

---

## Integration Prompts

### Full Preview Pipeline Integration

```
Read docs/skills/edge-detection/SKILL.md for architecture overview.

Wire together:
- FrameProcessor (isolate)
- ContourDetectionPipeline
- TemporalQuadFilter
- QuadStateProvider (Riverpod)

Create lib/features/scanner/data/preview_detection_pipeline.dart that combines these.
Verify frame processing stays under 30ms.
```

### Full Scanner Screen

```
Read docs/skills/edge-detection/SKILL.md

Create lib/features/scanner/presentation/scanner_screen.dart that integrates:
- CameraPreview
- QuadOverlayWidget
- AutoCaptureProgressIndicator
- Manual capture button

Use Riverpod providers for state. Handle all CaptureResult cases.
```

---

## Debugging Prompts

### Performance Issue

```
Frame processing exceeds 30ms target.

Read docs/skills/edge-detection/contour-detection.md, section "Performance Considerations".

Profile and identify bottleneck. Likely candidates:
- Resolution too high (should be 480p)
- Too many contours being processed
- Edge strength calculation too dense
```

### Jittery Overlay

```
Overlay jitters despite stable document.

Read docs/skills/edge-detection/temporal-filtering.md, section "Tuning Guide".

Check:
- Is smoothingAlpha too high? (should be 0.2-0.3)
- Is deadZoneThreshold too low? (should be ~0.005)
- Is temporal filter being applied?
```