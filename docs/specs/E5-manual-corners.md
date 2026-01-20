# Epic 5: Manual Corner Adjustment

## Epic Overview

**Goal**: Allow users to manually adjust the detected document corners before processing. This epic provides the essential escape hatch when automatic edge detection isn't perfect — users can drag corners to precisely define the document boundary.

**Duration**: 1 Sprint (1 week)

**Epic Owner**: Luca (Scrum Master)

**Phase**: 1 (Flutter MVP — No Backend Required)

**Dependencies**: E4 (Edge Detection) must be complete

---

## Success Criteria

By the end of this epic:
- [ ] After capture, user sees a crop/adjust screen
- [ ] Four corner handles are displayed on the captured image
- [ ] User can drag any corner to reposition it
- [ ] Quadrilateral updates in real-time as corners move
- [ ] User can confirm or retake the photo
- [ ] Adjusted corners are passed to perspective correction (E6)
- [ ] Edge magnifier shows zoomed view while dragging
- [ ] All tests pass with success and failure scenarios

---

## User Flow

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────────┐
│   Camera    │────▶│  Corner Adjust  │────▶│   Processing     │
│   Capture   │     │     Screen      │     │  (E6: Perspective)│
└─────────────┘     └─────────────────┘     └──────────────────┘
                           │
                           │ Retake
                           ▼
                    ┌─────────────┐
                    │   Camera    │
                    └─────────────┘
```

---

## User Stories

### US-5.1: Corner Adjustment Screen

**As a** user  
**I want** to review my captured image before processing  
**So that** I can verify the document boundaries are correct

**Acceptance Criteria**:
- Screen displays the captured image
- Image fits within the screen with padding
- Initial corner positions come from edge detection (or defaults to image corners)
- App bar has "Retake" and "Confirm" actions
- Background is dark to focus attention on the image

**UI Specifications**:
```
┌─────────────────────────────────────────┐
│ ←  Adjust Corners              Confirm ✓│
├─────────────────────────────────────────┤
│                                         │
│   ●───────────────────────────●         │
│   │                           │         │
│   │                           │         │
│   │      [Captured Image]     │         │
│   │                           │         │
│   │                           │         │
│   ●───────────────────────────●         │
│                                         │
│        Drag corners to adjust           │
└─────────────────────────────────────────┘
```

**Implementation**:
```dart
// lib/features/document/presentation/screens/corner_adjustment_screen.dart

class CornerAdjustmentScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final DetectedDocument? initialDetection;
  
  const CornerAdjustmentScreen({
    super.key,
    required this.imagePath,
    this.initialDetection,
  });

  @override
  ConsumerState<CornerAdjustmentScreen> createState() => 
      _CornerAdjustmentScreenState();
}

