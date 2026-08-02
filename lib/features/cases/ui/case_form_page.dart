import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_priority.dart';
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
/// When embedded in the cases shell, [onCreated] is called on success instead
/// of popping the route.
class CaseFormPage extends StatelessWidget {
  const CaseFormPage({super.key, this.onCreated});

  final VoidCallback? onCreated;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CaseFormCubit>()),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
        BlocProvider(create: (_) => getIt<PatientsCubit>()..getPatients()),
        BlocProvider(
          create: (_) =>
              getIt<RestorationTypesCubit>()..getRestorationTypes(),
        ),
      ],
      child: _CaseFormView(onCreated: onCreated),
    );
  }
}

class _CaseFormView extends StatefulWidget {
  const _CaseFormView({this.onCreated});

  final VoidCallback? onCreated;

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
  CasePriority _priority = CasePriority.normal;
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

  void _reset() {
    setState(() {
      _currentStep = 0;
      _patientId = null;
      _selectedPatient = null;
      _referenceController.clear();
      _notesController.clear();
      _doctorId = null;
      _clinicId = null;
      _priority = CasePriority.normal;
      _dueDate = null;
      _receivedAt = null;
      _restorations.clear();
    });
  }

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
      ShowToast(message: 'أضف تعويضاً واحداً على الأقل', state: toastState.error);
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
        priority: _priority.apiValue,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        dueDate: _isoDate(_dueDate),
        receivedAt: _isoDate(_receivedAt),
        restorations: _restorations.map((r) => r.toRequest()).toList(),
      ),
    );
  }

  void _onSuccess() {
    if (widget.onCreated != null) {
      _reset();
      widget.onCreated!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = BlocConsumer<CaseFormCubit, CaseFormState>(
      listener: (context, state) {
        switch (state) {
          case CaseFormSuccess():
            ShowToast(message: 'تمت إضافة الحالة', state: toastState.success);
            _onSuccess();
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

    // Standalone route gets its own Scaffold; embedded in the shell it doesn't.
    if (widget.onCreated != null) return content;

    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('إضافة حالة', style: AppTextStyles.font18MediumText),
      ),
      body: SafeArea(child: content),
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
        onPriorityChanged: (v) => setState(() => _priority = v),
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
        priority: _priority,
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
                      style: AppTextStyles.font16MediumText,
                    ),
                  ),
                  Text(
                    'الخطوة ${_currentStep + 1} من $_totalSteps',
                    style: AppTextStyles.font12RegularHint,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  minHeight: 6,
                  backgroundColor: AppColorsManger.moreLightGray,
                  color: AppColorsManger.primary,
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
                      backgroundColor: AppColorsManger.primary,
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
