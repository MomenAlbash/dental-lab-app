import 'package:dental_lab_app/core/helper/laboratory_identity.dart';
import 'package:dental_lab_app/core/helper/laboratory_scope.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/laboratory_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LaboratoryIdentity', () {
    test('the same laboratory always gets the same colour', () {
      const id = '3f2a0c1e-9b7e-4d04-8c1a-000000000001';

      expect(
        LaboratoryIdentity.colorIndexFor(id),
        LaboratoryIdentity.colorIndexFor(id),
      );
      expect(
        LaboratoryIdentity.colorIndexFor(id),
        inInclusiveRange(0, LaboratoryIdentity.paletteSize - 1),
      );
    });

    test('different laboratories spread over the palette', () {
      final slots = {
        for (var i = 0; i < 40; i++) LaboratoryIdentity.colorIndexFor('lab-$i'),
      };

      // Not a guarantee for any two, but a hash stuck on one colour would
      // make the badge useless.
      expect(slots.length, greaterThan(4));
    });

    test('initials from two words, or the first two letters of one', () {
      expect(LaboratoryIdentity.initialsOf('مخبر النور'), 'من');
      expect(LaboratoryIdentity.initialsOf('Smile'), 'Sm');
      expect(LaboratoryIdentity.initialsOf('   '), '؟');
    });
  });

  group('LaboratoryBadge', () {
    Future<void> pump(WidgetTester tester, Widget child) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CacheHelper.init();
    });

    testWidgets('says nothing when one laboratory is in view', (tester) async {
      await LaboratoryScope.save([(id: 'a', name: 'مخبر أ')]);

      await pump(tester, const LaboratoryBadge(laboratoryId: 'a'));

      expect(find.text('مخبر أ'), findsNothing);
    });

    testWidgets('names the laboratory when several are in view', (
      tester,
    ) async {
      await LaboratoryScope.save([
        (id: 'a', name: 'مخبر أ'),
        (id: 'b', name: 'مخبر ب'),
      ]);

      await pump(tester, const LaboratoryBadge(laboratoryId: 'b'));

      expect(find.text('مخبر ب'), findsOneWidget);
    });
  });
}
