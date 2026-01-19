# Epic 1: Project Setup

## Epic Overview

**Goal**: Establish the foundational Flutter project structure for a cross-platform document scanner app. Backend scaffolding is deferred to Phase 2 (Epic 9). This epic creates the mobile app foundation upon which all Phase 1 features will be built.

**Duration**: 1 Sprint (1 week)

**Epic Owner**: Luca (Scrum Master)

**Phase**: 1 (Flutter MVP — No Backend Required)

---

## Success Criteria

By the end of this epic:
- [ ] Flutter mobile app runs on both iOS and Android emulators/simulators
- [ ] Project structure follows established conventions and is ready for feature development
- [ ] Basic navigation shell exists (empty screens as placeholders)
- [ ] State management is configured and demonstrated with a simple example
- [ ] Local storage foundation is in place
- [ ] All code passes linting with zero warnings

---

## User Stories

### US-1.1: Flutter Project Initialization

**As a** developer  
**I want** a properly structured Flutter project  
**So that** I can build features on a solid foundation

**Acceptance Criteria**:
- Flutter project created with null safety enabled
- Minimum SDK: Flutter 3.19+, Dart 3.3+
- App ID: `com.lucaplawliet.openscan`
- App name: "OpenScan"
- Project compiles and runs on both iOS simulator and Android emulator
- `.gitignore` properly configured for Flutter

**Technical Notes**:
```bash
flutter create --org com.lucaplawliet --project-name openscan .
```

---

### US-1.2: Folder Structure Setup

**As a** developer  
**I want** a clean, scalable folder structure  
**So that** the codebase remains maintainable as it grows

**Acceptance Criteria**:

Mobile app structure (`/mobile`):
```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # App widget, theme, router setup
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   ├── utils/
│   │   │   └── logger.dart
│   │   └── errors/
│   │       └── exceptions.dart
│   ├── features/
│   │   ├── camera/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   └── widgets/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   ├── gallery/
│   │   │   ├── presentation/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   └── document/
│   │       ├── presentation/
│   │       ├── domain/
│   │       └── data/
│   ├── shared/
│   │   ├── widgets/
│   │   └── services/
│   │       └── storage_service.dart
│   └── router/
│       └── app_router.dart
├── assets/
│   ├── images/
│   └── icons/
├── test/
└── pubspec.yaml
```

Root structure:
```
openscan/
├── mobile/                         # Flutter app
├── docs/                           # Documentation
│   └── specs/                      # Feature specifications
├── .github/
│   └── workflows/                  # CI/CD pipelines
├── CLAUDE.md                       # Development standards
├── README.md
└── .gitignore
```

**Note**: `/backend` folder will be added in Phase 2 (Epic 9) when curve flattening is implemented.

---

### US-1.3: State Management Setup (Riverpod)

**As a** developer  
**I want** a configured state management solution  
**So that** I can manage app state predictably across features

**Acceptance Criteria**:
- Riverpod 2.x installed and configured
- `ProviderScope` wrapping the app
- One example provider demonstrating the pattern (e.g., theme mode toggle)
- Code generation setup with `riverpod_generator` and `build_runner`

**Dependencies to add**:
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
```

**Example Provider** (`lib/core/providers/theme_provider.dart`):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeMode extends _$ThemeMode {
  @override
  bool build() => false; // false = light, true = dark
  
  void toggle() => state = !state;
}
```

---

### US-1.4: Navigation Setup (GoRouter)

**As a** developer  
**I want** declarative routing configured  
**So that** I can navigate between screens with type-safe routes

**Acceptance Criteria**:
- GoRouter installed and configured
- Routes defined for placeholder screens:
  - `/` → Home/Camera screen (placeholder)
  - `/gallery` → Gallery screen (placeholder)
  - `/document/:id` → Document detail screen (placeholder)
  - `/settings` → Settings screen (placeholder)
- Bottom navigation bar with Camera, Gallery, Settings tabs
- Navigation works and preserves state between tabs

**Dependencies**:
```yaml
dependencies:
  go_router: ^14.0.0
```

**Route Configuration** (`lib/router/app_router.dart`):
```dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (context, state) => const CameraPlaceholder()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/gallery', builder: (context, state) => const GalleryPlaceholder()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (context, state) => const SettingsPlaceholder()),
        ]),
      ],
    ),
    GoRoute(
      path: '/document/:id',
      builder: (context, state) => DocumentPlaceholder(id: state.pathParameters['id']!),
    ),
  ],
);
```

---

### US-1.5: Theme and Design System Foundation

**As a** developer  
**I want** a consistent design system  
**So that** the app has a cohesive look and feel

**Acceptance Criteria**:
- Light and dark theme defined
- Color palette established (primary, secondary, surface, error colors)
- Typography scale defined (headline, body, label styles)
- Theme switching works via the theme provider from US-1.3
- Material 3 enabled

