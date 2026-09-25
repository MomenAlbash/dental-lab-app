import 'dart:convert';

import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';

/// One laboratory the session is scoped to — just what the header and the
/// create picker need.
typedef ScopedLaboratory = ({String id, String name});

/// The laboratories the user is working on — one, or several at once.
///
/// How the backend reads the scope (see MOBILE-API-HEADERS):
/// * **GET** — every selected id in the `X-Laboratory-Ids` header, always.
/// * **POST create** — exactly one `laboratoryId` in the JSON body; the header
///   is ignored there. With one laboratory selected it is that one; with
///   several, the user picks ([chooseForCreate]).
/// * **PUT / PATCH / DELETE** — nothing: the server reads the row's own.
///
/// Kept in the data layer with no UI of its own: the picker is a callback the
/// app registers at start-up, the same way [Api.onSessionExpired] is.
abstract final class LaboratoryScope {
  static const _separator = ',';

  /// Every selected laboratory id, in the order they were picked.
  static List<String> get ids {
    final stored = CacheHelper.getData(key: CacheKeys.laboratoryIds);
    if (stored is String && stored.isNotEmpty) {
      return stored.split(_separator).where((id) => id.isNotEmpty).toList();
    }
    // A session saved before multi-laboratory scope existed still has its
    // single laboratory under the old key.
    final single = CacheHelper.getData(key: CacheKeys.laboratoryId);
    return single is String && single.isNotEmpty ? [single] : const [];
  }

  /// The selected laboratories with their names, for display and the picker.
  static List<ScopedLaboratory> get laboratories {
    final ids = LaboratoryScope.ids;
    final names = _names;
    return [
      for (var i = 0; i < ids.length; i++)
        (id: ids[i], name: i < names.length ? names[i] : ''),
    ];
  }

  static List<String> get _names {
    final stored = CacheHelper.getData(key: CacheKeys.laboratoryNames);
    if (stored is String && stored.isNotEmpty) {
      try {
        return (jsonDecode(stored) as List).cast<String>();
      } on FormatException {
        return const [];
      }
    }
    final single = CacheHelper.getData(key: CacheKeys.laboratoryName);
    return single is String ? [single] : const [];
  }

  static bool get isMulti => ids.length > 1;

  /// Replaces the scope. The first laboratory is also kept under the old
  /// single-laboratory keys, which the rest of the app still reads as "the
  /// session's own laboratory" (the login redirect, the dashboard title).
  static Future<void> save(List<ScopedLaboratory> laboratories) async {
    if (laboratories.isEmpty) return clear();

    await CacheHelper.saveData(
      key: CacheKeys.laboratoryIds,
      value: [for (final lab in laboratories) lab.id].join(_separator),
    );
    await CacheHelper.saveData(
      key: CacheKeys.laboratoryNames,
      value: jsonEncode([for (final lab in laboratories) lab.name]),
    );
    await CacheHelper.saveData(
      key: CacheKeys.laboratoryId,
      value: laboratories.first.id,
    );
    await CacheHelper.saveData(
      key: CacheKeys.laboratoryName,
      value: [for (final lab in laboratories) lab.name].join('، '),
    );
  }

  static Future<void> clear() async {
    await CacheHelper.removeData(key: CacheKeys.laboratoryIds);
    await CacheHelper.removeData(key: CacheKeys.laboratoryNames);
    await CacheHelper.removeData(key: CacheKeys.laboratoryId);
    await CacheHelper.removeData(key: CacheKeys.laboratoryName);
  }

  /// Asks which of the selected laboratories a new record belongs to. Set by
  /// the app at start-up; returns null when the user cancels.
  static Future<String?> Function(List<ScopedLaboratory> options)?
  chooseForCreate;

  /// The laboratory a create goes to: the only one selected, or the user's
  /// pick among several. Null when there is none, or the user cancelled.
  static Future<String?> resolveForCreate() async {
    final options = laboratories;
    if (options.isEmpty) return null;
    if (options.length == 1) return options.single.id;
    return chooseForCreate?.call(options);
  }

  /// The create endpoints whose body carries `laboratoryId` — taken from the
  /// Clinic swagger, not guessed. Only these get one injected: any other
  /// POST is an action on an existing row, where the server reads the row's
  /// own laboratory and an extra field would be refused.
  static final List<RegExp> _createPaths = [
    for (final path in const [
      'Accounting/invoices',
      'Accounting/expenses',
      'Accounting/untagged-currency/assign',
      'Accounting/cashbox/opening-balance',
      'Accounting/cashbox/entries',
      'case-priorities',
      'case-priorities/seed-defaults',
      'Cases',
      'case-statuses',
      'case-statuses/seed-defaults',
      'CaseTicketTemplates',
      'Clinics',
      'Commitments',
      'Community/doctors/{id}/follow',
      'Community/{id}/like',
      'Departments',
      'DetailsQuestions',
      'Doctors',
      'EmployeeAdvances',
      'employee-salary-systems',
      'employee-work-systems',
      'fingerprint-devices',
      'Holidays',
      'Inventory',
      'Leaves',
      'Notes/categories',
      'Notes/notes',
      'Notifications/broadcast',
      'Patients',
      'Payroll/generate',
      'photography-sessions',
      'photography-visits',
      'PriceTiers',
      'Punches/bulk',
      'Punches/manual',
      'Purchases',
      'RestorationTypes',
      'restoration-type-stages',
      'SalaryExceptions',
      'scanner-availability/rules',
      'Suppliers',
      'Users',
      'WorkShifts',
      'Zones',
    ])
      RegExp(
        '^/?${RegExp.escape(path).replaceAll(RegExp(r'\\\{[^}]*\\\}'), '[^/]+')}/?\$',
        caseSensitive: false,
      ),
  ];

  /// Whether a POST to [path] (relative, query string ignored) is a create.
  static bool isCreatePath(String path) {
    final bare = path.split('?').first;
    return _createPaths.any((pattern) => pattern.hasMatch(bare));
  }
}
