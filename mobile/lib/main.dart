import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Entry point for the OpenScan application.
///
/// Wraps the app with [ProviderScope] to enable Riverpod state management.
void main() {
  runApp(
    const ProviderScope(
      child: OpenScanApp(),
    ),
  );
}
