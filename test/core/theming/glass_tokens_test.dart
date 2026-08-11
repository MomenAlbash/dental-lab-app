import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlassTokens', () {
    test('light and dark tokens differ', () {
      expect(
        GlassTokens.light.fillColor,
        isNot(equals(GlassTokens.dark.fillColor)),
      );
      expect(
        GlassTokens.light.onGlass,
        isNot(equals(GlassTokens.dark.onGlass)),
      );
      expect(
        GlassTokens.light.backdropGradient,
        isNot(equals(GlassTokens.dark.backdropGradient)),
      );
      // Regression: hero headers, avatars and the FAB used to read
      // AppColorsManger.primaryLight/primary/primaryDark directly, which are
      // compile-time constants that never change with the theme — so those
      // elements stayed lit in the light-mode orange even under dark mode.
      // brandGradient/primaryDark route through here instead, so they must
      // actually differ between the two themes.
      expect(
        GlassTokens.light.brandGradient,
        isNot(equals(GlassTokens.dark.brandGradient)),
      );
      expect(
        GlassTokens.light.primaryDark,
        isNot(equals(GlassTokens.dark.primaryDark)),
      );
    });

    test('copyWith overrides only the given field', () {
      final updated = GlassTokens.light.copyWith(blurSigma: 42);

      expect(updated.blurSigma, 42);
      expect(updated.fillColor, GlassTokens.light.fillColor);
      expect(updated.onGlass, GlassTokens.light.onGlass);
    });

    test('lerp at t=0 and t=1 returns the endpoints', () {
      final start = GlassTokens.light.lerp(GlassTokens.dark, 0);
      final end = GlassTokens.light.lerp(GlassTokens.dark, 1);

      expect(start.fillColor, GlassTokens.light.fillColor);
      expect(end.fillColor, GlassTokens.dark.fillColor);
    });

    test('lerp interpolates blurSigma between endpoints', () {
      final tokens = GlassTokens.light
          .copyWith(blurSigma: 10)
          .lerp(GlassTokens.dark.copyWith(blurSigma: 20), 0.5);

      expect(tokens.blurSigma, 15);
    });

    test('lerp against null keeps the receiver', () {
      expect(GlassTokens.light.lerp(null, 0.5), same(GlassTokens.light));
    });

    test('lerp interpolates primaryDark between endpoints', () {
      final start = GlassTokens.light.lerp(GlassTokens.dark, 0);
      final end = GlassTokens.light.lerp(GlassTokens.dark, 1);

      expect(start.primaryDark, GlassTokens.light.primaryDark);
      expect(end.primaryDark, GlassTokens.dark.primaryDark);
    });
  });

  group('theme wiring', () {
    test('AppTheme.light exposes the light tokens', () {
      expect(AppTheme.light.extension<GlassTokens>(), GlassTokens.light);
    });

    test('AppTheme.dark exposes the dark tokens', () {
      expect(AppTheme.dark.extension<GlassTokens>(), GlassTokens.dark);
    });
  });

  testWidgets(
    'context.glass falls back to light tokens without the extension',
    (tester) async {
      late GlassTokens resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              resolved = context.glass;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, GlassTokens.light);
    },
  );

  testWidgets('context.glass reads the dark tokens under AppTheme.dark', (
    tester,
  ) async {
    late GlassTokens resolved;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            resolved = context.glass;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, GlassTokens.dark);
  });
}
