import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/employees/data/models/create_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/models/update_employee_request_model.dart';
import 'package:dental_lab_app/features/employees/logic/employee_form/employee_form_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_form/employee_form_state.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit employee screen. Pass [initialEmployee] to open in edit mode.
///
/// Submission is driven by [EmployeeFormCubit]; the city picker is fed by the
/// standalone [CitiesCubit].
class EmployeeFormPage extends StatelessWidget {
  const EmployeeFormPage({super.key, this.initialEmployee});

  final EmployeeModel? initialEmployee;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<EmployeeFormCubit>()),
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
      ],
      child: _EmployeeFormView(initialEmployee: initialEmployee),
    );
  }
}

class _EmployeeFormView extends StatefulWidget {
  const _EmployeeFormView({this.initialEmployee});

  final EmployeeModel? initialEmployee;

  @override
  State<_EmployeeFormView> createState() => _EmployeeFormViewState();
}

class _EmployeeFormViewState extends State<_EmployeeFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: widget.initialEmployee?.firstName ?? '',
  );
  late final _lastNameController = TextEditingController(
    text: widget.initialEmployee?.lastName ?? '',
  );
  late final _nationalNumberController = TextEditingController(
    text: widget.initialEmployee?.nationalNumber ?? '',
  );
  late final _codeController = TextEditingController(
    text: widget.initialEmployee?.code ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialEmployee?.phoneNumber ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialEmployee?.address ?? '',
  );
  late final _bankNameController = TextEditingController(
    text: widget.initialEmployee?.bankName ?? '',
  );
  late final _bankAccountController = TextEditingController(
    text: widget.initialEmployee?.bankAccountNumber ?? '',
  );

  late EmployeeGender _gender =
      widget.initialEmployee?.gender ?? EmployeeGender.male;
  late DateTime? _dateOfBirth = _parseDate(widget.initialEmployee?.dateOfBirth);
  late String? _cityId = widget.initialEmployee?.cityId;

  bool get _isEditing => widget.initialEmployee != null;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalNumberController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// `yyyy-MM-dd` — the format the API's `dateOfBirth` field expects.
  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1930),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<EmployeeFormCubit>();

    if (_isEditing) {
      cubit.updateEmployee(
        id: widget.initialEmployee!.id,
        updateEmployeeRequestBody: UpdateEmployeeRequestModel(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          nationalNumber: _optional(_nationalNumberController),
          code: _optional(_codeController),
          gender: _gender.apiValue,
          dateOfBirth: _formatDate(_dateOfBirth),
          cityId: _cityId,
          phoneNumber: _optional(_phoneController),
          address: _optional(_addressController),
          bankName: _optional(_bankNameController),
          bankAccountNumber: _optional(_bankAccountController),
        ),
      );
    } else {
      cubit.createEmployee(
        CreateEmployeeRequestModel(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          nationalNumber: _optional(_nationalNumberController),
          code: _optional(_codeController),
          gender: _gender.apiValue,
          dateOfBirth: _formatDate(_dateOfBirth),
          cityId: _cityId,
          phoneNumber: _optional(_phoneController),
          address: _optional(_addressController),
          bankName: _optional(_bankNameController),
          bankAccountNumber: _optional(_bankAccountController),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل الموظف' : 'إضافة موظف',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<EmployeeFormCubit, EmployeeFormState>(
          listener: (context, state) {
            switch (state) {
              case EmployeeFormSuccess():
                ShowToast(
                  message: _isEditing ? 'تم حفظ التعديلات' : 'تمت إضافة الموظف',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case EmployeeFormError(:final message):
                ShowToast(message: message, state: toastState.error);
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: EmployeeFormFields(
                        formKey: _formKey,
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        nationalNumberController: _nationalNumberController,
                        codeController: _codeController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        bankNameController: _bankNameController,
                        bankAccountController: _bankAccountController,
                        gender: _gender,
                        onGenderChanged: (value) =>
                            setState(() => _gender = value),
                        dateOfBirth: _formatDate(_dateOfBirth),
                        onPickDate: _pickDateOfBirth,
                        cityId: _cityId,
                        onCityChanged: (value) =>
                            setState(() => _cityId = value),
                        isSubmitting: state is EmployeeFormSubmitting,
                        isEditing: _isEditing,
                        onSave: _onSavePressed,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
