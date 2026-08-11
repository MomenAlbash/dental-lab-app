import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _probe() => const AdaptiveLayout(
  mobileLayout: _mobile,
  tabletLayout: _tablet,
  desktopLayout: _desktop,
);

Widget _mobile(BuildContext context) => const Text('mobile');
Widget _tablet(BuildContext context) => const Text('tablet');
Widget _desktop(BuildContext context) => const Text('desktop');

Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  // The default test window is 800dp wide, which is narrower than some of the
  // widths under test — the SizedBox would overflow before the layout ever
  // got a chance to choose.
  tester.view.physicalSize = Size(width + 400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(width: width, height: 600, child: child),
      ),
    ),
  );
}

void main() {
  group('picks a layout from the width it is given', () {
    testWidgets('below 600 is a phone', (tester) async {
      await _pumpAt(tester, 599, _probe());
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('600 itself is already a tablet', (tester) async {
      // The boundary belongs to the larger shape, so a 600dp tablet does not
      // get the phone layout.
      await _pumpAt(tester, 600, _probe());
      expect(find.text('tablet'), findsOneWidget);
    });

    testWidgets('between 600 and 900 is a tablet', (tester) async {
      await _pumpAt(tester, 899, _probe());
      expect(find.text('tablet'), findsOneWidget);
    });

    testWidgets('900 and up is a desktop', (tester) async {
      await _pumpAt(tester, 900, _probe());
      expect(find.text('desktop'), findsOneWidget);
    });
  });

  testWidgets('tabletUp reuses the tablet layout for desktop widths', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      1200,
      const AdaptiveLayout.tabletUp(
        mobileLayout: _mobile,
        tabletLayout: _tablet,
      ),
    );

    expect(find.text('tablet'), findsOneWidget);
  });

  testWidgets('measures its own box, not the window', (tester) async {
    // A layout nested in a narrow pane of a wide screen is a phone-shaped
    // space and has to be treated as one. _pumpAt gives the window plenty of
    // room; the child box is what should decide.
    await _pumpAt(tester, 360, _probe());

    expect(find.text('mobile'), findsOneWidget);
  });

  group('formFactorFor', () {
    test('maps each band to its form factor', () {
      expect(AdaptiveLayout.formFactorFor(0), AdaptiveFormFactor.mobile);
      expect(AdaptiveLayout.formFactorFor(360), AdaptiveFormFactor.mobile);
      expect(AdaptiveLayout.formFactorFor(600), AdaptiveFormFactor.tablet);
      expect(AdaptiveLayout.formFactorFor(768), AdaptiveFormFactor.tablet);
      expect(AdaptiveLayout.formFactorFor(1024), AdaptiveFormFactor.desktop);
    });
  });
}
