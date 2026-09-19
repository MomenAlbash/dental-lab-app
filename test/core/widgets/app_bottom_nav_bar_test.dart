import 'package:dental_lab_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _destinations = [
  AppBottomNavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'الرئيسية',
  ),
  AppBottomNavDestination(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    label: 'الحالات',
  ),
  AppBottomNavDestination(
    icon: Icons.event_outlined,
    selectedIcon: Icons.event_rounded,
    label: 'المواعيد',
  ),
  AppBottomNavDestination(
    icon: Icons.notifications_none_rounded,
    selectedIcon: Icons.notifications_rounded,
    label: 'الإشعارات',
  ),
];

Future<void> _pumpBar(
  WidgetTester tester, {
  int currentIndex = 0,
  ValueChanged<int>? onDestinationSelected,
  VoidCallback? onPrimaryAction,
}) {
  return tester.pumpWidget(
    MaterialApp(
      // Deliberately no Scaffold: the shell hosts the bar in a Stack above the
      // pages, so it has no Material ancestor to inherit and has to supply its
      // own — without one the tabs' ink throws "No Material widget found".
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AppBottomNavBar(
            destinations: _destinations,
            currentIndex: currentIndex,
            onDestinationSelected: onDestinationSelected ?? (_) {},
            onPrimaryAction: onPrimaryAction ?? () {},
            primaryActionLabel: 'إضافة حالة',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders every destination plus the raised add action', (
    tester,
  ) async {
    await _pumpBar(tester);

    expect(find.byIcon(Icons.add), findsOneWidget);
    // Home is selected, so it shows its filled icon and the rest show outlines.
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    final tapped = <int>[];
    await _pumpBar(tester, onDestinationSelected: tapped.add);

    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pump();

    expect(tapped, [2]);
  });

  testWidgets('the raised + triggers the primary action, not a tab change', (
    tester,
  ) async {
    var primaryTaps = 0;
    final tapped = <int>[];
    await _pumpBar(
      tester,
      onDestinationSelected: tapped.add,
      onPrimaryAction: () => primaryTaps++,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(primaryTaps, 1);
    expect(tapped, isEmpty);
  });

  testWidgets('selected destination swaps to its filled icon', (tester) async {
    await _pumpBar(tester, currentIndex: 1);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('fits a small phone without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpBar(tester);

    expect(tester.takeException(), isNull);
  });
}
