# Overlay Rendering Skill

## Purpose

Render the quadrilateral overlay on the camera preview with smooth animations, confidence-based coloring, and proper visual feedback.

## Scope

- CustomPainter for quad rendering
- Color coding by detection state
- Opacity animations for fade in/out
- Corner indicators
- Locked state visualization
- Inset drawing for edge clarity

## Key Concepts

### Visual States

| State | Color | Opacity | Visual |
|-------|-------|---------|--------|
| No detection | — | 0% | Hidden |
| Low confidence (<0.5) | Orange | 50% | Faint outline |
| Medium confidence (0.5-0.7) | Orange | 80% | Visible outline |
| High confidence (0.7-0.85) | Blue | 100% | Solid outline |
| Locked (>0.85) | Green | 100% | Filled + outline |

### Drawing Strategy

1. Draw slightly inside detected edges (2% inset) for visual clarity
2. Round corners for smoother appearance
3. Add corner indicators (circles) at vertices
4. Use semi-transparent fill when locked

## Implementation

### Overlay Widget

```dart
import 'package:flutter/material.dart';

class QuadOverlayWidget extends StatefulWidget {
  final Stream<FilteredQuadState> stateStream;
  final QuadCoordinateTransformer transformer;

  const QuadOverlayWidget({
    super.key,
    required this.stateStream,
    required this.transformer,
  });

  @override
  State<QuadOverlayWidget> createState() => _QuadOverlayWidgetState();
}

class _QuadOverlayWidgetState extends State<QuadOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  FilteredQuadState? _currentState;
  late StreamSubscription<FilteredQuadState> _subscription;

  @override
  void initState() {
    super.initState();
    
    // Fade animation for appearing/disappearing
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Subscribe to state updates
    _subscription = widget.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });

      // Animate fade based on detection
      if (state.hasValidQuad) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: QuadOverlayPainter(
            state: _currentState,
            transformer: widget.transformer,
            opacity: _fadeAnimation.value,
          ),
        );
      },
    );
  }
}
```

### Custom Painter

```dart
class QuadOverlayPainter extends CustomPainter {
  final FilteredQuadState? state;
  final QuadCoordinateTransformer transformer;
  final double opacity;

  // Visual configuration
  static const double strokeWidth = 3.0;
  static const double cornerRadius = 8.0;
  static const double insetFactor = 0.02;

  QuadOverlayPainter({
    this.state,
    required this.transformer,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (state?.quad == null || opacity == 0) return;

    final quad = state!.quad!;
    final confidence = state!.confidence;
    final isLocked = state!.isLocked;

    // Transform to canvas coordinates
    final corners = transformer.transformQuad(quad);

    // Inset corners slightly for visual clarity
    final center = _calculateCenter(corners);
    final insetCorners = _insetCorners(corners, center, size);

    // Determine color based on state
    final color = _getColor(confidence, isLocked);

    // Draw fill (only when locked)
    if (isLocked) {
      _drawFill(canvas, insetCorners, color);
    }

    // Draw outline
    _drawOutline(canvas, insetCorners, color);

    // Draw corner indicators
    _drawCornerIndicators(canvas, insetCorners, color);
  }

  Offset _calculateCenter(List<Offset> corners) {
    final cx = corners.map((c) => c.dx).reduce((a, b) => a + b) / 4;
    final cy = corners.map((c) => c.dy).reduce((a, b) => a + b) / 4;
    return Offset(cx, cy);
  }

  List<Offset> _insetCorners(List<Offset> corners, Offset center, Size size) {
    final insetAmount = insetFactor * size.shortestSide;
    
    return corners.map((corner) {
      final direction = (corner - center);
      final normalized = direction / direction.distance;
      return corner - normalized * insetAmount;
    }).toList();
  }

  Color _getColor(double confidence, bool isLocked) {
    if (isLocked) {
      return Colors.green;
    } else if (confidence > 0.7) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  void _drawFill(Canvas canvas, List<Offset> corners, Color color) {
    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawOutline(Canvas canvas, List<Offset> corners, Color color) {
    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.9)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void _drawCornerIndicators(Canvas canvas, List<Offset> corners, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawCircle(corner, cornerRadius, paint);
    }
  }

  @override
  bool shouldRepaint(QuadOverlayPainter oldDelegate) {
    return state != oldDelegate.state ||
        opacity != oldDelegate.opacity ||
        transformer != oldDelegate.transformer;
  }
}
```

