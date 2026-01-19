import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/exceptions.dart';

/// Service for managing app settings persistence.
///
/// Uses [SharedPreferences] to store user preferences like theme mode.
class SettingsService {
  /// Creates a settings service instance.
  const SettingsService();

  /// Key for storing the dark mode preference.
  static const String _darkModeKey = 'dark_mode';

  /// Gets the shared preferences instance.
  Future<SharedPreferences> get _prefs async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      throw StorageException(
        message: 'Failed to access shared preferences: $e',
        userMessage: 'Could not access settings. Please try again.',
        originalError: e,
      );
    }
  }

  /// Gets the saved dark mode preference.
  ///
  /// Returns `true` if dark mode is enabled, `false` if light mode.
  /// Defaults to `false` (light mode) if no preference is saved.
  Future<bool> getDarkMode() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(_darkModeKey) ?? false;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(
        message: 'Failed to get dark mode preference: $e',
        originalError: e,
      );
    }
  }

  /// Saves the dark mode preference.
  ///
  /// Set [enabled] to `true` for dark mode, `false` for light mode.
  /// Returns `true` if the preference was saved successfully.
  Future<bool> setDarkMode({required bool enabled}) async {
    try {
      final prefs = await _prefs;
      return prefs.setBool(_darkModeKey, enabled);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(
        message: 'Failed to save dark mode preference: $e',
        userMessage: 'Could not save settings. Please try again.',
        originalError: e,
      );
    }
  }

  /// Clears all saved settings.
  ///
  /// Returns `true` if settings were cleared successfully.
  Future<bool> clearAll() async {
    try {
      final prefs = await _prefs;
      return prefs.clear();
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(
        message: 'Failed to clear settings: $e',
        userMessage: 'Could not clear settings. Please try again.',
        originalError: e,
      );
    }
  }
}
