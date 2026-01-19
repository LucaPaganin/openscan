import 'package:flutter/material.dart';

/// Color palette for OpenScan.
///
/// Defines the light and dark theme colors following Material 3 guidelines.
/// Colors are organized by theme (light/dark) and semantic purpose.
abstract final class AppColors {
  // ============================================
  // Light Theme Colors
  // ============================================

  /// Primary color for light theme - Blue.
  static const Color primary = Color(0xFF2196F3);

  /// Container color for primary elements in light theme.
  static const Color primaryContainer = Color(0xFFD1E4FF);

  /// Secondary color for light theme - Teal.
  static const Color secondary = Color(0xFF03DAC6);

  /// Container color for secondary elements in light theme.
  static const Color secondaryContainer = Color(0xFFCEF5EC);

  /// Tertiary accent color for light theme.
  static const Color tertiary = Color(0xFF7C5800);

  /// Container color for tertiary elements in light theme.
  static const Color tertiaryContainer = Color(0xFFFFDEA6);

  /// Surface color for light theme.
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant for light theme (cards, dialogs).
  static const Color surfaceVariant = Color(0xFFE7E0EC);

  /// Background color for light theme.
  static const Color background = Color(0xFFF5F5F5);

  /// Error color for light theme.
  static const Color error = Color(0xFFB00020);

  /// Container color for error elements in light theme.
  static const Color errorContainer = Color(0xFFF9DEDC);

  /// Outline color for borders in light theme.
  static const Color outline = Color(0xFF79747E);

  /// Subtle outline color for light theme.
  static const Color outlineVariant = Color(0xFFCAC4D0);

  /// Text/icon color on primary in light theme.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text/icon color on primary container in light theme.
  static const Color onPrimaryContainer = Color(0xFF001D36);

  /// Text/icon color on secondary in light theme.
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Text/icon color on secondary container in light theme.
  static const Color onSecondaryContainer = Color(0xFF002117);

  /// Text/icon color on surface in light theme.
  static const Color onSurface = Color(0xFF1C1B1F);

  /// Text/icon color on surface variant in light theme.
  static const Color onSurfaceVariant = Color(0xFF49454F);

  /// Text/icon color on background in light theme.
  static const Color onBackground = Color(0xFF1C1B1F);

  /// Text/icon color on error in light theme.
  static const Color onError = Color(0xFFFFFFFF);

  /// Text/icon color on error container in light theme.
  static const Color onErrorContainer = Color(0xFF410E0B);

  /// Inverse surface for snackbars in light theme.
  static const Color inverseSurface = Color(0xFF313033);

  /// Inverse text on surface for snackbars in light theme.
  static const Color inverseOnSurface = Color(0xFFF4EFF4);

  /// Scrim/overlay color for light theme.
  static const Color scrim = Color(0xFF000000);

  /// Shadow color for light theme.
  static const Color shadow = Color(0xFF000000);

  // ============================================
  // Dark Theme Colors
  // ============================================

  /// Primary color for dark theme.
  static const Color primaryDark = Color(0xFF90CAF9);

  /// Container color for primary elements in dark theme.
  static const Color primaryContainerDark = Color(0xFF004A77);

  /// Secondary color for dark theme.
  static const Color secondaryDark = Color(0xFF4DD0C6);

  /// Container color for secondary elements in dark theme.
  static const Color secondaryContainerDark = Color(0xFF005048);

  /// Tertiary accent color for dark theme.
  static const Color tertiaryDark = Color(0xFFF5BF48);

  /// Container color for tertiary elements in dark theme.
  static const Color tertiaryContainerDark = Color(0xFF5E4200);

  /// Surface color for dark theme.
  static const Color surfaceDark = Color(0xFF1C1B1F);

  /// Surface variant for dark theme (cards, dialogs).
  static const Color surfaceVariantDark = Color(0xFF49454F);

  /// Background color for dark theme.
  static const Color backgroundDark = Color(0xFF121212);

  /// Error color for dark theme.
  static const Color errorDark = Color(0xFFF2B8B5);

  /// Container color for error elements in dark theme.
  static const Color errorContainerDark = Color(0xFF8C1D18);

  /// Outline color for borders in dark theme.
  static const Color outlineDark = Color(0xFF938F99);

  /// Subtle outline color for dark theme.
  static const Color outlineVariantDark = Color(0xFF49454F);

  /// Text/icon color on primary in dark theme.
  static const Color onPrimaryDark = Color(0xFF003258);

  /// Text/icon color on primary container in dark theme.
  static const Color onPrimaryContainerDark = Color(0xFFD1E4FF);

  /// Text/icon color on secondary in dark theme.
  static const Color onSecondaryDark = Color(0xFF003731);

  /// Text/icon color on secondary container in dark theme.
  static const Color onSecondaryContainerDark = Color(0xFFCEF5EC);

  /// Text/icon color on surface in dark theme.
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  /// Text/icon color on surface variant in dark theme.
  static const Color onSurfaceVariantDark = Color(0xFFCAC4D0);

  /// Text/icon color on background in dark theme.
  static const Color onBackgroundDark = Color(0xFFE6E1E5);

  /// Text/icon color on error in dark theme.
  static const Color onErrorDark = Color(0xFF601410);

  /// Text/icon color on error container in dark theme.
  static const Color onErrorContainerDark = Color(0xFFF9DEDC);

  /// Inverse surface for snackbars in dark theme.
  static const Color inverseSurfaceDark = Color(0xFFE6E1E5);

  /// Inverse text on surface for snackbars in dark theme.
  static const Color inverseOnSurfaceDark = Color(0xFF313033);

  /// Scrim/overlay color for dark theme.
  static const Color scrimDark = Color(0xFF000000);

  /// Shadow color for dark theme.
  static const Color shadowDark = Color(0xFF000000);
}