### Animated Corner Indicators

For more sophisticated corner indicators with pulse animation when locked:

```dart
class AnimatedQuadOverlayWidget extends StatefulWidget {
  final Stream<FilteredQuadState> stateStream;
  final QuadCoordinateTransformer transformer;

  const AnimatedQuadOverlayWidget({
    super.key,
    required this.stateStream,
    required this.transformer,
  });

  @override
  State<AnimatedQuadOverlayWidget> createState() =>
      _AnimatedQuadOverlayWidgetState();
}

class _AnimatedQuadOverlayWidgetState extends State<AnimatedQuadOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  FilteredQuadState? _currentState;
  late StreamSubscription<FilteredQuadState> _subscription;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Pulse animation for locked state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _subscription = widget.stateStream.listen(_onStateUpdate);
  }

  void _onStateUpdate(FilteredQuadState state) {
    final wasLocked = _currentState?.isLocked ?? false;
    final isNowLocked = state.isLocked;

    setState(() {
      _currentState = state;
    });

    // Handle fade
    if (state.hasValidQuad) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }

    // Handle pulse
    if (isNowLocked && !wasLocked) {
      // Just locked - start pulse
      _pulseController.repeat(reverse: true);
    } else if (!isNowLocked && wasLocked) {
      // Just unlocked - stop pulse
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _pulseAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: AnimatedQuadPainter(
            state: _currentState,
            transformer: widget.transformer,
            opacity: _fadeAnimation.value,
            cornerScale: _currentState?.isLocked == true
                ? _pulseAnimation.value
                : 1.0,
          ),
        );
      },
    );
  }
}

class AnimatedQuadPainter extends CustomPainter {
  final FilteredQuadState? state;
  final QuadCoordinateTransformer transformer;
  final double opacity;
  final double cornerScale;

  static const double baseCornerRadius = 8.0;

  AnimatedQuadPainter({
    this.state,
    required this.transformer,
    required this.opacity,
    required this.cornerScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (state?.quad == null || opacity == 0) return;

    // ... (same as before for fill and outline)

    // Animated corner indicators
    final corners = transformer.transformQuad(state!.quad!);
    final color = _getColor(state!.confidence, state!.isLocked);
    final effectiveRadius = baseCornerRadius * cornerScale;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawCircle(corner, effectiveRadius, paint);
    }
  }

  Color _getColor(double confidence, bool isLocked) {
    if (isLocked) return Colors.green;
    if (confidence > 0.7) return Colors.blue;
    return Colors.orange;
  }

  @override
  bool shouldRepaint(AnimatedQuadPainter oldDelegate) {
    return state != oldDelegate.state ||
        opacity != oldDelegate.opacity ||
        cornerScale != oldDelegate.cornerScale;
  }
}
```

### Capture Progress Indicator

```dart
class CaptureProgressOverlay extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final QuadCoordinateTransformer transformer;
  final DetectedQuad quad;

  const CaptureProgressOverlay({
    super.key,
    required this.progress,
    required this.transformer,
    required this.quad,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: CaptureProgressPainter(
        progress: progress,
        transformer: transformer,
        quad: quad,
      ),
    );
  }
}

class CaptureProgressPainter extends CustomPainter {
  final double progress;
  final QuadCoordinateTransformer transformer;
  final DetectedQuad quad;

  CaptureProgressPainter({
    required this.progress,
    required this.transformer,
    required this.quad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final corners = transformer.transformQuad(quad);

    // Draw progress along the quad outline
    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, trackPaint);

    // Progress indicator
    final progressPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate path metrics for partial drawing
    final pathMetrics = path.computeMetrics().first;
    final progressPath = pathMetrics.extractPath(
      0,
      pathMetrics.length * progress,
    );
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(CaptureProgressPainter oldDelegate) {
    return progress != oldDelegate.progress || quad != oldDelegate.quad;
  }
}
```

