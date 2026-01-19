import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A scaffold that displays a bottom navigation bar.
///
/// Uses [StatefulNavigationShell] to preserve state across tab switches.
/// Each tab maintains its own navigation stack.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  /// The navigation shell that manages the current tab state.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Handles navigation when a destination is selected.
  ///
  /// Uses [goBranch] to navigate while preserving state in each branch.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Navigate to the initial location of the branch if already on it
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
