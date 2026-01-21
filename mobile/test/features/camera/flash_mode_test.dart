import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/camera/presentation/providers/flash_mode_provider.dart';

void main() {
  group('FlashModeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with FlashMode.off', () {
      final flashMode = container.read(flashModeNotifierProvider);
      expect(flashMode, FlashMode.off);
    });

    test('cycles from off to auto', () {
      final notifier = container.read(flashModeNotifierProvider.notifier);

      // Initial state is off
      expect(container.read(flashModeNotifierProvider), FlashMode.off);

      // Cycle: off → auto
      notifier.cycle();
      expect(container.read(flashModeNotifierProvider), FlashMode.auto);
    });

    test('cycles from auto to always', () {
      final notifier = container.read(flashModeNotifierProvider.notifier)
        ..setMode(FlashMode.auto);

      // Cycle: auto → always
      notifier.cycle();
      expect(container.read(flashModeNotifierProvider), FlashMode.always);
    });

    test('cycles from always to off', () {
      final notifier = container.read(flashModeNotifierProvider.notifier)
        ..setMode(FlashMode.always);

      // Cycle: always → off
      notifier.cycle();
      expect(container.read(flashModeNotifierProvider), FlashMode.off);
    });

    test('completes full cycle: off → auto → always → off', () {
      final notifier = container.read(flashModeNotifierProvider.notifier);

      // Start at off
      expect(container.read(flashModeNotifierProvider), FlashMode.off);

      // off → auto
      notifier.cycle();
      expect(container.read(flashModeNotifierProvider), FlashMode.auto);

      // auto → always
      notifier.cycle();
      expect(container.read(flashModeNotifierProvider), FlashMode.always);

      // always → off
      notifier.cycle();
      expect(container.read(flashModeNotifierProvider), FlashMode.off);
    });

    test('setMode sets flash mode to specific value', () {
      final notifier = container.read(flashModeNotifierProvider.notifier)
        ..setMode(FlashMode.auto);
      expect(container.read(flashModeNotifierProvider), FlashMode.auto);

      notifier.setMode(FlashMode.always);
      expect(container.read(flashModeNotifierProvider), FlashMode.always);

      notifier.setMode(FlashMode.off);
      expect(container.read(flashModeNotifierProvider), FlashMode.off);
    });

    test('handles torch mode by cycling to auto', () {
      final notifier = container.read(flashModeNotifierProvider.notifier)
        ..setMode(FlashMode.torch);

      // Cycle should go to auto (default case)
      notifier.cycle();
      expect(container.read(flashModeNotifierProvider), FlashMode.auto);
    });
  });
}