**Color Palette** (suggested):
```dart
// Light theme
static const primary = Color(0xFF2196F3);       // Blue
static const secondary = Color(0xFF03DAC6);     // Teal
static const surface = Color(0xFFFFFFFF);
static const background = Color(0xFFF5F5F5);
static const error = Color(0xFFB00020);

// Dark theme
static const primaryDark = Color(0xFF90CAF9);
static const surfaceDark = Color(0xFF121212);
static const backgroundDark = Color(0xFF1E1E1E);
```

---

### US-1.6: Local Storage Foundation

**As a** developer  
**I want** a local storage solution configured  
**So that** I can persist documents and settings on-device

**Acceptance Criteria**:
- Path provider configured for accessing app directories
- Storage service abstraction created
- Basic file operations: save, load, delete, list
- Settings persistence (e.g., theme preference)

**Dependencies**:
```yaml
dependencies:
  path_provider: ^2.1.2
  shared_preferences: ^2.2.2
```

**Storage Service** (`lib/shared/services/storage_service.dart`):
```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<Directory> get _documentsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/scans');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  Future<File> saveFile(String filename, List<int> bytes) async {
    final dir = await _documentsDir;
    final file = File('${dir.path}/$filename');
    return file.writeAsBytes(bytes);
  }

  Future<List<FileSystemEntity>> listFiles() async {
    final dir = await _documentsDir;
    return dir.listSync();
  }

  Future<void> deleteFile(String filename) async {
    final dir = await _documentsDir;
    final file = File('${dir.path}/$filename');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
```

**Tests Required**:
- ✅ `saveFile` creates file in correct directory
- ✅ `deleteFile` handles non-existent file gracefully


---

### US-1.7: Linting and Code Quality

**As a** developer  
**I want** strict linting rules enforced  
**So that** code quality remains high

**Acceptance Criteria**:
- Flutter: `flutter_lints` with custom rules in `analysis_options.yaml`
- Pre-commit hooks configured (optional but recommended)
- Zero lint warnings in initial codebase

**Flutter** (`analysis_options.yaml`):
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_locals
    - require_trailing_commas
    - sort_constructors_first

analyzer:
  errors:
    missing_required_param: error
    missing_return: error
```

---

### US-1.8: Basic CI Pipeline

**As a** developer  
**I want** a CI pipeline that runs on every push  
**So that** code quality is automatically verified

**Acceptance Criteria**:
- GitHub Actions workflow
- Pipeline runs: `flutter analyze`, `flutter test`
- Pipeline triggers on push to `main` and on pull requests

**GitHub Actions** (`.github/workflows/ci.yml`):
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  flutter:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: mobile
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

---

## Technical Specifications

### Environment Requirements

**Development Machine**:
- macOS (required for iOS development) — your 2016 MacBook Pro with Monterey should work
- Flutter SDK 3.19+
- Xcode 15+ (for iOS)
- Android Studio (for Android emulator)

**Note**: Flutter 3.19 supports macOS Monterey, but check compatibility. If issues arise, Flutter 3.16 is a safe fallback.

---

## Definition of Done

- [ ] All code committed to Git repository
- [ ] README.md updated with setup instructions
- [ ] Flutter app launches on iOS simulator
- [ ] Flutter app launches on Android emulator
- [ ] Storage service successfully saves and retrieves a test file
- [ ] All linting passes with zero warnings
- [ ] CI pipeline passes on push
- [ ] Code reviewed (self-review acceptable for solo development)

---

## Out of Scope

The following are explicitly NOT part of this epic:
- Camera functionality (Epic 2)
- Any image processing
- User authentication
- Backend / API (deferred to Phase 2, Epic 9)
- Cloud deployment

---

## Implementation Order

Suggested order for Claude Code:

1. Create root folder structure and `.gitignore`
2. Add `CLAUDE.md` to repository root
3. Initialize Flutter project in `/mobile`
4. Set up folder structure in Flutter
5. Add dependencies to `pubspec.yaml`
6. Implement theme system (colors, typography)
7. Implement Riverpod setup with theme provider
8. Implement GoRouter with placeholder screens
9. Implement bottom navigation shell
10. Implement storage service with basic file operations
11. Add linting configuration
12. Add CI pipeline
13. Write README with setup instructions
14. Run all tests and verify linting passes

---

## Notes for Claude Code

When implementing this epic:

1. **Use the latest stable versions** of all dependencies at time of implementation
2. **Include comprehensive comments** explaining architectural decisions
3. **Create placeholder screens** as simple `Scaffold` widgets with centered text indicating the screen name
4. **Write tests for storage service** — at minimum the two scenarios specified in US-1.6
5. **Test each component** before moving to the next
6. **Commit logically** — one commit per user story is a good cadence
7. **Read CLAUDE.md first** — follow the development standards defined there

---

## Confirmed Decisions

- **App ID**: `com.lucaplawliet.openscan`
- **App Name**: OpenScan
- **CI Platform**: GitHub Actions
- **Repository**: New repository
- **Phase**: Flutter-only MVP (no backend in Phase 1)
