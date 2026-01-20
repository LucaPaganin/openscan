import 'package:flutter/material.dart';

/// Widget displayed when camera permission is denied.
///
/// Shows a friendly message explaining why camera access is needed
/// and provides a button to either request permission again or
/// open the app settings.
class CameraPermissionDeniedView extends StatelessWidget {
  const CameraPermissionDeniedView({
    required this.onActionPressed,
    super.key,
    this.isPermanentlyDenied = false,
  });

  /// Callback when the user taps the action button.
  ///
  /// For denied state, this should request permission.
  /// For permanently denied state, this should open settings.
  final VoidCallback onActionPressed;

  /// Whether the permission was permanently denied.
  ///
  /// When true, the button will say "Open Settings" instead of "Grant Access".
  final bool isPermanentlyDenied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Camera Access Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isPermanentlyDenied
                  ? 'Camera access was denied. Please enable it in Settings to scan documents.'
                  : 'OpenScan needs camera access to scan your documents. Please grant permission to continue.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onActionPressed,
              icon: Icon(
                isPermanentlyDenied ? Icons.settings : Icons.camera_alt,
              ),
              label: Text(
                isPermanentlyDenied ? 'Open Settings' : 'Grant Access',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
