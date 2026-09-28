import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';

/// One page of `GET /Cases` (`ClinicCaseListItemDtoPagedResult`).
class CasesPageModel {
  const CasesPageModel({
    this.items = const [],
    this.page = 1,
    this.pageSize = 0,
    this.totalCount = 0,
  });

  final List<CaseListItemModel> items;
  final int page;
  final int pageSize;

  /// Every case matching the filters, across all pages.
  final int totalCount;

  /// Whether another page exists after this one. Worked out from the count
  /// rather than from a short page, which a server may also send mid-list.
  bool get hasMore => page * pageSize < totalCount;

  /// Tolerates a bare list too — an older server, or the offline cache —
  /// read as a single, final page.
  factory CasesPageModel.fromJson(dynamic json) {
    if (json is List) {
      final items = [
        for (final row in json)
          if (row is Map<String, dynamic>) CaseListItemModel.fromJson(row),
      ];
      return CasesPageModel(
        items: items,
        pageSize: items.length,
        totalCount: items.length,
      );
    }
    final map = json as Map<String, dynamic>? ?? const {};
    return CasesPageModel(
      items: [
        for (final row in map['items'] as List<dynamic>? ?? const [])
          if (row is Map<String, dynamic>) CaseListItemModel.fromJson(row),
      ],
      page: map['page'] as int? ?? 1,
      pageSize: map['pageSize'] as int? ?? 0,
      totalCount: map['totalCount'] as int? ?? 0,
    );
  }
}
