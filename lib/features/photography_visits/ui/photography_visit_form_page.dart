import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_save_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_form/photography_visit_form_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_form/photography_visit_form_state.dart';
import 'package:dental_lab_app/features/photography_visits/ui/widgets/date_time_pick.dart';
import 'package:dental_lab_app/features/photography_visits/ui/widgets/shade_notes_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs a photography visit for a doctor. Pops with the created visit.
class PhotographyVisitFormPage extends StatelessWidget {
  const PhotographyVisitFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PhotographyVisitFormCubit>()..loadCatalog(),
      child: const _FormView(),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView();

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _shade = ShadeNotesControllers();

  String? _doctorId;
  String? _patientId;
  String? _currencyId;
  PhotographyVisitType _visitType =
      PhotographyVisitType.labTechnicianVisitsClinic;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    _shade.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final doctorId = _doctorId;
    if (doctorId == null) return;

    final notes = _notesController.text.trim();
    context.read<PhotographyVisitFormCubit>().create(
      CreatePhotographyVisitRequestModel(
        doctorId: doctorId,
        patientId: _patientId,
        visitType: _visitType,
        // Only a visit to the clinic has a date to keep.
        scheduledAt: _visitType.isSchedulable ? _scheduledAt : null,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        currencyId: _currencyId,
        notes: notes.isEmpty ? null : notes,
        shade: _shade.toModel(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'طلب زيارة تصوير',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child:
            BlocConsumer<PhotographyVisitFormCubit, PhotographyVisitFormState>(
              listener: (context, state) {
                switch (state) {
                  case PhotographyVisitFormSuccess(:final visit):
                    showToast(
                      message: 'تم تسجيل الزيارة',
                      state: ToastState.success,
                    );
                    Navigator.of(context).pop(visit);
                  case PhotographyVisitFormSubmitError(:final message):
                    showToast(message: message, state: ToastState.error);
                  default:
                    break;
                }
              },
              buildWhen: (_, current) =>
                  current is! PhotographyVisitFormSuccess &&
                  current is! PhotographyVisitFormSubmitError,
              builder: (context, state) => switch (state) {
                PhotographyVisitFormReady() => _buildForm(context, state),
                PhotographyVisitFormCatalogError(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font14RegularSecondary.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ),
                ),
                _ => const Center(
                  child: CustomCircleProgressIndiacatorWidget(),
                ),
              },
            ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, PhotographyVisitFormReady state) {
    final enabled = !state.isSubmitting;
    final cubit = context.read<PhotographyVisitFormCubit>();

    // One currency means nothing to ask.
    if (_currencyId == null && state.currencies.length == 1) {
      _currencyId = state.currencies.single.id;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              // A form: capped and centred on a tablet, never stretched.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const GlassSectionTitle('الطبيب والمريض'),
                      DropdownButtonFormField<String>(
                        initialValue: _doctorId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'الطبيب',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final doctor in state.doctors)
                            DropdownMenuItem(
                              value: doctor.id,
                              child: Text(
                                doctor.fullName.isEmpty ? '—' : doctor.fullName,
                              ),
                            ),
                        ],
                        onChanged: enabled
                            ? (id) {
                                setState(() {
                                  _doctorId = id;
                                  _patientId = null;
                                });
                                cubit.selectDoctor(id);
                              }
                            : null,
                        validator: (id) => id == null ? 'اختر الطبيب' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        // Rebuilt per doctor so a stale pick cannot linger.
                        key: ValueKey('patients-$_doctorId'),
                        initialValue: _patientId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: state.isLoadingPatients
                              ? 'جارٍ تحميل المرضى…'
                              : 'المريض (اختياري)',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            child: Text('بدون مريض'),
                          ),
                          for (final patient in state.patients)
                            DropdownMenuItem<String?>(
                              value: patient.id,
                              child: Text(
                                patient.fullName.isEmpty
                                    ? '—'
                                    : patient.fullName,
                              ),
                            ),
                        ],
                        onChanged: enabled && _doctorId != null
                            ? (id) => setState(() => _patientId = id)
                            : null,
                      ),

                      const SizedBox(height: 20),
                      const GlassSectionTitle('نوع الزيارة'),
                      SegmentedButton<PhotographyVisitType>(
                        segments: [
                          for (final type in PhotographyVisitType.values)
                            ButtonSegment(
                              value: type,
                              label: Text(type.label, maxLines: 2),
                            ),
                        ],
                        selected: {_visitType},
                        onSelectionChanged: enabled
                            ? (s) => setState(() => _visitType = s.first)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      if (_visitType.isSchedulable)
                        OutlinedButton.icon(
                          onPressed: enabled
                              ? () async {
                                  final picked = await pickDateTime(
                                    context,
                                    initial: _scheduledAt,
                                  );
                                  if (picked != null) {
                                    setState(() => _scheduledAt = picked);
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            _scheduledAt == null
                                ? 'موعد الزيارة (اختياري)'
                                : ApiTime.displayDateTime(_scheduledAt),
                          ),
                        ),

                      const SizedBox(height: 20),
                      const GlassSectionTitle('السعر'),
                      Text(
                        // Unlike shipping, this charge is shown to the doctor
                        // as is — say so before anyone types a number.
                        'يُسجَّل على حساب الطبيب عند إكمال الزيارة ويظهر له',
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: context.glass.onGlassMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              controller: _priceController,
                              hintText: 'السعر',
                              enabled: enabled,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final price = double.tryParse(
                                  value?.trim() ?? '',
                                );
                                return price == null || price < 0
                                    ? 'قيمة غير صالحة'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _currencyId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'العملة',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                for (final currency in state.currencies)
                                  DropdownMenuItem(
                                    value: currency.id,
                                    child: Text(
                                      currency.code ?? currency.name ?? '—',
                                    ),
                                  ),
                              ],
                              onChanged: enabled
                                  ? (id) => setState(() => _currencyId = id)
                                  : null,
                              validator: (id) {
                                final price =
                                    double.tryParse(
                                      _priceController.text.trim(),
                                    ) ??
                                    0;
                                // A price nobody can bill is not a price.
                                return price > 0 && id == null
                                    ? 'اختر العملة'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const GlassSectionTitle('اللون والملاحظات السريرية'),
                      ShadeNotesFields(controllers: _shade, enabled: enabled),
                      AppTextFormField(
                        controller: _notesController,
                        hintText: 'ملاحظات',
                        enabled: enabled,
                        maxLines: 3,
                        validator: (_) => null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        GlassSaveBar(
          isSubmitting: state.isSubmitting,
          label: 'تسجيل الزيارة',
          onSave: _submit,
        ),
      ],
    );
  }
}
