import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flash_mode_provider.g.dart';

/// Provider for managing flash mode state.
///
/// Cycles through: off → auto → on → off
/// Defaults to auto on initialization.
@riverpod
class FlashModeNotifier extends _$FlashModeNotifier {
  @override
  FlashMode build() => FlashMode.off;

  /// Cycles through flash modes: off → auto → always → off
  void cycle() {
    state = switch (state) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
  }

  /// Sets the flash mode to a specific value.
  // ignore: use_setters_to_change_properties
  void setMode(FlashMode mode) => state = mode;
}
