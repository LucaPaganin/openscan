# OpenScan

A cross-platform document scanner app built with Flutter.

## Features

- Document scanning with edge detection
- Gallery for managing scanned documents
- PDF export
- Dark/Light theme support

## Requirements

- Flutter SDK 3.19+
- Dart 3.3+
- Android Studio (for Android development)
- Xcode 15+ (for iOS development, requires CocoaPods)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/openscan.git
cd openscan/mobile
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run code generation (Riverpod)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the app

**Android:**
```bash
flutter run -d android
```

**iOS (requires CocoaPods):**
```bash
cd ios && pod install && cd ..
flutter run -d ios
```

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # App widget with theme/router
│   ├── core/
│   │   ├── constants/               # App-wide constants
│   │   ├── errors/                  # Custom exception classes
│   │   ├── providers/               # Riverpod providers
│   │   ├── theme/                   # Theme configuration
│   │   └── utils/                   # Utility functions
│   ├── features/
│   │   ├── camera/                  # Camera/scanning feature
│   │   ├── document/                # Document viewer feature
│   │   ├── gallery/                 # Gallery feature
│   │   └── settings/                # Settings feature
│   ├── router/                      # GoRouter configuration
│   └── shared/
│       ├── services/                # Shared services (storage, etc.)
│       └── widgets/                 # Shared widgets
├── test/                            # Unit and widget tests
└── assets/                          # Images, icons, etc.
```

## Development

### Running Tests

```bash
flutter test
```

### Running Analysis

```bash
flutter analyze
```

### Code Formatting

```bash
dart format .
```

### Code Generation

After modifying Riverpod providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or watch for changes:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Architecture

- **State Management**: Riverpod 2.x with code generation
- **Navigation**: GoRouter with StatefulShellRoute for bottom navigation
- **Theme**: Material 3 with light/dark mode support
- **Storage**: path_provider + shared_preferences for local persistence

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.19+ |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Local Storage | path_provider, shared_preferences |
| Code Generation | build_runner, riverpod_generator |
| Linting | flutter_lints |

## CI/CD

This project uses GitHub Actions for continuous integration:

- **Trigger**: Push to `main` or pull request to `main`
- **Jobs**: Flutter analyze, test, format check

## License

MIT License - see LICENSE file for details.
