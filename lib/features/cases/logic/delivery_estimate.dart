import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';

/// When a case can be promised, worked out from what it actually contains.
///
/// The laboratory declares a turnaround per restoration type **per priority
/// level** (`RestorationTypeModel.durations`), so the case's own answer is the
/// **slowest** of its restorations at the chosen priority: a case is finished
/// when its last piece is, not when its first one is.
///
/// Nothing here is sent to the server. `ClinicCreateCaseRequest` carries no
/// due-date field at all — the server computes `expectedCompletionAt` itself
/// from the same numbers — so this exists to show the user, before they file,
/// what the lab is about to promise.
class DeliveryEstimate {
  const DeliveryEstimate({
    required this.totalMinutes,
    required this.expectedAt,
    required this.hasEstimateForEveryLine,
  });

  /// The slowest line's turnaround, in minutes.
  final int totalMinutes;

  /// [totalMinutes] added to when the case was received.
  final DateTime expectedAt;

  /// False when at least one restoration type has no row at this priority.
  ///
  /// A missing row means "no estimate declared at this level" — **not** a
  /// zero-day turnaround — so the figure shown is a floor, not an answer, and
  /// the screen has to say so rather than quote it as fact.
  final bool hasEstimateForEveryLine;

  /// Works the estimate out for [restorationTypeIds] at [priorityId].
  ///
  /// Returns null when nothing can be said at all — no lines, no priority
  /// chosen, or not one type carrying a row for it. A blank is honest there;
  /// "today" would be a promise nobody made.
  static DeliveryEstimate? forCase({
    required Iterable<String> restorationTypeIds,
    required String? priorityId,
    required List<RestorationTypeModel> types,
    required DateTime? receivedAt,
  }) {
    if (priorityId == null || priorityId.isEmpty) return null;

    final byId = {for (final type in types) type.id: type};

    var slowest = 0;
    var sawAny = false;
    var sawAll = true;

    for (final typeId in restorationTypeIds) {
      final type = byId[typeId];
      // A type the catalogue did not return cannot be estimated, and must not
      // be quietly treated as instant.
      if (type == null) {
        sawAll = false;
        continue;
      }

      final minutes = _minutesFor(type, priorityId);
      if (minutes == null) {
        sawAll = false;
        continue;
      }

      sawAny = true;
      if (minutes > slowest) slowest = minutes;
    }

    if (!sawAny) return null;

    return DeliveryEstimate(
      totalMinutes: slowest,
      expectedAt: (receivedAt ?? DateTime.now()).add(
        Duration(minutes: slowest),
      ),
      hasEstimateForEveryLine: sawAll,
    );
  }

  static int? _minutesFor(RestorationTypeModel type, String priorityId) {
    for (final duration in type.durations) {
      if (duration.casePriorityId == priorityId) {
        return duration.durationMinutes;
      }
    }
    return null;
  }

  /// "٣ أيام و٤ ساعات" — whole days first, because that is the unit a lab
  /// quotes a doctor in. Minutes are dropped once there are days: nobody
  /// promises a case to the minute a week out.
  String get durationLabel {
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final minutes = totalMinutes % 60;

    final parts = <String>[
      if (days > 0) '$days ${days == 1 ? 'يوم' : 'أيام'}',
      if (hours > 0) '$hours ${hours == 1 ? 'ساعة' : 'ساعات'}',
      if (days == 0 && minutes > 0) '$minutes دقيقة',
    ];

    return parts.isEmpty ? 'أقل من دقيقة' : parts.join(' و');
  }
}
