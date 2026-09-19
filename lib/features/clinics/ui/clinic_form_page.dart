import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_save_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/core/widgets/unsaved_changes_guard.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/create_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/update_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_state.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_form_fields.dart';
import 'package:dental_lab_app/features/zones/logic/zones/zones_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit clinic screen. Pass [initialClinic] to open in edit mode.
///
/// The form submission is driven by [ClinicFormCubit]; the city/zone
/// dropdowns are fed by the standalone [CitiesCubit]/[ZonesCubit] — the
/// concerns stay separate.
class ClinicFormPage extends StatelessWidget {
  const ClinicFormPage({super.key, this.initialClinic});

  final ClinicModel? initialClinic;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ClinicFormCubit>()),
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
        BlocProvider(create: (_) => getIt<ZonesCubit>()..getZones()),
      ],
      child: _ClinicFormView(initialClinic: initialClinic),
    );
  }
}

class _ClinicFormView extends StatefulWidget {
  const _ClinicFormView({this.initialClinic});

  final ClinicModel? initialClinic;

  @override
  State<_ClinicFormView> createState() => _ClinicFormViewState();
}

class _ClinicFormViewState extends State<_ClinicFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialClinic?.name ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialClinic?.phoneNumber ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.initialClinic?.email ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialClinic?.address ?? '',
  );

  late String? _cityId = widget.initialClinic?.cityId;
  late String? _zoneId = widget.initialClinic?.zoneId;

  bool get _isEditing => widget.initialClinic != null;

  @override
  void initState() {
    super.initState();
    // The preview mirrors the name as it is typed.
    _nameController.addListener(_onPreviewFieldChanged);
  }

  void _onPreviewFieldChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onPreviewFieldChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Whether anything differs from what the form opened with — asked when the
  /// user tries to leave, so a discarded edit is never silent.
  bool get _isDirty {
    final initial = widget.initialClinic;
    return isTextDirty(_nameController, initial?.name) ||
        isTextDirty(_phoneController, initial?.phoneNumber) ||
        isTextDirty(_emailController, initial?.email) ||
        isTextDirty(_addressController, initial?.address) ||
        _cityId != initial?.cityId ||
        _zoneId != initial?.zoneId;
  }

  /// Optional fields are sent as `null` rather than an empty string so the
  /// API stores "not set" instead of a blank value.
  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<ClinicFormCubit>();

    if (_isEditing) {
      // Only sent when it actually changed: a plain `null` here means "leave
      // the assignment alone", so re-sending the clinic's own current zone
      // id every save would work by accident today but is the wrong intent
      // to encode — and would misfire the moment the clear-zone sentinel
      // (an empty guid, not null) is ever involved.
      final zoneChanged = _zoneId != widget.initialClinic?.zoneId;

      cubit.updateClinic(
        id: widget.initialClinic!.id,
        updateClinicRequestBody: UpdateClinicRequestModel(
          name: _nameController.text.trim(),
          phoneNumber: _optional(_phoneController),
          email: _optional(_emailController),
          address: _optional(_addressController),
          cityId: _cityId,
          zoneId: zoneChanged ? _zoneId : null,
        ),
      );
    } else {
      cubit.createClinic(
        CreateClinicRequestModel(
          name: _nameController.text.trim(),
          phoneNumber: _optional(_phoneController),
          email: _optional(_emailController),
          address: _optional(_addressController),
          cityId: _cityId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: () => _isDirty,
      child: GlassScaffold(
        appBar: GlassAppBar(
          title: Text(
            _isEditing ? 'تعديل العيادة' : 'إضافة عيادة',
            style: AppTextStyles.font18MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
        ),
        // Save stays reachable without scrolling to the bottom of the form.
        bottomNavigationBar: BlocBuilder<ClinicFormCubit, ClinicFormState>(
          builder: (context, state) => GlassSaveBar(
            isSubmitting: state is ClinicFormSubmitting,
            label: _isEditing ? 'حفظ التعديلات' : 'إضافة العيادة',
            onSave: _onSavePressed,
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<ClinicFormCubit, ClinicFormState>(
            listener: (context, state) {
              switch (state) {
                case ClinicFormSuccess(:final clinic):
                  showToast(
                    message: _isEditing
                        ? 'تم حفظ التعديلات'
                        : 'تمت إضافة العيادة',
                    state: ToastState.success,
                  );
                  // The saved clinic is handed back, not just a "yes": a
                  // caller that opened this screen from a clinic field needs
                  // the record itself so it can select it.
                  Navigator.of(context).pop(clinic);
                case ClinicFormError(:final message):
                  showToast(message: message, state: ToastState.error);
                default:
                  break;
              }
            },
            builder: (context, state) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final contentWidth = isWide ? 560.0 : constraints.maxWidth;

                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 32 : 20,
                        20,
                        isWide ? 32 : 20,
                        // Clears the pinned action bar so the last field is
                        // never trapped underneath it.
                        110,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: ClinicFormFields(
                          formKey: _formKey,
                          nameController: _nameController,
                          addressController: _addressController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          cityId: _cityId,
                          onCityChanged: (value) =>
                              setState(() => _cityId = value),
                          zoneId: _zoneId,
                          onZoneChanged: _isEditing
                              ? (value) => setState(() => _zoneId = value)
                              : null,
                          isEditing: _isEditing,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
