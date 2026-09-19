import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a sheet paints the app backdrop rather than borrowing one', (
    tester,
  ) async {
    // A glass pane takes its colour from what is behind it. A tall form covers
    // the whole screen, leaving only the neutral end of the background behind
    // it — which rendered the sheet flat grey. It has to carry the app's own
    // backdrop so it looks the same whatever it covers.
    late GlassTokens glass;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            glass = context.glass;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showGlassBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(height: 600),
                  ),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final gradients = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassSheetSurface),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => (box.decoration as BoxDecoration).gradient)
        .toList();

    expect(gradients, contains(glass.backdropGradient));
    expect(gradients, contains(glass.surfaceGradient));
  });

  testWidgets('a short sheet still hugs its content', (tester) async {
    // The backdrop layer must not stretch the sheet to full height — the
    // whole point of a bottom sheet is that it covers only what it needs.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showGlassBottomSheet<void>(
                  context: context,
                  builder: (_) => const SizedBox(height: 80, width: 200),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final height = tester.getSize(find.byType(GlassSheetSurface)).height;

    expect(height, lessThan(tester.view.physicalSize.height));
    expect(tester.takeException(), isNull);
  });
}
