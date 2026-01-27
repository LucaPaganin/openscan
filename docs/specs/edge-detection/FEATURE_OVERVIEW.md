# OpenScan Edge Detection — Functional Overview

## 1. Purpose

OpenScan's edge detection system provides real-time visual feedback during document scanning by displaying a stabilized quadrilateral overlay on the camera preview. When the system confidently detects a stable document, it automatically captures the image.

## 2. User Experience Goals

### What Users See
- Camera preview with a smooth, colored polygon overlay tracking document edges
- Overlay color indicates detection confidence:
  - **Orange**: Detecting, low confidence
  - **Blue**: Good detection, building confidence  
  - **Green**: Locked, ready for capture
- Overlay fades in/out gracefully rather than appearing/disappearing abruptly
- Corner indicators provide visual anchors
- Semi-transparent fill when locked signals "ready" state

### What Users Experience
- Overlay feels "attached" to the document — moves smoothly, never jitters
- Brief lag is acceptable; erratic jumping is not
- Auto-capture triggers after ~1.5 seconds of stable detection
- Capture progress indicator shows countdown to auto-trigger
- Manual capture always available as fallback

## 3. Functional Requirements

### FR-1: Real-Time Edge Detection
- System detects rectangular document edges during camera preview
- Detection runs at 8-10 fps (not every camera frame)
- Detection does not block UI — preview remains smooth at 30fps

### FR-2: Visual Overlay
- Quadrilateral overlay rendered over camera preview
- Corners ordered consistently: top-left → top-right → bottom-right → bottom-left
- Overlay drawn slightly inside detected edges for visual clarity
- Smooth corner movement with configurable easing

### FR-3: Stability & Confidence
- Overlay position stabilizes over multiple frames (temporal smoothing)
- Small movements ignored (dead-zone locking)
- Confidence builds over consecutive stable detections
- "Locked" state achieved after ~5 stable frames

### FR-4: Auto-Capture
- Auto-capture triggers when:
  - Detection is locked (stable for 5+ frames)
  - Confidence exceeds 85%
  - Locked state maintained for 1.5 seconds
- Visual progress indicator during countdown
- Capture can be triggered manually at any time

### FR-5: Capture Processing
- Full-resolution image captured (independent of preview)
- Edge detection re-runs on full-res image
- Perspective correction applied automatically
- If detection fails, user can adjust corners manually

### FR-6: Graceful Degradation
- Low-confidence detection: overlay shown with reduced opacity
- No detection: overlay fades out smoothly
- Motion blur/fast movement: overlay freezes at last known position
- Manual capture always available when auto-detection fails

## 4. Non-Functional Requirements

### Performance
| Metric | Target |
|--------|--------|
| Preview frame processing | < 30ms |
| UI frame rate | 60fps (no drops) |
| Memory growth (10min session) | < 50MB |
| Time to first detection | < 500ms |
| Lock stabilization | < 1 second |

### Quality
| Scenario | Expected Behavior |
|----------|-------------------|
| Static document, steady hand | Lock within 10 frames |
| Slow camera movement | Smooth overlay tracking with slight lag |
| Fast movement / blur | Overlay freezes, resumes when stable |
| Partial document visible | No detection (graceful fade) |
| Busy background, no document | No false positive detection |
| Poor lighting | Detection with reduced confidence |

## 5. User Flows

### Happy Path: Auto-Capture
```
1. User opens scanner
2. Points camera at document
3. Orange overlay appears, tracking edges
4. Overlay turns blue as confidence builds
5. Overlay turns green and locks
6. Progress indicator counts down (1.5s)
7. Auto-capture triggers
8. Cropped document displayed for review
```

### Fallback Path: Manual Adjustment
```
1. User opens scanner
2. Points camera at low-contrast document
3. Overlay appears intermittently, never locks
4. User taps manual capture button
5. Full-res image captured
6. System attempts detection on captured image
7. If detection fails, manual corner adjustment UI shown
8. User drags corners to correct positions
9. Perspective correction applied
```

### Edge Case: Motion During Capture
```
1. Document detected and locked
2. User's hand moves during countdown
3. Lock breaks, overlay turns blue/orange
4. Countdown resets
5. When stable again, countdown restarts
```

## 6. Success Criteria

### MVP (Phase 1)
- [ ] Overlay tracks document edges in real-time without jitter
- [ ] Overlay color reflects confidence state
- [ ] Auto-capture triggers on stable detection
- [ ] Manual capture works as fallback
- [ ] Perspective correction produces rectangular output

### Quality Bar
- [ ] 90% of static documents detected within 2 seconds
- [ ] Zero UI frame drops during detection
- [ ] No false positives on plain backgrounds
- [ ] Overlay movement indistinguishable from native scanning apps

## 7. Out of Scope (Phase 1)

- Multi-document detection (batch scanning)
- Curved page detection / dewarping
- OCR integration
- Cloud processing
- ML-based detection

## 8. Dependencies

| Dependency | Purpose |
|------------|---------|
| `camera` plugin | Camera preview and capture |
| `opencv_dart` | Edge detection, contour finding |
| Riverpod | State management |
| Flutter CustomPainter | Overlay rendering |

## 9. Testing Strategy

### Automated Testing
- Unit tests for geometry validation (convexity, angles, ordering)
- Unit tests for temporal filtering math
- Unit tests for scoring functions
- Integration tests with recorded frame sequences

### Manual Testing
- Various document types (white paper, receipts, books, cards)
- Various lighting conditions (bright, dim, uneven, shadows)
- Various backgrounds (wood, fabric, cluttered desk)
- Device orientations (portrait, landscape)
- Edge cases (partial visibility, reflections, creases)

## 10. Acceptance Criteria Summary

| ID | Criteria | Validation |
|----|----------|------------|
| AC-1 | Overlay appears within 500ms of document entering frame | Stopwatch test |
| AC-2 | Overlay does not jitter when camera is steady | Visual inspection |
| AC-3 | Auto-capture triggers within 3s of stable document | Stopwatch test |
| AC-4 | Captured image has correct perspective | Visual inspection |
| AC-5 | UI maintains 60fps during detection | Performance profiler |
| AC-6 | No detection on plain background (no document) | Functional test |
| AC-7 | Manual capture works when auto-detection fails | Functional test |
