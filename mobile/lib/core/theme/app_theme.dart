import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme configuration for OpenScan.
///
/// Provides light and dark [ThemeData] with Material 3 design.
/// Includes comprehensive theming for all major components.
abstract final class AppTheme {
  /// Light theme configuration.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: _lightAppBarTheme,
        navigationBarTheme: _lightNavigationBarTheme,
        bottomNavigationBarTheme: _lightBottomNavigationBarTheme,
        floatingActionButtonTheme: _lightFabTheme,
        cardTheme: _lightCardTheme,
        inputDecorationTheme: _lightInputDecorationTheme,
        elevatedButtonTheme: _lightElevatedButtonTheme,
        outlinedButtonTheme: _lightOutlinedButtonTheme,
        textButtonTheme: _lightTextButtonTheme,
        dialogTheme: _lightDialogTheme,
        snackBarTheme: _lightSnackBarTheme,
        dividerTheme: _lightDividerTheme,
        listTileTheme: _lightListTileTheme,
        switchTheme: _lightSwitchTheme,
        textTheme: _textTheme,
      );

  /// Dark theme configuration.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: _darkAppBarTheme,
        navigationBarTheme: _darkNavigationBarTheme,
        bottomNavigationBarTheme: _darkBottomNavigationBarTheme,
        floatingActionButtonTheme: _darkFabTheme,
        cardTheme: _darkCardTheme,
        inputDecorationTheme: _darkInputDecorationTheme,
        elevatedButtonTheme: _darkElevatedButtonTheme,
        outlinedButtonTheme: _darkOutlinedButtonTheme,
        textButtonTheme: _darkTextButtonTheme,
        dialogTheme: _darkDialogTheme,
        snackBarTheme: _darkSnackBarTheme,
        dividerTheme: _darkDividerTheme,
        listTileTheme: _darkListTileTheme,
        switchTheme: _darkSwitchTheme,
        textTheme: _textTheme,
      );

  // ============================================
  // Color Schemes
  // ============================================

  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    scrim: AppColors.scrim,
    shadow: AppColors.shadow,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryContainerDark,
    tertiary: AppColors.tertiaryDark,
    tertiaryContainer: AppColors.tertiaryContainerDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    error: AppColors.errorDark,
    onError: AppColors.onErrorDark,
    errorContainer: AppColors.errorContainerDark,
    onErrorContainer: AppColors.onErrorContainerDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    inverseSurface: AppColors.inverseSurfaceDark,
    onInverseSurface: AppColors.inverseOnSurfaceDark,
    scrim: AppColors.scrimDark,
    shadow: AppColors.shadowDark,
  );

  // ============================================
  // AppBar Themes
  // ============================================

  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.onSurface,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.onSurface),
    actionsIconTheme: IconThemeData(color: AppColors.onSurfaceVariant),
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.onSurfaceDark,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.onSurfaceDark),
    actionsIconTheme: IconThemeData(color: AppColors.onSurfaceVariantDark),
  );

  // ============================================
  // Navigation Bar Themes (Material 3)
  // ============================================

  static const NavigationBarThemeData _lightNavigationBarTheme =
      NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.secondaryContainer,
    elevation: 0,
    height: 80,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  );

  static const NavigationBarThemeData _darkNavigationBarTheme =
      NavigationBarThemeData(
    backgroundColor: AppColors.surfaceDark,
    indicatorColor: AppColors.secondaryContainerDark,
    elevation: 0,
    height: 80,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  );

  // ============================================
  // Bottom Navigation Bar Themes (Legacy)
  // ============================================

  static const BottomNavigationBarThemeData _lightBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.onSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  );

  static const BottomNavigationBarThemeData _darkBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceDark,
    selectedItemColor: AppColors.primaryDark,
    unselectedItemColor: AppColors.onSurfaceVariantDark,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  );

  // ============================================
  // Floating Action Button Themes
  // ============================================

  static const FloatingActionButtonThemeData _lightFabTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryContainer,
    foregroundColor: AppColors.onPrimaryContainer,
    elevation: 3,
    highlightElevation: 6,
  );

  static const FloatingActionButtonThemeData _darkFabTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryContainerDark,
    foregroundColor: AppColors.onPrimaryContainerDark,
    elevation: 3,
    highlightElevation: 6,
  );

  // ============================================
  // Card Themes
  // ============================================

  static const CardThemeData _lightCardTheme = CardThemeData(
    color: AppColors.surface,
    elevation: 1,
    margin: EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  static const CardThemeData _darkCardTheme = CardThemeData(
    color: AppColors.surfaceDark,
    elevation: 1,
    margin: EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // ============================================
  // Input Decoration Themes
  // ============================================

  static const InputDecorationTheme _lightInputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static const InputDecorationTheme _darkInputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariantDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.outlineDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.errorDark),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.errorDark, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  // ============================================
  // Button Themes
  // ============================================

  static final ElevatedButtonThemeData _lightElevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static final ElevatedButtonThemeData _darkElevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.onPrimaryDark,
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static final OutlinedButtonThemeData _lightOutlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.outline),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static final OutlinedButtonThemeData _darkOutlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      side: const BorderSide(color: AppColors.outlineDark),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static final TextButtonThemeData _lightTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static final TextButtonThemeData _darkTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  // ============================================
  // Dialog Themes
  // ============================================

  static const DialogThemeData _lightDialogTheme = DialogThemeData(
    backgroundColor: AppColors.surface,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    ),
  );

  static const DialogThemeData _darkDialogTheme = DialogThemeData(
    backgroundColor: AppColors.surfaceDark,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    ),
  );

  // ============================================
  // SnackBar Themes
  // ============================================

  static const SnackBarThemeData _lightSnackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.inverseSurface,
    contentTextStyle: TextStyle(color: AppColors.inverseOnSurface),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  static const SnackBarThemeData _darkSnackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.inverseSurfaceDark,
    contentTextStyle: TextStyle(color: AppColors.inverseOnSurfaceDark),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  // ============================================
  // Divider Themes
  // ============================================

  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.outlineVariant,
    thickness: 1,
    space: 1,
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.outlineVariantDark,
    thickness: 1,
    space: 1,
  );

  // ============================================
  // ListTile Themes
  // ============================================

  static const ListTileThemeData _lightListTileTheme = ListTileThemeData(
    iconColor: AppColors.onSurfaceVariant,
    textColor: AppColors.onSurface,
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  );

  static const ListTileThemeData _darkListTileTheme = ListTileThemeData(
    iconColor: AppColors.onSurfaceVariantDark,
    textColor: AppColors.onSurfaceDark,
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  );

  // ============================================
  // Switch Themes
  // ============================================

  static final SwitchThemeData _lightSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.onPrimaryContainer;
      }
      return AppColors.outline;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryContainer;
      }
      return AppColors.surfaceVariant;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.transparent;
      }
      return AppColors.outline;
    }),
  );

  static final SwitchThemeData _darkSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.onPrimaryContainerDark;
      }
      return AppColors.outlineDark;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryContainerDark;
      }
      return AppColors.surfaceVariantDark;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.transparent;
      }
      return AppColors.outlineDark;
    }),
  );

  // ============================================
  // Typography
  // ============================================

  /// Typography scale following Material 3 guidelines.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );
}
