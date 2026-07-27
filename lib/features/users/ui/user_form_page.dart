import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/users/data/models/create_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/user_form/user_form_cubit.dart';
import 'package:dental_lab_app/features/users/logic/user_form/user_form_state.dart';
import 'package:dental_lab_app/features/users/ui/widgets/user_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add-user screen. Every account is bound to either an employee or a doctor
/// record (`type`), given credentials and an optional role. Submission is
/// driven by [UserFormCubit]; the role/employee/doctor pickers are fed by the
/// standalone [RolesCubit], [EmployeesCubit] and [DoctorsCubit].
class UserFormPage extends StatelessWidget {
  const UserFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<UserFormCubit>()),
        BlocProvider(create: (_) => getIt<RolesCubit>()..getRoles()),
        BlocProvider(create: (_) => getIt<EmployeesCubit>()..getEmployees()),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
      ],
      child: const _UserFormView(),
    );
  }
}

class _UserFormView extends StatefulWidget {
  const _UserFormView();

  @override
  State<_UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<_UserFormView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  UserType _type = UserType.employee;
  bool _isAdmin = false;
  bool _obscurePassword = true;
  String? _roleId;
  String? _employeeId;
  String? _doctorId;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isEmployee = _type == UserType.employee;
    final linkedId = isEmployee ? _employeeId : _doctorId;
    if (linkedId == null) {
      ShowToast(
        message: isEmployee ? 'الرجاء اختيار الموظف' : 'الرجاء اختيار الطبيب',
        state: toastState.error,
      );
      return;
    }

    context.read<UserFormCubit>().createUser(
      CreateUserRequestModel(
        type: _type.apiValue,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _optional(_emailController),
        isAdmin: _isAdmin,
        roleId: _roleId,
        employeeId: isEmployee ? _employeeId : null,
        doctorId: isEmployee ? null : _doctorId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('إضافة مستخدم', style: AppTextStyles.font18MediumText),
      ),
      body: SafeArea(
        child: BlocConsumer<UserFormCubit, UserFormState>(
          listener: (context, state) {
            switch (state) {
              case UserFormSuccess():
                ShowToast(
                  message: 'تمت إضافة المستخدم',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case UserFormError(:final message):
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
                      child: UserFormFields(
                        formKey: _formKey,
                        type: _type,
                        onTypeChanged: (value) => setState(() {
                          _type = value;
                          _employeeId = null;
                          _doctorId = null;
                        }),
                        employeeId: _employeeId,
                        onEmployeeChanged: (value) =>
                            setState(() => _employeeId = value),
                        doctorId: _doctorId,
                        onDoctorChanged: (value) =>
                            setState(() => _doctorId = value),
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        emailController: _emailController,
                        obscurePassword: _obscurePassword,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        roleId: _roleId,
                        onRoleChanged: (value) =>
                            setState(() => _roleId = value),
                        isAdmin: _isAdmin,
                        onAdminChanged: (value) =>
                            setState(() => _isAdmin = value),
                        isSubmitting: state is UserFormSubmitting,
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
