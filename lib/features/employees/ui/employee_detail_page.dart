import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_state.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_details_body.dart';
import 'package:file_picker/file_picker.dart';
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
      ShowToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: toastState.error,
      );
    }
  }

  Future<void> _openFile(String? filePath) async {
    final url = resolveMediaUrl(filePath);
    if (url == null) {
      ShowToast(message: 'لا يوجد ملف للفتح', state: toastState.error);
      return;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      ShowToast(message: 'تعذّر فتح الملف', state: toastState.error);
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
            ShowToast(message: message, state: toastState.success);
          case EmployeeDetailsActionError(:final message):
            ShowToast(message: message, state: toastState.error);
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
