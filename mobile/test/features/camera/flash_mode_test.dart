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

    test('initializes with FlashMode.auto', () {
      final flashMode = container.read(flashModeProvider);
      expect(flashMode, FlashMode.auto);
    });

    test('cycles from auto to always', () {
      final notifier = container.read(flashModeProvider.notifier);

      // Initial state is auto
      expect(container.read(flashModeProvider), FlashMode.auto);

      // Cycle: auto → always
      notifier.cycle();
      expect(container.read(flashModeProvider), FlashMode.always);
    });

    test('cycles from always to off', () {
      final notifier = container.read(flashModeProvider.notifier)
        ..setMode(FlashMode.always);

      // Cycle: always → off
      notifier.cycle();
      expect(container.read(flashModeProvider), FlashMode.off);
    });

    test('cycles from off to auto', () {
      final notifier = container.read(flashModeProvider.notifier)
        ..setMode(FlashMode.off);

      // Cycle: off → auto
      notifier.cycle();
      expect(container.read(flashModeProvider), FlashMode.auto);
    });

    test('completes full cycle: auto → always → off → auto', () {
      final notifier = container.read(flashModeProvider.notifier);

      // Start at auto
      expect(container.read(flashModeProvider), FlashMode.auto);

      // auto → always
      notifier.cycle();
      expect(container.read(flashModeProvider), FlashMode.always);

      // always → off
      notifier.cycle();
      expect(container.read(flashModeProvider), FlashMode.off);

      // off → auto
      notifier.cycle();
      expect(container.read(flashModeProvider), FlashMode.auto);
    });

    test('setMode sets flash mode to specific value', () {
      final notifier = container.read(flashModeProvider.notifier)
        ..setMode(FlashMode.off);
      expect(container.read(flashModeProvider), FlashMode.off);

      notifier.setMode(FlashMode.always);
      expect(container.read(flashModeProvider), FlashMode.always);

      notifier.setMode(FlashMode.auto);
      expect(container.read(flashModeProvider), FlashMode.auto);
    });

    test('handles torch mode by cycling to auto', () {
      final notifier = container.read(flashModeProvider.notifier)
        ..setMode(FlashMode.torch);

      // Cycle should go to auto (default case)
      notifier.cycle();
      expect(container.read(flashModeProvider), FlashMode.auto);
    });
  });
}
