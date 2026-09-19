import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_hr/employee_hr_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_state.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_details_body.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_notes_sheet.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_work_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dental_lab_app/features/details_questions/ui/widgets/person_answers_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Employee detail screen — shows the profile, photo and attachments, and lets
/// the user add attachments, open them or remove them.
class EmployeeDetailPage extends StatelessWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmployeeDetailsCubit>()..getEmployee(employeeId),
      child: const _EmployeeDetailView(),
    );
  }
}

class _EmployeeDetailView extends StatelessWidget {
  const _EmployeeDetailView();

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final cubit = context.read<EmployeeDetailsCubit>();
    try {
      final result = await FilePicker.pickFiles();
      final path = result?.files.single.path;
      if (path != null) await cubit.uploadFile(path);
    } catch (e) {
      showToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: ToastState.error,
      );
    }
  }

  /// Replaces the employee's photo.
  ///
  /// The detail cubit refetches afterwards rather than the HR cubit's answer
  /// being spliced in: the two hold the same employee, and one of them
  /// quietly holding a newer copy is how a screen starts disagreeing with
  /// itself.
  Future<void> _changePhoto(BuildContext context, EmployeeModel employee) async {
    final detailsCubit = context.read<EmployeeDetailsCubit>();
    final hrCubit = getIt<EmployeeHrCubit>();

    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    await hrCubit.uploadImage(employeeId: employee.id, filePath: path);
    final state = hrCubit.state;

    if (state is EmployeeHrError) {
      showToast(message: state.message, state: ToastState.error);
      return;
    }
    if (state is EmployeeHrSaved) {
      showToast(message: state.message, state: ToastState.success);
      await detailsCubit.getEmployee(employee.id);
    }
  }

  /// Ends the employment, dated — and says plainly that the person stays.
  Future<void> _terminate(BuildContext context, EmployeeModel employee) async {
    final detailsCubit = context.read<EmployeeDetailsCubit>();

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'تاريخ إنهاء العمل',
    );
    if (date == null || !context.mounted) return;

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'إنهاء عمل الموظف',
      message:
          'سيُسجَّل انتهاء العمل بتاريخ ${ApiTime.formatDate(date)}. '
          'يبقى الموظف وسجلّه (الحضور، الرواتب، الحالات) كما هو، '
          'ويمكن إعادة تعيينه لاحقاً.',
      confirmText: 'إنهاء العمل',
      isDestructive: true,
    );
    if (confirmed != true) return;

    final hrCubit = getIt<EmployeeHrCubit>();
    await hrCubit.terminate(employeeId: employee.id, terminationDate: date);

    final state = hrCubit.state;
    if (state is EmployeeHrError) {
      showToast(message: state.message, state: ToastState.error);
      return;
    }
    if (state is EmployeeHrSaved) {
      showToast(message: state.message, state: ToastState.success);
      await detailsCubit.getEmployee(employee.id);
    }
  }

  Future<void> _reinstate(BuildContext context, EmployeeModel employee) async {
    final detailsCubit = context.read<EmployeeDetailsCubit>();
    final hrCubit = getIt<EmployeeHrCubit>();

    await hrCubit.reinstate(employee.id);

    final state = hrCubit.state;
    if (state is EmployeeHrError) {
      showToast(message: state.message, state: ToastState.error);
      return;
    }
    if (state is EmployeeHrSaved) {
      showToast(message: state.message, state: ToastState.success);
      await detailsCubit.getEmployee(employee.id);
    }
  }

  Future<void> _openFile(String? filePath) async {
    final url = resolveMediaUrl(filePath);
    if (url == null) {
      showToast(message: 'لا يوجد ملف للفتح', state: ToastState.error);
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      showToast(message: 'تعذّر فتح الملف', state: ToastState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeeDetailsCubit, EmployeeDetailsState>(
      listenWhen: (previous, current) =>
          current is EmployeeDetailsActionError ||
          current is EmployeeDetailsActionSuccess,
      listener: (context, state) {
        switch (state) {
          case EmployeeDetailsActionSuccess(:final message):
            showToast(message: message, state: ToastState.success);
          case EmployeeDetailsActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! EmployeeDetailsActionError &&
          current is! EmployeeDetailsActionSuccess,
      builder: (context, state) {
        final employee = state is EmployeeDetailsLoaded ? state.employee : null;

        // No `appBar` here: once loaded, the body supplies its own collapsing
        // SliverAppBar. A plain glass bar is used only for the loading and
        // error states, which have no header to collapse.
        return GlassScaffold(
          appBar: employee != null
              ? null
              : GlassAppBar(
                  title: Text(
                    'تفاصيل الموظف',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: context.glass.onGlass,
                    ),
                  ),
                ),
          body: switch (state) {
            EmployeeDetailsLoaded(:final employee, :final isBusy) =>
              EmployeeDetailsBody(
                employee: employee,
                isBusy: isBusy,
                onEdit: () async {
                  await context.push(
                    Routes.employeeFormScreen,
                    extra: employee,
                  );
                  if (context.mounted) {
                    context.read<EmployeeDetailsCubit>().getEmployee(
                      employee.id,
                    );
                  }
                },
                onAddFile: () => _pickAndUploadFile(context),
                onDeleteFile: (fileId) =>
                    context.read<EmployeeDetailsCubit>().deleteFile(fileId),
                onOpenFile: (file) => _openFile(file.filePath),
                onChangePhoto: () => _changePhoto(context, employee),
                onOpenAnswers: () => showPersonAnswersSheet(
                  context,
                  personId: employee.id,
                  isDoctor: false,
                  personName: employee.fullName,
                ),
                onTerminate: () => _terminate(context, employee),
                onReinstate: () => _reinstate(context, employee),
                onOpenNotes: () => showEmployeeNotesSheet(
                  context,
                  employeeId: employee.id,
                  employeeName: employee.fullName,
                ),
                onOpenWorkAndPay: () => showEmployeeWorkSheet(
                  context,
                  employeeId: employee.id,
                  employeeName: employee.fullName,
                ),
              ),
            EmployeeDetailsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: context.glass.onGlassMuted,
                  ),
                ),
              ),
            ),
            _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
          },
        );
      },
    );
  }
}
