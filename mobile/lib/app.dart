import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/theme_mode_provider.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Root application widget for OpenScan.
///
/// Sets up the MaterialApp with theme configuration and GoRouter navigation.
/// Theme mode is controlled by the [themeModeNotifierProvider].
class OpenScanApp extends ConsumerWidget {
  const OpenScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'OpenScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
