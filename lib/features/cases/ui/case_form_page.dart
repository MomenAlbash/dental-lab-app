import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/core/widgets/unsaved_changes_guard.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_state.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_cubit.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_intake_picker.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_optional_stages_step.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_patient_step.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_restorations_step.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_review_step.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/previous_case_picker.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/delivery_estimate.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A restoration line being built in the form. Teeth (with bridge
/// connections) and shade/color choices are owned by the restoration itself
/// — the API stores them per restoration, not per case.
class RestorationEntry {
  RestorationEntry({
    required this.restorationTypeId,
    required this.restorationName,
    this.quantity = 1,
    this.unitPrice,
    this.currencyId,
    this.currencyName,
    this.notes,
    this.teeth = const [],
    this.shadeLayout,
    this.shadeCervical,
    this.shadeMiddle,
    this.shadeIncisal,
    this.baseToothColor,
  });

  final String restorationTypeId;
  final String restorationName;
  final int quantity;
  final double? unitPrice;

  /// The currency [unitPrice] is denominated in — a lab can bill a
  /// restoration in Syrian pounds or dollars, so the price alone is not
  /// enough to read it back correctly.
  final String? currencyId;

  /// Kept alongside [currencyId] purely so the summary row in
  /// [CaseRestorationsStep] can show it without a lookup — same reason the
  /// response model keeps [CaseRestorationModel.currencyName] beside its id.
  final String? currencyName;
  final String? notes;
  final List<ToothMarkModel> teeth;
  final String? shadeLayout;
  final String? shadeCervical;
  final String? shadeMiddle;
  final String? shadeIncisal;
  final String? baseToothColor;

  /// [optionalStageIds] are the optional stages of *this line's own route*
  /// that the case opted into — resolved by the form from the answers given
  /// in the wizard's optional-stages step, since the answer is collected once
  /// for the case but has to be sent per restoration.
  CaseRestorationRequestModel toRequest({
    List<String> optionalStageIds = const [],
  }) => CaseRestorationRequestModel(
    restorationTypeId: restorationTypeId,
    quantity: quantity,
    unitPrice: unitPrice,
    currencyId: currencyId,
    notes: notes,
    teeth: teeth,
    restorationTypeStageIds: optionalStageIds,
    shadeLayout: shadeLayout,
    shadeCervical: shadeCervical,
    shadeMiddle: shadeMiddle,
    shadeIncisal: shadeIncisal,
    baseToothColor: baseToothColor,
  );
}

/// Create-case screen, laid out as a wizard because of the amount of data.
/// A standalone route like every other feature's form — it pops with `true`
/// on success so the list behind it can refresh.
class CaseFormPage extends StatelessWidget {
  const CaseFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CaseFormCubit>()),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
        BlocProvider(create: (_) => getIt<PatientsCubit>()..getPatients()),
        BlocProvider(
          create: (_) => getIt<RestorationTypesCubit>()..getRestorationTypes(),
        ),
        // Active priorities only: a retired one must not be selectable for
        // new work, even though it stays on the cases already filed under it.
        BlocProvider(
          create: (_) => getIt<CasePrioritiesCubit>()..getCasePriorities(),
        ),
        // Loaded on the way into its own step rather than up front: which
        // optional stages exist depends on the restoration types picked.
        BlocProvider(create: (_) => getIt<OptionalStagesCubit>()),
      ],
      child: const _CaseFormView(),
    );
  }
}

class _CaseFormView extends StatefulWidget {
  const _CaseFormView();

  @override
  State<_CaseFormView> createState() => _CaseFormViewState();
}

class _CaseFormViewState extends State<_CaseFormView> {
  int _currentStep = 0;

  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _patientId;
  PatientModel? _selectedPatient;
  String? _doctorId;
  String? _clinicId;

  /// The whole row, not just its id, so the review step can show its label
  /// without a second lookup.
  CasePriorityModel? _priority;

  /// Whether the user has touched the priority field. Once they have, a late
  /// arriving priorities list must not overwrite their choice with the lab's
  /// default.
  bool _priorityTouched = false;

