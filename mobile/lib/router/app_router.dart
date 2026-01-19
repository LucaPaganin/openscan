import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/document/presentation/screens/document_screen.dart';
import '../features/gallery/presentation/screens/gallery_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../shared/widgets/scaffold_with_nav_bar.dart';

/// Global navigator key for accessing navigator state outside of context.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Route paths as constants for type-safe navigation.
abstract class AppRoutes {
  static const String camera = '/';
  static const String gallery = '/gallery';
  static const String settings = '/settings';
  static const String document = '/document/:id';

  /// Generates the document route path with the given [id].
  static String documentPath(String id) => '/document/$id';
}

/// The main router configuration for the app.
///
/// Uses [StatefulShellRoute.indexedStack] to preserve state across
/// bottom navigation tabs. Each tab has its own navigation stack.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.camera,
  debugLogDiagnostics: true,
  routes: [
    // Main shell route with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Camera tab (index 0)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.camera,
              builder: (context, state) => const CameraScreen(),
            ),
          ],
        ),
        // Gallery tab (index 1)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.gallery,
              builder: (context, state) => const GalleryScreen(),
            ),
          ],
        ),
        // Settings tab (index 2)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Document detail route (outside shell, full screen)
    GoRoute(
      path: AppRoutes.document,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final documentId = state.pathParameters['id']!;
        return DocumentScreen(documentId: documentId);
      },
    ),
  ],
);
