import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_request_model.dart';

/// Create payload for a case (`ClinicCreateCaseRequest`). [patientId] is the
/// only field required by the API (a real `Patient` record) — a case also
/// needs a doctor and one restoration to be meaningful.
///
/// Teeth are no longer accepted at the case level — each entry in
/// [restorations] carries its own `teeth` list (see
/// [CaseRestorationRequestModel]).
class CreateCaseRequestModel {
  final String? doctorId;
  final String? clinicId;
  final String? patientId;
  final String? referenceNumber;
  final String? priorityId;
  final String? notes;

  /// **Not part of the request schema the server reads.** `expectedCompletionAt`
  /// is computed server-side from the restoration types' own turnaround
  /// figures — see [DeliveryEstimate] — and `ClinicCreateCaseRequest` has no
  /// due-date field to receive one. Still sent because it costs nothing and a
  /// future server revision may pick it up, but nothing should be built
  /// assuming it changes what the case is promised; use [DeliveryEstimate]
  /// for that.
  final String? dueDate;
  final String? receivedAt;

  /// How the case arrives. This is not cosmetic: the lab's routes carry both a
  /// traditional and a digital head, and the server prunes the stages that do
  /// not apply. Leaving it null hands that choice to the server's default,
  /// which is how a scanner case ends up running impression stages.
  final ImpressionMethod? impressionMethod;

  /// Only meaningful for a digital intake — whether the doctor uploaded the
  /// scan themselves or the lab scanned it in a session.
  final DigitalScanSource? digitalScanSource;

  /// The case this one repeats or corrects, when the work is not new.
  ///
  /// A remake is not a fresh case: the lab needs to see what it is redoing,
  /// and the server carries the link back as `previousCaseNumber`.
  final String? previousCaseId;

  /// The optional stages of the **case's own** workflow this case opted into.
  ///
  /// A stage marked `isOptional` is not cut onto the route by default — the
  /// case form asks about each one and the answers are sent here. An empty
  /// list means "none of them", which is a real answer, not a missing one.
  ///
  /// Only case stages belong here. A restoration route's optional stages ride
  /// on the restoration that runs them
  /// ([CaseRestorationRequestModel.restorationTypeStageIds]) — the server
  /// keeps the two lists apart, and a route stage sent at case level is
  /// dropped without complaint.
  final List<String> selectedStageIds;

  final List<CaseRestorationRequestModel> restorations;

  CreateCaseRequestModel({
    this.doctorId,
    this.clinicId,
    this.patientId,
    this.referenceNumber,
    this.priorityId,
    this.notes,
    this.dueDate,
    this.receivedAt,
    this.impressionMethod,
    this.digitalScanSource,
    this.previousCaseId,
    this.selectedStageIds = const [],
    this.restorations = const [],
  }) : assert(
         digitalScanSource == null ||
             impressionMethod == ImpressionMethod.digital,
         'A scan source only makes sense on a digital intake.',
       );

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'clinicId': clinicId,
      'patientId': patientId,
      'referenceNumber': referenceNumber,
      'priorityId': priorityId,
      'notes': notes,
      'dueDate': dueDate,
      'receivedAt': receivedAt,
      // Omitted rather than sent as null: an absent field lets the server keep
      // its own default, while an explicit null is a value the enum has no
      // member for.
      if (impressionMethod != null) 'impressionMethod': impressionMethod!.value,
      if (digitalScanSource != null)
        'digitalScanSource': digitalScanSource!.value,
      if (previousCaseId != null && previousCaseId!.isNotEmpty)
        'previousCaseId': previousCaseId,
      // `selectedCaseStagesIds` is the field the API actually reads. It was
      // sent as `selectedStageIds` — a name the request has no member for —
      // so every optional case stage the user asked for was silently ignored.
      'selectedCaseStagesIds': selectedStageIds,
      'restorations': restorations.map((r) => r.toJson()).toList(),
    };
  }
}
