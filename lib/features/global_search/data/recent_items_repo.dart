import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';

/// What kind of record a recent item opens.
enum RecentItemKind { caseItem, patient, doctor }

/// A record the user opened from the search — enough to show it again and
/// open it, without asking the server.
class RecentItem {
  const RecentItem({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  final RecentItemKind kind;
  final String id;
  final String title;
  final String subtitle;

  bool sameRecordAs(RecentItem other) => kind == other.kind && id == other.id;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'id': id,
    'title': title,
    'subtitle': subtitle,
  };

  /// Null for a row this version cannot read — skipped, not a crash.
  static RecentItem? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final kind = RecentItemKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final id = json['id'];
    if (kind == null || id is! String || id.isEmpty) return null;
    return RecentItem(
      kind: kind,
      id: id,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}

/// The last few records opened from the search, newest first — kept on this
/// device only, as a convenience: losing them loses nothing.
class RecentItemsRepo {
  /// Enough to find what was just looked at, few enough to scan.
  static const maxItems = 10;

  List<RecentItem> load() {
    final stored = CacheHelper.getJson(key: CacheKeys.recentSearchItems);
    if (stored is! List) return const [];
    return [
      for (final row in stored) ?RecentItem.tryFromJson(row),
    ].take(maxItems).toList();
  }

  /// Puts [item] first; opening the same record again moves it up rather
  /// than listing it twice.
  Future<List<RecentItem>> remember(RecentItem item) async {
    final items = [
      item,
      ...load().where((existing) => !existing.sameRecordAs(item)),
    ].take(maxItems).toList();
    await CacheHelper.saveJson(
      key: CacheKeys.recentSearchItems,
      value: [for (final i in items) i.toJson()],
    );
    return items;
  }

  Future<void> clear() =>
      CacheHelper.removeData(key: CacheKeys.recentSearchItems);
}
