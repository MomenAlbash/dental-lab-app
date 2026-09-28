import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';

/// When the app last heard from the server — what "offline" data is as old
/// as. Shown in the offline banner, so a list read from the cache is not
/// taken for today's.
abstract final class LastSync {
  /// Writing on every response would cost a disk write per request; a minute
  /// is finer than anyone reads a "last updated" line.
  static const _resolution = Duration(minutes: 1);

  static DateTime? _lastWritten;

  /// Records a successful answer from the server.
  static void markNow([DateTime? now]) {
    final at = now ?? DateTime.now();
    final last = _lastWritten;
    if (last != null && at.difference(last) < _resolution) return;
    _lastWritten = at;
    CacheHelper.saveData(
      key: CacheKeys.lastSyncAt,
      value: at.toIso8601String(),
    );
  }

  static DateTime? get at {
    final stored = CacheHelper.getData(key: CacheKeys.lastSyncAt);
    return stored is String ? DateTime.tryParse(stored) : null;
  }

  /// `اليوم 14:30`, `أمس 09:05`, or the date for anything older.
  static String describe(DateTime at, DateTime now) {
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(day).inDays;
    if (days == 0) return 'اليوم $time';
    if (days == 1) return 'أمس $time';
    final month = at.month.toString().padLeft(2, '0');
    final date = at.day.toString().padLeft(2, '0');
    return '${at.year}-$month-$date $time';
  }
}
