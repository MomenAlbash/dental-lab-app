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
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_patient_step.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_restorations_step.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_review_step.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
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
  final String? notes;
  final List<ToothMarkModel> teeth;
  final String? shadeLayout;
  final String? shadeCervical;
  final String? shadeMiddle;
  final String? shadeIncisal;
  final String? baseToothColor;

  CaseRestorationRequestModel toRequest() => CaseRestorationRequestModel(
    restorationTypeId: restorationTypeId,
    quantity: quantity,
    unitPrice: unitPrice,
    notes: notes,
    teeth: teeth,
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
  DateTime? _receivedAt;

  final List<RestorationEntry> _restorations = [];

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
      _receivedAt != null ||
      _restorations.isNotEmpty;

  void _onSubmit() {
    if (_patientId == null) {
      ShowToast(message: 'الرجاء اختيار المريض', state: toastState.error);
      setState(() => _currentStep = 0);
      return;
    }
    if (_doctorId == null) {
      ShowToast(message: 'الرجاء اختيار الطبيب', state: toastState.error);
      setState(() => _currentStep = 0);
      return;
    }
    if (_restorations.isEmpty) {
      ShowToast(
        message: 'أضف تعويضاً واحداً على الأقل',
        state: toastState.error,
      );
      setState(() => _currentStep = 1);
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
        restorations: _restorations.map((r) => r.toRequest()).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocConsumer<CaseFormCubit, CaseFormState>(
      listener: (context, state) {
        switch (state) {
          case CaseFormSuccess():
            ShowToast(message: 'تمت إضافة الحالة', state: toastState.success);
            Navigator.of(context).pop(true);
          case CaseFormError(:final message):
            ShowToast(message: message, state: toastState.error);
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
    'مراجعة',
  ];

  int get _totalSteps => _stepTitles.length;

  /// Validates the current step's inputs; returns true if we may advance.
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_patientId == null) {
          ShowToast(message: 'الرجاء اختيار المريض', state: toastState.error);
          return false;
        }
        if (_doctorId == null) {
          ShowToast(message: 'الرجاء اختيار الطبيب', state: toastState.error);
          return false;
        }
        return true;
      case 1:
        if (_restorations.isEmpty) {
          ShowToast(
            message: 'أضف تعويضاً واحداً على الأقل',
            state: toastState.error,
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
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _onBack() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Widget _stepContent(int index) {
    return switch (index) {
      0 => CasePatientStep(
        patientId: _patientId,
        onPatientChanged: (id, patient) => setState(() {
          _patientId = id;
          _selectedPatient = patient;
        }),
        referenceController: _referenceController,
        notesController: _notesController,
        doctorId: _doctorId,
        onDoctorChanged: (doctorId, clinicId) => setState(() {
          _doctorId = doctorId;
          _clinicId = clinicId;
        }),
        priority: _priority,
        onPriorityChanged: (v) => setState(() {
          _priority = v;
          _priorityTouched = true;
        }),
        dueDate: _dueDate,
        onPickDueDate: _pickDueDate,
        receivedAt: _receivedAt,
        onPickReceivedAt: _pickReceivedAt,
      ),
      1 => CaseRestorationsStep(
        restorations: _restorations,
        onAdd: _addRestoration,
        onRemove: (i) => setState(() => _restorations.removeAt(i)),
      ),
      _ => CaseReviewStep(
        patientName: _selectedPatient?.fullName ?? '',
        priorityName: _priority?.displayName ?? '',
        restorations: _restorations,
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

  Future<void> _addRestoration() async {
    final entry = await showDialog<RestorationEntry>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<RestorationTypesCubit>(),
        child: const AddRestorationPage(),
      ),
    );

    if (entry != null) setState(() => _restorations.add(entry));
  }
}