  DateTime? _dueDate;

  /// Today, date-only — the same shape `showDatePicker` returns, so the
  /// default and a picked value compare equal.
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Defaults to today rather than starting empty.
  ///
  /// A case is filed the day it arrives in all but a handful of instances, so
  /// making every user pick today by hand taxes the common path to spare the
  /// rare one. Still editable for the case that came in yesterday.
  DateTime? _receivedAt = _today;

  /// How the case arrives. Decides which half of the laboratory's routes the
  /// server cuts onto it, so it is asked on the first step rather than buried.
  ImpressionMethod? _impressionMethod;
  DigitalScanSource? _digitalScanSource;

  final List<RestorationEntry> _restorations = [];

  /// Whether this case repeats work the lab already did. A remake carries a
  /// link back to the case it redoes, so the bench can see what it is
  /// correcting instead of starting blind.
  bool _isRepeatCase = false;
  String? _previousCaseId;

  /// Shown on the field once a case is linked — the number, not the id.
  String? _previousCaseLabel;

  /// Each optional stage's answer, keyed by its id.
  ///
  /// A map rather than a set of "yes" ids: absent has to mean *unanswered*.
  /// A set could only say yes-or-not-yes, which silently turned every
  /// question the user never reached into a "no" — an answer given on their
  /// behalf, and the reason the submit below refuses until this is complete.
  Map<String, bool> _stageAnswers = {};