class _CornerAdjustmentScreenState 
    extends ConsumerState<CornerAdjustmentScreen> {
  late List<Offset> _corners;
  Size? _imageSize;
  int? _activeCornerIndex;
  
  @override
  void initState() {
    super.initState();
    _initCorners();
  }
  
  void _initCorners() {
    if (widget.initialDetection != null) {
      // Use detected corners (normalized to 0-1)
      _corners = widget.initialDetection!.normalizedCorners
          .map((p) => Offset(p.x, p.y))
          .toList();
    } else {
      // Default to full image with 10% margin
      _corners = const [
        Offset(0.1, 0.1),   // Top-left
        Offset(0.9, 0.1),   // Top-right
        Offset(0.9, 0.9),   // Bottom-right
        Offset(0.1, 0.9),   // Bottom-left
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _retake,
          tooltip: 'Retake',
        ),
        title: const Text('Adjust Corners'),
        actions: [
          TextButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: CornerAdjustmentWidget(
                imagePath: widget.imagePath,
                corners: _corners,
                activeCornerIndex: _activeCornerIndex,
                onCornerDragStart: _onCornerDragStart,
                onCornerDragUpdate: _onCornerDragUpdate,
                onCornerDragEnd: _onCornerDragEnd,
                onImageSizeCalculated: (size) {
                  _imageSize = size;
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Drag corners to adjust document boundaries',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  void _onCornerDragStart(int index) {
    setState(() => _activeCornerIndex = index);
    HapticFeedback.selectionClick();
  }
  
  void _onCornerDragUpdate(int index, Offset normalizedPosition) {
    setState(() {
      _corners[index] = _clampToImage(normalizedPosition);
    });
  }
  
  void _onCornerDragEnd(int index) {
    setState(() => _activeCornerIndex = null);
  }
  
  Offset _clampToImage(Offset position) {
    return Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );
  }
  
  void _retake() {
    // Navigate back to camera
    context.go('/');
  }
  
  void _confirm() {
    // Navigate to next step with adjusted corners
    final adjustedCorners = _corners
        .map((o) => Point(o.dx, o.dy))
        .toList();
    
    context.push(
      '/process',
      extra: ProcessingArgs(
        imagePath: widget.imagePath,
        corners: adjustedCorners,
      ),
    );
  }
}
```

**Tests Required**:
- ✅ Screen displays image with initial corner positions from detection
- ✅ Screen defaults to margin corners when no detection provided

---

### US-5.2: Corner Handle Widget

**As a** user  
**I want** visible and draggable corner handles  
**So that** I can easily grab and move them

**Acceptance Criteria**:
- Corner handles are large enough to tap (minimum 44x44 touch target)
- Handles are visually distinct (colored circles with border)
- Active handle (being dragged) has different appearance
- Handles display outside the document area for easier grabbing

**Implementation**:
```dart
// lib/features/document/presentation/widgets/corner_handle.dart

class CornerHandle extends StatelessWidget {
  final Offset position;
  final bool isActive;
  final int cornerIndex;
  final Function(int) onDragStart;
  final Function(int, Offset) onDragUpdate;
  final Function(int) onDragEnd;
  
  const CornerHandle({
    super.key,
    required this.position,
    required this.isActive,
    required this.cornerIndex,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 22, // Center the 44x44 touch target
      top: position.dy - 22,
      child: GestureDetector(
        onPanStart: (_) => onDragStart(cornerIndex),
        onPanUpdate: (details) {
          final newPos = Offset(
            position.dx + details.delta.dx,
            position.dy + details.delta.dy,
          );
          onDragUpdate(cornerIndex, newPos);
        },
        onPanEnd: (_) => onDragEnd(cornerIndex),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isActive ? 28 : 24,
              height: isActive ? 28 : 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive 
                    ? const Color(0xFF2196F3)  // Blue when active
                    : const Color(0xFF4CAF50), // Green normally
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
- ✅ Corner handle renders at correct position
- ✅ Corner handle shows active state when isActive is true

---

### US-5.3: Quadrilateral Overlay

**As a** user  
**I want** to see the document boundary as I adjust corners  
**So that** I can visualize the crop area

**Acceptance Criteria**:
- Lines connect all four corners forming a quadrilateral
- Fill area is semi-transparent
- Area outside the quadrilateral is dimmed (scrim effect)
- Updates in real-time as corners are dragged

**Implementation**:
```dart
// lib/features/document/presentation/widgets/crop_overlay.dart

class CropOverlay extends StatelessWidget {
  final List<Offset> corners; // Pixel positions
  final Size imageSize;
  
  const CropOverlay({
    super.key,
    required this.corners,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: imageSize,
      painter: _CropOverlayPainter(corners: corners),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final List<Offset> corners;
  
  _CropOverlayPainter({required this.corners});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;
    
    // Create document path
    final documentPath = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();
    
    // Create full screen path
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Combine paths to create scrim (area outside document)
    final scrimPath = Path.combine(
      PathOperation.difference,
      fullPath,
      documentPath,
    );
    
    // Draw scrim (dimmed area outside document)
    final scrimPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(scrimPath, scrimPaint);
    
    // Draw document border
    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(documentPath, borderPaint);
    
    // Draw grid lines (rule of thirds) inside document
    _drawGridLines(canvas, corners);
  }
  
  void _drawGridLines(Canvas canvas, List<Offset> corners) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    
    // Interpolate points along edges for grid
    for (int i = 1; i <= 2; i++) {
      final t = i / 3.0;
      
      // Horizontal lines
      final leftPoint = Offset.lerp(corners[0], corners[3], t)!;
      final rightPoint = Offset.lerp(corners[1], corners[2], t)!;
      canvas.drawLine(leftPoint, rightPoint, gridPaint);
      
      // Vertical lines
      final topPoint = Offset.lerp(corners[0], corners[1], t)!;
      final bottomPoint = Offset.lerp(corners[3], corners[2], t)!;
      canvas.drawLine(topPoint, bottomPoint, gridPaint);
    }
  }
  
  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) {
    return corners != oldDelegate.corners;
  }
}
```

**Tests Required**:
- ✅ Overlay draws quadrilateral connecting four corners
- ✅ Overlay draws scrim outside document area

---

### US-5.4: Edge Magnifier

**As a** user  
**I want** a magnified view when dragging corners  
**So that** I can precisely position the corner on the document edge

**Acceptance Criteria**:
- Magnifier appears when dragging starts
- Shows 3x zoom of area around the active corner
- Magnifier positioned away from finger (top of screen if dragging bottom, etc.)
- Crosshair indicates exact corner position
- Magnifier disappears when dragging ends

**Implementation**:
```dart
// lib/features/document/presentation/widgets/edge_magnifier.dart

class EdgeMagnifier extends StatelessWidget {
  final Offset cornerPosition; // Position in widget coordinates
  final int cornerIndex;
  final String imagePath;
  final Size imageDisplaySize;
  final Size actualImageSize;
  
  static const double magnifierSize = 120;
  static const double zoomFactor = 3.0;
  
  const EdgeMagnifier({
    super.key,
    required this.cornerPosition,
    required this.cornerIndex,
    required this.imagePath,
    required this.imageDisplaySize,
    required this.actualImageSize,
  });

  @override
  Widget build(BuildContext context) {
    // Position magnifier opposite to corner being dragged
    final isTopCorner = cornerIndex < 2;
    final isLeftCorner = cornerIndex == 0 || cornerIndex == 3;
    
    final magnifierTop = isTopCorner 
        ? imageDisplaySize.height - magnifierSize - 20 
        : 20.0;
    final magnifierLeft = isLeftCorner
        ? imageDisplaySize.width - magnifierSize - 20
        : 20.0;
    
    return Positioned(
      top: magnifierTop,
      left: magnifierLeft,
      child: Container(
        width: magnifierSize,
        height: magnifierSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              // Zoomed image section
              _buildZoomedImage(),
              
              // Crosshair
              Center(
                child: CustomPaint(
                  size: Size(magnifierSize, magnifierSize),
                  painter: _CrosshairPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildZoomedImage() {
    // Calculate the region to display
    final scaleX = actualImageSize.width / imageDisplaySize.width;
    final scaleY = actualImageSize.height / imageDisplaySize.height;
    
    final sourceX = cornerPosition.dx * scaleX;
    final sourceY = cornerPosition.dy * scaleY;
    
    final viewportSize = magnifierSize / zoomFactor;
    
    return OverflowBox(
      maxWidth: actualImageSize.width * zoomFactor / scaleX,
      maxHeight: actualImageSize.height * zoomFactor / scaleY,
      child: Transform.translate(
        offset: Offset(
          -sourceX * zoomFactor / scaleX + magnifierSize / 2,
          -sourceY * zoomFactor / scaleY + magnifierSize / 2,
        ),
        child: Transform.scale(
          scale: zoomFactor,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.none,
          ),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - 15, center.dy),
      Offset(center.dx + 15, center.dy),
      paint,
    );
    
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - 15),
      Offset(center.dx, center.dy + 15),
      paint,
    );
    
    // Center dot
    canvas.drawCircle(center, 3, paint..style = PaintingStyle.fill);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

**Tests Required**:
- ✅ Magnifier positions opposite to the active corner
- ✅ Magnifier shows crosshair at center

---

### US-5.5: Corner Adjustment Widget (Composite)

**As a** developer  
**I want** a single widget that combines all adjustment functionality  
**So that** integration is clean and simple

**Acceptance Criteria**:
- Widget displays the image
- Widget calculates proper image display size
- Widget positions corner handles correctly
- Widget shows crop overlay
- Widget shows magnifier when dragging
- All coordinates are properly translated between normalized and pixel space

**Implementation**:
```dart
// lib/features/document/presentation/widgets/corner_adjustment_widget.dart

class CornerAdjustmentWidget extends StatefulWidget {
  final String imagePath;
  final List<Offset> corners; // Normalized (0-1)
  final int? activeCornerIndex;
  final Function(int) onCornerDragStart;
  final Function(int, Offset) onCornerDragUpdate; // Returns normalized
  final Function(int) onCornerDragEnd;
  final Function(Size)? onImageSizeCalculated;
  
  const CornerAdjustmentWidget({
    super.key,
    required this.imagePath,
    required this.corners,
    required this.activeCornerIndex,
    required this.onCornerDragStart,
    required this.onCornerDragUpdate,
    required this.onCornerDragEnd,
    this.onImageSizeCalculated,
  });

  @override
  State<CornerAdjustmentWidget> createState() => 
      _CornerAdjustmentWidgetState();
}

class _CornerAdjustmentWidgetState extends State<CornerAdjustmentWidget> {
  Size? _imageDisplaySize;
  Size? _actualImageSize;
  final GlobalKey _imageKey = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<Size>(
          future: _getImageSize(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            _actualImageSize = snapshot.data!;
            _imageDisplaySize = _calculateDisplaySize(
              snapshot.data!,
              constraints,
            );
            
            widget.onImageSizeCalculated?.call(_imageDisplaySize!);
            
            final pixelCorners = _toPixelCoordinates(widget.corners);
            
            return Center(
              child: SizedBox(
                width: _imageDisplaySize!.width,
                height: _imageDisplaySize!.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background image
                    Positioned.fill(
                      child: Image.file(
                        File(widget.imagePath),
                        key: _imageKey,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    // Crop overlay
                    Positioned.fill(
                      child: CropOverlay(
                        corners: pixelCorners,
                        imageSize: _imageDisplaySize!,
                      ),
                    ),
                    
                    // Corner handles
                    for (int i = 0; i < 4; i++)
                      CornerHandle(
                        position: pixelCorners[i],
                        isActive: widget.activeCornerIndex == i,
                        cornerIndex: i,
                        onDragStart: widget.onCornerDragStart,
                        onDragUpdate: (index, pixelPos) {
                          final normalized = _toNormalizedCoordinates(pixelPos);
                          widget.onCornerDragUpdate(index, normalized);
                        },
                        onDragEnd: widget.onCornerDragEnd,
                      ),
                    
                    // Magnifier (only when dragging)
                    if (widget.activeCornerIndex != null)
                      EdgeMagnifier(
                        cornerPosition: pixelCorners[widget.activeCornerIndex!],
                        cornerIndex: widget.activeCornerIndex!,
                        imagePath: widget.imagePath,
                        imageDisplaySize: _imageDisplaySize!,
                        actualImageSize: _actualImageSize!,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Future<Size> _getImageSize() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }
  
  Size _calculateDisplaySize(Size imageSize, BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth - 32; // Padding
    final maxHeight = constraints.maxHeight - 32;
    
    final imageAspect = imageSize.width / imageSize.height;
    final containerAspect = maxWidth / maxHeight;
    
    if (imageAspect > containerAspect) {
      // Image is wider than container
      return Size(maxWidth, maxWidth / imageAspect);
    } else {
      // Image is taller than container
      return Size(maxHeight * imageAspect, maxHeight);
    }
  }
  
  List<Offset> _toPixelCoordinates(List<Offset> normalized) {
    if (_imageDisplaySize == null) return normalized;
    
    return normalized.map((n) => Offset(
      n.dx * _imageDisplaySize!.width,
      n.dy * _imageDisplaySize!.height,
    )).toList();
  }
  
  Offset _toNormalizedCoordinates(Offset pixel) {
    if (_imageDisplaySize == null) return pixel;
    
    return Offset(
      pixel.dx / _imageDisplaySize!.width,
      pixel.dy / _imageDisplaySize!.height,
    );
  }
}
```

**Tests Required**:
- ✅ Widget converts normalized corners to pixel coordinates correctly
- ✅ Widget converts pixel coordinates back to normalized on drag update

---

### US-5.6: Validation and Constraints

**As a** user  
**I want** corners to stay within valid bounds  
**So that** I can't create an invalid crop area

**Acceptance Criteria**:
- Corners cannot be dragged outside the image
- Corners cannot cross over each other (maintains convex quadrilateral)
- Visual feedback when hitting constraints
- Haptic feedback on constraint hit

**Implementation**:
```dart
// lib/features/document/domain/services/corner_validation_service.dart

class CornerValidationService {
  /// Validates and constrains corner position.
  /// Returns the constrained position.
  static Offset constrainCorner({
    required int cornerIndex,
    required Offset proposedPosition,
    required List<Offset> currentCorners,
    double minDistance = 0.1, // Minimum 10% distance between corners
  }) {
    var constrained = Offset(
      proposedPosition.dx.clamp(0.0, 1.0),
      proposedPosition.dy.clamp(0.0, 1.0),
    );
    
    // Ensure corners don't cross
    constrained = _preventCrossing(
      cornerIndex,
      constrained,
      currentCorners,
      minDistance,
    );
    
    return constrained;
  }
  
  static Offset _preventCrossing(
    int index,
    Offset proposed,
    List<Offset> corners,
    double minDist,
  ) {
    // Create a copy with proposed change
    final testCorners = List<Offset>.from(corners);
    testCorners[index] = proposed;
    
    // Check if resulting quadrilateral is convex
    if (!_isConvex(testCorners)) {
      // Return current position (reject the move)
      return corners[index];
    }
    
    // Check minimum distances to adjacent corners
    final prevIndex = (index - 1 + 4) % 4;
    final nextIndex = (index + 1) % 4;
    
    final distToPrev = (proposed - corners[prevIndex]).distance;
    final distToNext = (proposed - corners[nextIndex]).distance;
    
    if (distToPrev < minDist || distToNext < minDist) {
      return corners[index];
    }
    
    return proposed;
  }
  
  static bool _isConvex(List<Offset> corners) {
    // Check if all cross products have the same sign
    int sign = 0;
    
    for (int i = 0; i < 4; i++) {
      final o1 = corners[i];
      final o2 = corners[(i + 1) % 4];
      final o3 = corners[(i + 2) % 4];
      
      final cross = (o2.dx - o1.dx) * (o3.dy - o2.dy) -
                    (o2.dy - o1.dy) * (o3.dx - o2.dx);
      
      if (cross != 0) {
        if (sign == 0) {
          sign = cross > 0 ? 1 : -1;
        } else if ((cross > 0 ? 1 : -1) != sign) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Checks if the quadrilateral is reasonably shaped for a document
  static bool isValidDocumentShape(List<Offset> corners) {
    if (!_isConvex(corners)) return false;
    
    // Calculate area (should be at least 5% of image)
    final area = _calculateArea(corners);
    if (area < 0.05) return false;
    
    return true;
  }
  
  static double _calculateArea(List<Offset> corners) {
    // Shoelace formula for polygon area
    double area = 0;
    for (int i = 0; i < 4; i++) {
      final j = (i + 1) % 4;
      area += corners[i].dx * corners[j].dy;
      area -= corners[j].dx * corners[i].dy;
    }
    return (area.abs() / 2);
  }
}
```

**Integration in adjustment screen**:
```dart
void _onCornerDragUpdate(int index, Offset normalizedPosition) {
  final constrained = CornerValidationService.constrainCorner(
    cornerIndex: index,
    proposedPosition: normalizedPosition,
    currentCorners: _corners,
  );
  
  // Haptic feedback if constrained
  if (constrained != normalizedPosition) {
    HapticFeedback.heavyImpact();
  }
  
  setState(() {
    _corners[index] = constrained;
  });
}
```

**Tests Required**:
- ✅ `constrainCorner()` clamps position to 0-1 range
- ✅ `constrainCorner()` prevents non-convex quadrilateral

---

### US-5.7: Navigation Integration

**As a** developer  
**I want** proper navigation to and from the adjustment screen  
**So that** the user flow is seamless

**Acceptance Criteria**:
- Camera capture navigates to adjustment screen with image path and detection
- Retake navigates back to camera (clears captured image)
- Confirm navigates to processing/next step with corners data
- Back button acts as Retake

**Route Configuration**:
```dart
// lib/router/app_router.dart (add route)

GoRoute(
  path: '/adjust',
  builder: (context, state) {
    final args = state.extra as AdjustmentArgs;
    return CornerAdjustmentScreen(
      imagePath: args.imagePath,
      initialDetection: args.detection,
    );
  },
),

// lib/features/document/domain/models/adjustment_args.dart

class AdjustmentArgs {
  final String imagePath;
  final DetectedDocument? detection;
  
  const AdjustmentArgs({
    required this.imagePath,
    this.detection,
  });
}

// lib/features/document/domain/models/processing_args.dart

class ProcessingArgs {
  final String imagePath;
  final List<Point> corners;
  
  const ProcessingArgs({
    required this.imagePath,
    required this.corners,
  });
}
```

**From Camera Screen (after capture)**:
```dart
Future<void> _onCaptureComplete(CapturedImage image) async {
  final detection = ref.read(detectionNotifierProvider);
  
  context.push(
    '/adjust',
    extra: AdjustmentArgs(
      imagePath: image.path,
      detection: detection,
    ),
  );
}
```

**Tests Required**:
- ✅ Confirm button passes corners to next screen
- ✅ Retake button navigates back to camera

---

## Definition of Done

- [ ] Adjustment screen displays captured image
- [ ] Four corner handles are visible and draggable
- [ ] Quadrilateral overlay updates in real-time
- [ ] Magnifier appears when dragging corners
- [ ] Corners cannot create invalid (non-convex) shapes
- [ ] Retake returns to camera
- [ ] Confirm passes corners to processing step
- [ ] Initial corners come from edge detection when available
- [ ] All tests pass (minimum 2 scenarios per component)
- [ ] No lint warnings

---

## Out of Scope

The following are explicitly NOT part of this epic:
- Perspective correction processing (Epic 6)
- Auto-adjusting corners based on edges
- Undo/redo for corner adjustments
- Preset aspect ratios (A4, Letter, etc.)
- Rotation controls

---

## Implementation Order

Suggested order for Claude Code:

1. Create Point class (if not already from E4)
2. Create AdjustmentArgs and ProcessingArgs models
3. Create CornerValidationService
4. Create CornerHandle widget
5. Create CropOverlay widget with CustomPainter
6. Create EdgeMagnifier widget
7. Create CornerAdjustmentWidget (composite)
8. Create CornerAdjustmentScreen
9. Add route configuration
10. Update camera capture flow to navigate to adjustment
11. Write tests for all components
12. Run `flutter analyze` and fix issues

---

## Notes for Claude Code

When implementing this epic:

1. **Coordinate systems** — Be careful with normalized (0-1) vs pixel coordinates
2. **Touch targets** — Ensure handles are at least 44x44 for accessibility
3. **Performance** — CustomPainter should be efficient; avoid unnecessary repaints
4. **Image loading** — Cache image size calculation; don't reload on every build
5. **Haptics** — Use HapticFeedback for tactile response on constraints
6. **Follow CLAUDE.md** — Especially the two-scenario testing requirement

---

## Confirmed Decisions

- **Handle size**: 24dp visible, 44dp touch target
- **Magnifier zoom**: 3x
- **Magnifier size**: 120x120dp
- **Minimum corner distance**: 10% of image dimension
- **Scrim opacity**: 50% black
- **Active handle color**: Blue (#2196F3)
- **Normal handle color**: Green (#4CAF50)