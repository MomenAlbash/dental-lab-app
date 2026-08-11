import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/font_scale_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> startWith({String? saved}) async {
    SharedPreferences.setMockInitialValues({CacheKeys.fontScale: ?saved});
    await CacheHelper.init();
  }

  group('FontScaleCubit', () {
    test('starts on medium when nothing was chosen before', () async {
      await startWith();

      expect(FontScaleCubit().state, FontScale.medium);
    });

    test('restores the saved choice', () async {
      await startWith(saved: 'large');

      expect(FontScaleCubit().state, FontScale.large);
    });

    test('falls back to medium on an unrecognised value', () async {
      await startWith(saved: 'enormous');

      expect(FontScaleCubit().state, FontScale.medium);
    });

    test('persists a new choice so it survives a restart', () async {
      await startWith();
      final cubit = FontScaleCubit();

      await cubit.setScale(FontScale.small);

      expect(cubit.state, FontScale.small);
      // A fresh instance reads what the first one wrote.
      expect(FontScaleCubit().state, FontScale.small);
      await cubit.close();
    });
  });

  group('applyFontScale', () {
    test('medium leaves the device setting untouched', () {
      expect(
        applyFontScale(const TextScaler.linear(1), FontScale.medium).scale(14),
        14,
      );
    });

    test('scales up and down around it', () {
      const system = TextScaler.linear(1);

      expect(
        applyFontScale(system, FontScale.large).scale(14),
        greaterThan(14),
      );
      expect(applyFontScale(system, FontScale.small).scale(14), lessThan(14));
    });

    test('multiplies the device setting rather than replacing it', () {
      // CLAUDE.md §C.1: a user who enlarged text OS-wide must keep that here.
      const enlargedDevice = TextScaler.linear(1.5);

      final result = applyFontScale(enlargedDevice, FontScale.large).scale(14);

      expect(result, closeTo(14 * 1.5 * FontScale.large.factor, 0.001));
      // Still bigger than the device setting alone.
      expect(result, greaterThan(enlargedDevice.scale(14)));
    });

    test('an enlarged device with the small option still beats no scaling', () {
      const enlargedDevice = TextScaler.linear(1.5);

      expect(
        applyFontScale(enlargedDevice, FontScale.small).scale(14),
        greaterThan(14),
      );
    });
  });
}
