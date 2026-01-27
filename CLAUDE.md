# CLAUDE.md — OpenScan

Flutter document scanner with real-time edge detection.

---

## Core Rules

1. **Always testable** — Every commit must pass `flutter analyze` and `flutter test`
2. **Two-scenario tests** — Every feature needs happy path + failure path tests
3. **Incremental builds** — Small working increments, never leave broken state

---

## Architecture

```
lib/features/scanner/
  domain/      → entities, geometry types (no deps)
  data/        → pipelines, filters, repositories
  presentation/→ widgets, painters, screens
  application/ → orchestrators, controllers
```

**State**: Riverpod · **Navigation**: GoRouter · **Coordinates**: Normalized (0.0-1.0)

---

## Edge Detection Skills

Docs in `docs/skills/edge-detection/`. **Load only what's needed:**

| Task | Load |
|------|------|
| Quad geometry, points | `geometry-validation.md` |
| Isolate, frame sampling | `isolate-pipeline.md` |
| OpenCV, contours, scoring | `contour-detection.md` |
| Smoothing, locking | `temporal-filtering.md` |
| Coordinate mapping | `coordinate-transform.md` |
| Overlay painting | `overlay-rendering.md` |
| Full-res capture | `capture-pipeline.md` |
| Auto-capture logic | `auto-capture.md` |

**Dependency chain**: `geometry-validation` → all others → `overlay-rendering` → `capture-pipeline` → `auto-capture`

Read `SKILL.md` for architecture overview.

---

## Testing

```dart
// Name tests by scenario
test('detectEdges returns four corners when document is visible', () {});
test('detectEdges throws NoDocumentException when image is blank', () {});
```

| Component | Happy Path | Failure Path |
|-----------|-----------|--------------|
| UI Widget | Renders with valid data | Shows error/empty state |
| Service | Returns expected result | Throws/handles exception |
| Provider | State updates correctly | Handles edge cases |

---

## Commands

```bash
flutter analyze          # lint
flutter test             # all tests
flutter test test/unit/  # unit only
flutter run              # run on device
```

---

## Commits

Format: `<type>(<scope>): <description>`

Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`

```
feat(camera): add capture button with haptic feedback
fix(edge-detection): handle low-contrast images
test(geometry): add convexity validation tests
```

---

## Pre-Implementation Checklist

- [ ] Acceptance criteria understood
- [ ] Two test scenarios identified
- [ ] Relevant skill file(s) read
- [ ] Project builds, all tests pass

**If unclear, ask before implementing.**