  /// Picked on the review step, uploaded one at a time as a second round of
  /// requests once the case itself exists — there is no case id to attach
  /// them to before that. Kept as parallel lists rather than a list of
  /// records so the review step only ever sees the names it needs to show.
  final List<String> _attachmentPaths = [];
  final List<String> _attachmentNames = [];

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      final files = result?.files ?? const [];
      if (files.isEmpty) return;
      setState(() {
        for (final file in files) {
          if (file.path == null) continue;
          _attachmentPaths.add(file.path!);
          _attachmentNames.add(file.name);
        }
      });
    } catch (e) {
      showToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: ToastState.error,
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachmentPaths.removeAt(index);
      _attachmentNames.removeAt(index);
    });
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _isoDate(DateTime? date) => date?.toIso8601String();

  /// Whether anything has been entered — asked when the user tries to leave.
  /// Losing this form is the most expensive of all: [_restorations] is built
  /// up one entry at a time through a sub-dialog.
  ///
  /// [_currentStep] is deliberately excluded: paging through the wizard is not
  /// an edit. `_clinicId` moves only with `_doctorId`, and `_selectedPatient`
  /// only with `_patientId`, so neither adds anything here.
  bool get _isDirty =>
      isTextDirty(_referenceController) ||
      isTextDirty(_notesController) ||
      _patientId != null ||
      _doctorId != null ||
      _priorityTouched ||
      _dueDate != null ||
      // Compared against the default, not against null: it is pre-filled with
      // today, and treating that as an edit would make an untouched form
      // prompt "discard your changes?" on the way out.
      _receivedAt != _today ||
      _impressionMethod != null ||
      _isRepeatCase ||
      _stageAnswers.isNotEmpty ||
      _restorations.isNotEmpty ||
      _attachmentPaths.isNotEmpty;

  void _onSubmit() {
    if (_patientId == null) {
      showToast(message: 'الرجاء اختيار المريض', state: ToastState.error);
      setState(() => _currentStep = 0);
      return;
    }
    if (_doctorId == null) {
      showToast(message: 'الرجاء اختيار الطبيب', state: ToastState.error);
      setState(() => _currentStep = 0);
      return;
    }
    // How the case arrived decides which head of the lab's route it runs on —
    // the server prunes the stages that do not apply — so a case with no
    // intake method is a case nobody can start.
    if (_impressionMethod == null) {
      showToast(
        message: 'حدّد طريقة الاستلام: تقليدية أم رقمية',
        state: ToastState.error,
      );
      setState(() => _currentStep = 0);
      return;
    }
    // A remake with no link to what it remakes is the one fact nobody can
    // recover afterwards.
    if (_isRepeatCase && _previousCaseId == null) {
      showToast(
        message: 'اختر الحالة القديمة التي تُعاد',
        state: ToastState.error,
      );
      setState(() => _currentStep = 0);
      return;
    }
    // A digital case has to say where the scan came from. The two answers send
    // the case down different paths — a doctor upload arrives with the file,
    // a lab session still has to be booked and driven — so leaving it blank
    // files a case nobody knows how to start.
    if (_impressionMethod == ImpressionMethod.digital &&
        _digitalScanSource == null) {
      showToast(
        message: 'حدّد مصدر المسح الرقمي: رفعه الطبيب أم جلسة سكنر',
        state: ToastState.error,
      );
      setState(() => _currentStep = 0);
      return;
    }
    if (_restorations.isEmpty) {
      showToast(
        message: 'أضف تعويضاً واحداً على الأقل',
        state: ToastState.error,
      );
      setState(() => _currentStep = 1);
      return;
    }

    // Every optional stage has to have been answered yes or no. An unanswered
    // one is not a "no": it is a question the user never saw, and filing the
    // case would decide it for them — silently, and in the direction that
    // leaves work off the route.
    final optionalStages = context.read<OptionalStagesCubit>().state;
    final unanswered = optionalStages.unanswered(_stageAnswers);
    if (unanswered.isNotEmpty) {
      showToast(
        // The first one by name, not a count: "3 unanswered" makes the user
        // hunt for which.
        message: 'أجب عن سؤال "${unanswered.first.name}"',
        state: ToastState.error,
      );
      setState(() => _currentStep = 2);
      return;
    }

    context.read<CaseFormCubit>().createCase(
      CreateCaseRequestModel(
        doctorId: _doctorId,
        clinicId: _clinicId,
        patientId: _patientId,
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        priorityId: _priority?.id,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        dueDate: _isoDate(_dueDate),
        receivedAt: _isoDate(_receivedAt),
        impressionMethod: _impressionMethod,
        digitalScanSource: _digitalScanSource,
        previousCaseId: _isRepeatCase ? _previousCaseId : null,
        // Case stages only. A restoration route's optional stages travel on
        // the restoration that runs them, just below — the server keeps the
        // two lists apart and drops a route stage sent up here.
        selectedStageIds: optionalStages.selectedCaseStageIds(_stageAnswers),
        restorations: _restorations
            .map(
              (r) => r.toRequest(
                optionalStageIds: optionalStages.selectedRouteStageIds(
                  _stageAnswers,
                  r.restorationTypeId,
                ),
              ),
            )
            .toList(),
      ),
      attachmentPaths: _attachmentPaths,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocConsumer<CaseFormCubit, CaseFormState>(
      listener: (context, state) {
        switch (state) {
          case CaseFormSuccess(:final failedAttachmentCount):
            showToast(
              message: failedAttachmentCount > 0
                  ? 'تمت إضافة الحالة، لكن تعذّر إرفاق $failedAttachmentCount '
                        'من الملفات — أضفها لاحقاً من تفاصيل الحالة'
                  : 'تمت إضافة الحالة',
              state: failedAttachmentCount > 0
                  ? ToastState.warning
                  : ToastState.success,
            );
            Navigator.of(context).pop(true);
          case CaseFormError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CaseFormSubmitting;
        return _buildWizard(isSubmitting);
      },
    );

    // The priorities list arrives after the first frame, so the lab's default
    // row is applied here rather than in initState — and only while the user
    // has not picked one themselves.
    final body = BlocListener<CasePrioritiesCubit, CasePrioritiesState>(
      listener: (context, state) {
        if (state is! CasePrioritiesLoaded || _priorityTouched) return;
        for (final priority in state.priorities) {
          if (priority.isDefault) {
            setState(() => _priority = priority);
            return;
          }
        }
      },
      child: content,
    );

    // The guard sits above the wizard and never consults _currentStep, so back
    // asks once and leaves the whole wizard — it does not walk back through
    // the steps. Stepping back is the body's "السابق" button.
    return UnsavedChangesGuard(
      isDirty: () => _isDirty,
      child: GlassScaffold(
        appBar: GlassAppBar(
          title: Text(
            'إضافة حالة',
            style: AppTextStyles.font18MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
        ),
        body: SafeArea(child: body),
      ),
    );
  }

  static const List<String> _stepTitles = [
    'معلومات المريض',
    'التعويضات',
    'مراحل إضافية',
    'مراجعة',
  ];

  int get _totalSteps => _stepTitles.length;

  /// Validates the current step's inputs; returns true if we may advance.
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_patientId == null) {
          showToast(message: 'الرجاء اختيار المريض', state: ToastState.error);
          return false;
        }
        if (_doctorId == null) {
          showToast(message: 'الرجاء اختيار الطبيب', state: ToastState.error);
          return false;
        }
        // Caught on the way out of the step as well as on submit: finding out
        // three screens later that the intake was incomplete means walking
        // back through a wizard.
        if (_impressionMethod == null) {
          showToast(
            message: 'حدّد طريقة الاستلام: تقليدية أم رقمية',
            state: ToastState.error,
          );
          return false;
        }
        if (_isRepeatCase && _previousCaseId == null) {
          showToast(
            message: 'اختر الحالة القديمة التي تُعاد',
            state: ToastState.error,
          );
          return false;
        }
        if (_impressionMethod == ImpressionMethod.digital &&
            _digitalScanSource == null) {
          showToast(
            message: 'حدّد مصدر المسح الرقمي: رفعه الطبيب أم جلسة سكنر',
            state: ToastState.error,
          );
          return false;
        }
        return true;
      case 1:
        if (_restorations.isEmpty) {
          showToast(
            message: 'أضف تعويضاً واحداً على الأقل',
            state: ToastState.error,
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _onNext() {
    if (!_validateCurrentStep()) return;
    if (_currentStep >= _totalSteps - 1) return;

    setState(() => _currentStep++);

    // Asked for on arrival, with the restoration types finally known — which
    // stages are on offer depends on them, so loading earlier would ask the
    // wrong question.
    if (_currentStep == 2) {
      context.read<OptionalStagesCubit>().load(
        [
          for (final restoration in _restorations)
            restoration.restorationTypeId,
        ],
        // A route has a traditional head and a digital head. Without the
        // intake the step would ask about stages this case will never run.
        intake: _impressionMethod,
      );
    }
  }

  void _onBack() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  /// Reloads the restoration-type catalog priced for the chosen doctor.
  ///
  /// A case-creation form must quote the doctor's own negotiated/tier rate
  /// (`GET /RestorationTypes/lookup`), not the plain catalog's currency-less
  /// list price — quoting a different total than the invoice charges is the
  /// one pricing bug a lab never forgives. Falls back to the plain list
  /// (`GET /RestorationTypes`) while no doctor is chosen yet, which is the
  /// unpriced-preview behaviour the form already had.
  /// What the server says this draft would be promised, or null while nothing
  /// can be said yet.
  ///
  /// Asked of `GET /Cases/expected-completion-preview` rather than worked out
  /// from the catalogue: the server falls back to a slower priority level when
  /// the chosen one has no duration configured, and a client that did not know
  /// that would show a date the case then contradicts the moment it is filed.
  DateTime? _serverExpectedAt;

  /// Rerun whenever the priority or the restoration lines change — those two
  /// are the whole input to the answer.
  Future<void> _refreshExpectedCompletion() async {
    final typeIds = _restorations.map((r) => r.restorationTypeId).toList();
    if (typeIds.isEmpty || _priority?.id == null) {
      setState(() => _serverExpectedAt = null);
      return;
    }

    final result = await getIt<CasesRepo>().getExpectedCompletionPreview(
      priorityId: _priority?.id,
      restorationTypeIds: typeIds,
    );
    if (!mounted) return;

    // A failed preview leaves the local estimate showing rather than blanking
    // the card: a floor the user can still override beats nothing at all.
    result.fold((_) {}, (date) {
      setState(() => _serverExpectedAt = date);
      if (date != null) _dueDate ??= date;
    });
  }

  void _refreshRestorationCatalog() {
    final doctorId = _doctorId;
    final cubit = context.read<RestorationTypesCubit>();
    if (doctorId == null) {
      cubit.getRestorationTypes();
      return;
    }

    cubit.getForDoctor(
      doctorId: doctorId,
      intake: switch (_impressionMethod) {
        ImpressionMethod.traditional =>
          RouteStageAppliesTo.traditionalOnly.value,
        ImpressionMethod.digital => RouteStageAppliesTo.digitalOnly.value,
        null => null,
      },
    );
  }

  Widget _stepContent(int index) {
    return switch (index) {
      // The intake sits above the patient details: it is the first thing the
      // receptionist knows about a case, and it decides which route the case
      // will run.
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CaseIntakePicker(
            method: _impressionMethod,
            scanSource: _digitalScanSource,
            onMethodChanged: (method) {
              setState(() {
                _impressionMethod = method;
                // A scan source is meaningless on a traditional intake, and the
                // request model asserts as much — clear it rather than sending a
                // contradiction.
                if (method != ImpressionMethod.digital) {
                  _digitalScanSource = null;
                }
              });
              _refreshRestorationCatalog();
            },
            onScanSourceChanged: (source) =>
                setState(() => _digitalScanSource = source),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          CasePatientStep(
            patientId: _patientId,
            onPatientChanged: (id, patient) => setState(() {
              _patientId = id;
              _selectedPatient = patient;
            }),
            referenceController: _referenceController,
            notesController: _notesController,
            doctorId: _doctorId,
            onDoctorChanged: (doctorId, clinicId) {
              setState(() {
                _doctorId = doctorId;
                _clinicId = clinicId;
              });
              _refreshRestorationCatalog();
            },
            priority: _priority,
            onPriorityChanged: (v) {
              setState(() {
                _priority = v;
                _priorityTouched = true;
              });
              // The priority is half the input to the promised date — the
              // other half being the restoration lines.
              _refreshExpectedCompletion();
            },
            dueDate: _dueDate,
            onPickDueDate: _pickDueDate,
            receivedAt: _receivedAt,
            onPickReceivedAt: _pickReceivedAt,
            isRepeatCase: _isRepeatCase,
            onCaseKindChanged: (isRepeat) => setState(() {
              _isRepeatCase = isRepeat;
              // A case turned back into a new one must not keep a link to the
              // work it was going to redo.
              if (!isRepeat) {
                _previousCaseId = null;
                _previousCaseLabel = null;
              }
            }),
            previousCaseLabel: _previousCaseLabel,
            onPickPreviousCase: _pickPreviousCase,
          ),
        ],
      ),
      1 => CaseRestorationsStep(
        restorations: _restorations,
        onAdd: _addRestoration,
        onEdit: _editRestoration,
        onRemove: (i) {
          setState(() => _restorations.removeAt(i));
          _refreshExpectedCompletion();
        },
      ),
      2 => CaseOptionalStagesStep(
        answers: _stageAnswers,
        onChanged: (answers) => setState(() => _stageAnswers = answers),
      ),
      _ => BlocBuilder<RestorationTypesCubit, RestorationTypesState>(
        builder: (context, state) {
          final types = state is RestorationTypesLoaded ? state.types : null;

          final estimate = types == null
              ? null
              : DeliveryEstimate.forCase(
                  restorationTypeIds: _restorations.map(
                    (r) => r.restorationTypeId,
                  ),
                  priorityId: _priority?.id,
                  types: types,
                  receivedAt: _receivedAt,
                );

          // The server's own answer where it gave one — it applies a fallback
          // to a slower priority level that the catalogue does not expose, so
          // the local figure can differ from what the case is actually dated
          // with. The local estimate stays as the fallback (and as the source
          // of the duration label, which the endpoint does not return).
          _dueDate ??= _serverExpectedAt ?? estimate?.expectedAt;

          return CaseReviewStep(
            patientName: _selectedPatient?.fullName ?? '',
            priorityName: _priority?.displayName ?? '',
            restorations: _restorations,
            estimate: estimate,
            expectedAt:
                _dueDate ?? _serverExpectedAt ?? estimate?.expectedAt,
            onPickExpectedAt: _pickDueDate,
            attachments: _attachmentNames,
            onPickAttachment: _pickAttachment,
            onRemoveAttachment: _removeAttachment,
          );
        },
      ),
    };
  }

  Widget _buildWizard(bool isSubmitting) {
    final isLast = _currentStep == _totalSteps - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- progress header: page number + bar ----
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _stepTitles[_currentStep],
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: context.glass.onGlass,
                      ),
                    ),
                  ),
                  Text(
                    'الخطوة ${_currentStep + 1} من $_totalSteps',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: context.glass.onGlassMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  minHeight: 6,
                  backgroundColor: context.glass.mutedSurface,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // ---- current step content ----
        Expanded(
          child: IndexedStack(
            index: _currentStep,
            sizing: StackFit.expand,
            children: List.generate(
              _totalSteps,
              (i) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _stepContent(i),
              ),
            ),
          ),
        ),
        // ---- bottom navigation buttons ----
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : _onBack,
                      child: const Text('السابق'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : (isLast ? _onSubmit : _onNext),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isLast ? 'حفظ الحالة' : 'التالي'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickReceivedAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _receivedAt = picked);
  }

  /// Picks the case this one redoes. Needs the patient first — a remake is
  /// tied to the same mouth, and that is what the list is scoped by.
  Future<void> _pickPreviousCase() async {
    final patientId = _patientId;
    if (patientId == null) {
      showToast(message: 'اختر المريض أولاً', state: ToastState.error);
      return;
    }

    final picked = await showPreviousCasePicker(
      context: context,
      patientId: patientId,
      patientName: _selectedPatient?.fullName ?? '',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _previousCaseId = picked.id;
      _previousCaseLabel = picked.label;
    });
  }

  Future<void> _addRestoration() => _openRestoration();

  /// Reopens an existing line so it can be corrected in place.
  ///
  /// A restoration is the most expensive thing on this form to enter — a type,
  /// a shade and a tooth chart — so a typo used to mean deleting it and
  /// building the whole line again.
  Future<void> _editRestoration(int index) => _openRestoration(index: index);

  /// Every tooth already marked on the case's other restoration lines.
  ///
  /// [skipIndex] is the line being edited, whose own teeth are of course still
  /// its to keep — without the exclusion, reopening a line would show all of
  /// its teeth locked against itself.
  Set<int> _teethTakenByOtherRestorations(int? skipIndex) {
    final taken = <int>{};
    for (var i = 0; i < _restorations.length; i++) {
      if (i == skipIndex) continue;
      taken.addAll(_restorations[i].teeth.map((t) => t.toothNumber));
    }
    return taken;
  }

  Future<void> _openRestoration({int? index}) async {
    final entry = await showDialog<RestorationEntry>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<RestorationTypesCubit>()),
          // Scoped to the dialog: each restoration answers the lab's options
          // for itself, so its preview must not outlive the line being edited.
          BlocProvider(create: (_) => getIt<RoutePreviewCubit>()),
        ],
        child: AddRestorationPage(
          impressionMethod: _impressionMethod,
          priorityId: _priority?.id,
          initial: index == null ? null : _restorations[index],
          takenTeeth: _teethTakenByOtherRestorations(index),
        ),
      ),
    );
    if (entry == null) return;

    setState(() {
      // Replaced in place rather than appended: an edit that added a second
      // line would double the case.
      if (index == null) {
        _restorations.add(entry);
      } else {
        _restorations[index] = entry;
      }
    });

    // The case is promised by its slowest piece, so every line changes the
    // answer.
    await _refreshExpectedCompletion();
  }
}
