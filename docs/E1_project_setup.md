# Epic 1: Project Setup

## Epic Overview

**Goal**: Establish the foundational project structure for a cross-platform document scanner app with a cloud backend. This epic creates the scaffolding upon which all future features will be built.

**Duration**: 1 Sprint (1 week)

**Epic Owner**: Luca (Scrum Master)

---

## Success Criteria

By the end of this epic:
- [ ] Flutter mobile app runs on both iOS and Android emulators/simulators
- [ ] FastAPI backend runs locally and responds to health check endpoint
- [ ] Project structure follows established conventions and is ready for feature development
- [ ] Basic navigation shell exists (empty screens as placeholders)
- [ ] State management is configured and demonstrated with a simple example
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
│   │   │   ├── app_constants.dart
│   │   │   └── api_constants.dart
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
│   │       └── api_client.dart
│   └── router/
│       └── app_router.dart
├── assets/
│   ├── images/
│   └── icons/
├── test/
└── pubspec.yaml
```

Backend structure (`/backend`):
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                     # FastAPI app entry point
│   ├── core/
│   │   ├── config.py               # Settings/env management
│   │   └── logging.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   └── health.py
│   │   └── deps.py                 # Dependency injection
│   ├── services/
│   │   └── __init__.py
│   └── models/
│       └── __init__.py
├── tests/
│   └── test_health.py
├── requirements.txt
├── requirements-dev.txt
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

Root structure:
```
openscan/
├── mobile/                         # Flutter app
├── backend/                        # FastAPI backend
├── docs/                           # Documentation
│   └── specs/                      # Feature specifications
├── .github/
│   └── workflows/                  # CI/CD pipelines
├── README.md
└── .gitignore
```

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

### US-1.6: Backend Project Initialization

**As a** developer  
**I want** a FastAPI backend scaffolded  
**So that** I can add processing endpoints in future sprints

**Acceptance Criteria**:
- FastAPI project created with proper structure
- Health check endpoint: `GET /health` returns `{"status": "healthy", "version": "0.1.0"}`
- CORS configured for local development
- Environment variable management via `pydantic-settings`
- Runs locally with `uvicorn`
- Docker support with `Dockerfile` and `docker-compose.yml`

**Dependencies** (`requirements.txt`):
```
fastapi>=0.110.0
uvicorn[standard]>=0.27.0
pydantic>=2.6.0
pydantic-settings>=2.2.0
python-multipart>=0.0.9
```

**Health Endpoint** (`app/api/routes/health.py`):
```python
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy", "version": "0.1.0"}
```

---

### US-1.7: API Client Setup (Mobile)

**As a** developer  
**I want** an HTTP client configured in the mobile app  
**So that** I can communicate with the backend

**Acceptance Criteria**:
- Dio HTTP client installed and configured
- Base API client class with:
  - Base URL configuration (from environment/constants)
  - Request/response interceptors for logging
  - Error handling wrapper
- Health check call demonstrates connectivity

**Dependencies**:
```yaml
dependencies:
  dio: ^5.4.0
  pretty_dio_logger: ^1.3.1
```

**API Client** (`lib/shared/services/api_client.dart`):
```dart
class ApiClient {
  late final Dio _dio;
  
  ApiClient({required String baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
    ));
  }
  
  Future<Response<T>> get<T>(String path) async {
    return _dio.get<T>(path);
  }
  
  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    return _dio.post<T>(path, data: data);
  }
}
```

---

### US-1.8: Linting and Code Quality

**As a** developer  
**I want** strict linting rules enforced  
**So that** code quality remains high

**Acceptance Criteria**:
- Flutter: `flutter_lints` with custom rules in `analysis_options.yaml`
- Python: `ruff` for linting and formatting
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

**Python** (`pyproject.toml`):
```toml
[tool.ruff]
line-length = 100
select = ["E", "F", "W", "I", "N", "UP", "B", "C4"]

[tool.ruff.isort]
known-first-party = ["app"]
```

---

### US-1.9: Basic CI Pipeline

**As a** developer  
**I want** a CI pipeline that runs on every push  
**So that** code quality is automatically verified

**Acceptance Criteria**:
- GitHub Actions workflow (or Azure DevOps if preferred)
- Pipeline runs:
  - Flutter: `flutter analyze`, `flutter test`
  - Python: `ruff check`, `pytest`
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

  backend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: ruff check .
      - run: pytest
```

---

## Technical Specifications

### Environment Requirements

**Development Machine**:
- macOS (required for iOS development) — your 2016 MacBook Pro with Monterey should work
- Flutter SDK 3.19+
- Xcode 15+ (for iOS)
- Android Studio (for Android emulator)
- Python 3.11+
- Docker Desktop

**Note**: Flutter 3.19 supports macOS Monterey, but check compatibility. If issues arise, Flutter 3.16 is a safe fallback.

### Configuration Files

**Mobile** (`mobile/.env.example`):
```
API_BASE_URL=http://localhost:8000
```

**Backend** (`backend/.env.example`):
```
APP_ENV=development
DEBUG=true
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

---

## Definition of Done

- [ ] All code committed to Git repository
- [ ] README.md updated with setup instructions
- [ ] Flutter app launches on iOS simulator
- [ ] Flutter app launches on Android emulator
- [ ] Backend runs locally and `/health` returns expected response
- [ ] Mobile app successfully calls backend health endpoint (when both running locally)
- [ ] All linting passes with zero warnings
- [ ] CI pipeline passes on push
- [ ] Code reviewed (self-review acceptable for solo development)

---

## Out of Scope

The following are explicitly NOT part of this epic:
- Camera functionality (Epic 2)
- Any image processing
- User authentication
- Cloud deployment (Azure setup comes in a later epic)
- Database setup

---

## Implementation Order

Suggested order for Claude Code:

1. Create root folder structure and `.gitignore`
2. Initialize Flutter project in `/mobile`
3. Set up folder structure in Flutter
4. Add dependencies to `pubspec.yaml`
5. Implement theme system
6. Implement Riverpod setup with theme provider
7. Implement GoRouter with placeholder screens
8. Implement bottom navigation shell
9. Set up API client
10. Initialize Python backend in `/backend`
11. Implement FastAPI app with health endpoint
12. Add Docker configuration
13. Add linting configuration (both projects)
14. Add CI pipeline
15. Write README with setup instructions

---

## Notes for Claude Code

When implementing this epic:

1. **Use the latest stable versions** of all dependencies at time of implementation
2. **Include comprehensive comments** explaining architectural decisions
3. **Create placeholder screens** as simple `Scaffold` widgets with centered text indicating the screen name
4. **Test each component** before moving to the next
5. **Commit logically** — one commit per user story is a good cadence

---

## Confirmed Decisions

- **App ID**: `com.lucaplawliet.openscan`
- **App Name**: OpenScan
- **CI Platform**: GitHub Actions
- **Repository**: New repository