import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';

sealed class DoctorExcludedRepresentativesState {
  const DoctorExcludedRepresentativesState();
}

class DoctorExcludedRepresentativesLoading
    extends DoctorExcludedRepresentativesState {
  const DoctorExcludedRepresentativesLoading();
}

class DoctorExcludedRepresentativesError
    extends DoctorExcludedRepresentativesState {
  const DoctorExcludedRepresentativesError(this.message);

  final String message;
}

/// Who is barred from this doctor's scanner sessions, and who else could be.
///
/// [zoneRepresentatives] is the doctor's own zone's representative list — the
/// only people a session for them could ever be offered to, and so the only
/// candidates worth excluding. Empty (not an error) when the doctor has no
/// zone yet.
class DoctorExcludedRepresentativesLoaded
    extends DoctorExcludedRepresentativesState {
  const DoctorExcludedRepresentativesLoaded({
    required this.excluded,
    required this.zoneRepresentatives,
    this.isBusy = false,
  });

  final List<ZoneRepresentativeModel> excluded;
  final List<ZoneRepresentativeModel> zoneRepresentatives;
  final bool isBusy;

  /// Zone representatives not already excluded — what the "exclude" picker
  /// offers, so the same person cannot be added twice.
  List<ZoneRepresentativeModel> get candidates {
    final excludedIds = {for (final rep in excluded) rep.userId};
    return [
      for (final rep in zoneRepresentatives)
        if (!excludedIds.contains(rep.userId)) rep,
    ];
  }

  DoctorExcludedRepresentativesLoaded copyWith({
    List<ZoneRepresentativeModel>? excluded,
    List<ZoneRepresentativeModel>? zoneRepresentatives,
    bool? isBusy,
  }) => DoctorExcludedRepresentativesLoaded(
    excluded: excluded ?? this.excluded,
    zoneRepresentatives: zoneRepresentatives ?? this.zoneRepresentatives,
    isBusy: isBusy ?? this.isBusy,
  );
}

/// A one-shot message. The cubit emits it, the screen toasts it, and the
/// loaded state comes straight back.
class DoctorExcludedRepresentativesMessage
    extends DoctorExcludedRepresentativesState {
  const DoctorExcludedRepresentativesMessage(
    this.message, {
    this.isError = false,
  });

  final String message;
  final bool isError;
}
