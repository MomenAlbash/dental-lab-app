import 'package:dental_lab_app/core/helper/last_sync.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 9, 27, 18, 0);

  test('today and yesterday by name, anything older by date', () {
    expect(LastSync.describe(DateTime(2026, 9, 27, 14, 5), now), 'اليوم 14:05');
    expect(LastSync.describe(DateTime(2026, 9, 26, 9, 30), now), 'أمس 09:30');
    expect(
      LastSync.describe(DateTime(2026, 9, 20, 8, 0), now),
      '2026-09-20 08:00',
    );
  });

  test('remembers the last answer, at most once a minute', () async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    LastSync.markNow(DateTime(2026, 9, 27, 10, 0, 0));
    LastSync.markNow(DateTime(2026, 9, 27, 10, 0, 30));
    await Future<void>.delayed(Duration.zero);
    expect(LastSync.at, DateTime(2026, 9, 27, 10, 0, 0));

    LastSync.markNow(DateTime(2026, 9, 27, 10, 2, 0));
    await Future<void>.delayed(Duration.zero);
    expect(LastSync.at, DateTime(2026, 9, 27, 10, 2, 0));
  });
}