### Complete Widget Assembly

```dart
/// Full overlay stack with all visual elements
class ScannerOverlay extends StatelessWidget {
  final Stream<FilteredQuadState> stateStream;
  final QuadCoordinateTransformer transformer;
  final double? captureProgress;

  const ScannerOverlay({
    super.key,
    required this.stateStream,
    required this.transformer,
    this.captureProgress,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FilteredQuadState>(
      stream: stateStream,
      builder: (context, snapshot) {
        return Stack(
          children: [
            // Main quad overlay
            AnimatedQuadOverlayWidget(
              stateStream: stateStream,
              transformer: transformer,
            ),

            // Capture progress (when applicable)
            if (captureProgress != null && 
                snapshot.data?.quad != null &&
                snapshot.data!.isLocked)
              CaptureProgressOverlay(
                progress: captureProgress!,
                transformer: transformer,
                quad: snapshot.data!.quad!,
              ),
          ],
        );
      },
    );
  }
}
```

## Unit Tests

```dart
void main() {
  group('QuadOverlayPainter', () {
    test('returns correct color for locked state', () {
      expect(_getColor(0.9, true), equals(Colors.green));
    });

    test('returns blue for high confidence unlocked', () {
      expect(_getColor(0.8, false), equals(Colors.blue));
    });

    test('returns orange for low confidence', () {
      expect(_getColor(0.4, false), equals(Colors.orange));
    });
  });

  group('Corner inset calculation', () {
    test('insets toward center', () {
      final corners = [
        Offset(100, 100), // TL
        Offset(200, 100), // TR
        Offset(200, 200), // BR
        Offset(100, 200), // BL
      ];

      final center = Offset(150, 150);
      final inset = _insetCorners(corners, center, Size(300, 300));

      // All corners should move toward center
      expect(inset[0].dx, greaterThan(100));
      expect(inset[0].dy, greaterThan(100));
      expect(inset[2].dx, lessThan(200));
      expect(inset[2].dy, lessThan(200));
    });
  });
}

Color _getColor(double confidence, bool isLocked) {
  if (isLocked) return Colors.green;
  if (confidence > 0.7) return Colors.blue;
  return Colors.orange;
}

List<Offset> _insetCorners(List<Offset> corners, Offset center, Size size) {
  const insetFactor = 0.02;
  final insetAmount = insetFactor * size.shortestSide;

  return corners.map((corner) {
    final direction = corner - center;
    final normalized = direction / direction.distance;
    return corner - normalized * insetAmount;
  }).toList();
}
```

## Performance Considerations

1. **shouldRepaint** — Only repaint when state actually changes
2. **Path reuse** — Cache paths if quad hasn't moved
3. **Opacity animations** — Use AnimatedOpacity for simpler cases
4. **Layer composition** — Use RepaintBoundary if overlay updates frequently

## Common Pitfalls

1. **Missing shouldRepaint** — Causes unnecessary repaints every frame
2. **Heavy animations** — Keep animations simple, avoid complex shaders
3. **Opacity vs alpha** — Use `withOpacity()` consistently
4. **Z-order issues** — Ensure overlay is above camera preview

## Dependencies

- `coordinate-transform.md` (for `QuadCoordinateTransformer`)
- `temporal-filtering.md` (for `FilteredQuadState`)

## Related Skills

- `auto-capture.md` — Provides capture progress value
