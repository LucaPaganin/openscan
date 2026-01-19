import 'package:flutter/material.dart';

/// Color palette for OpenScan.
///
/// Defines the light and dark theme colors following Material 3 guidelines.
abstract final class AppColors {
  // ============================================
  // Light Theme Colors
  // ============================================

  /// Primary color for light theme - Blue.
  static const Color primary = Color(0xFF2196F3);

  /// Secondary color for light theme - Teal.
  static const Color secondary = Color(0xFF03DAC6);

  /// Surface color for light theme.
  static const Color surface = Color(0xFFFFFFFF);

  /// Background color for light theme.
  static const Color background = Color(0xFFF5F5F5);

  /// Error color for light theme.
  static const Color error = Color(0xFFB00020);

  /// Text color for light theme.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text on surface for light theme.
  static const Color onSurface = Color(0xFF1C1B1F);

  /// Text on background for light theme.
  static const Color onBackground = Color(0xFF1C1B1F);

  // ============================================
  // Dark Theme Colors
  // ============================================

  /// Primary color for dark theme.
  static const Color primaryDark = Color(0xFF90CAF9);

  /// Secondary color for dark theme.
  static const Color secondaryDark = Color(0xFF03DAC6);

  /// Surface color for dark theme.
  static const Color surfaceDark = Color(0xFF121212);

  /// Background color for dark theme.
  static const Color backgroundDark = Color(0xFF1E1E1E);

  /// Error color for dark theme.
  static const Color errorDark = Color(0xFFCF6679);

  /// Text on primary for dark theme.
  static const Color onPrimaryDark = Color(0xFF000000);

  /// Text on surface for dark theme.
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  /// Text on background for dark theme.
  static const Color onBackgroundDark = Color(0xFFE6E1E5);
}
