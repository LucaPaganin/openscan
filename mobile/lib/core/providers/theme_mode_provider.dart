import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Provider for managing the app's theme mode.
///
/// Returns `true` for dark mode, `false` for light mode.
/// This provider demonstrates Riverpod's code generation pattern.
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  bool build() => false; // Default to light mode

  /// Toggle between light and dark mode.
  void toggle() => state = !state;

  /// Set a specific theme mode.
  // ignore: use_setters_to_change_properties
  void setDarkMode({required bool enabled}) => state = enabled;
}
