import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_state.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_details_body.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Doctor detail screen — shows the profile, photo and attachments, and lets
/// the user change the photo, add attachments or remove them.
class DoctorDetailPage extends StatelessWidget {
  const DoctorDetailPage({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DoctorDetailsCubit>()..getDoctor(doctorId),
      child: const _DoctorDetailView(),
    );
  }
}

class _DoctorDetailView extends StatelessWidget {
  const _DoctorDetailView();

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

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final cubit = context.read<DoctorDetailsCubit>();
    try {
      final result = await FilePicker.pickFiles(withData: false);
      final path = result?.files.single.path;
      if (path != null) await cubit.uploadFile(path);
    } catch (e) {
      ShowToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: toastState.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorDetailsCubit, DoctorDetailsState>(
      listenWhen: (previous, current) =>
          current is DoctorDetailsActionError ||
          current is DoctorDetailsActionSuccess,
      listener: (context, state) {
        switch (state) {
          case DoctorDetailsActionSuccess(:final message):
            ShowToast(message: message, state: toastState.success);
          case DoctorDetailsActionError(:final message):
            ShowToast(message: message, state: toastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! DoctorDetailsActionError &&
          current is! DoctorDetailsActionSuccess,
      builder: (context, state) {
        final doctor = state is DoctorDetailsLoaded ? state.doctor : null;

        return Scaffold(
          backgroundColor: AppColorsManger.background,
          appBar: AppBar(
            title: Text(
              'تفاصيل الدكتور',
              style: AppTextStyles.font18MediumText,
            ),
            actions: [
              if (doctor != null)
                IconButton(
                  onPressed: () async {
                    await context.push(Routes.doctorFormScreen, extra: doctor);
                    if (context.mounted) {
                      context.read<DoctorDetailsCubit>().getDoctor(doctor.id);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              DoctorDetailsLoaded(:final doctor, :final isBusy) =>
                DoctorDetailsBody(
                  doctor: doctor,
                  isBusy: isBusy,
                  onAddFile: () => _pickAndUploadFile(context),
                  onDeleteFile: (fileId) =>
                      context.read<DoctorDetailsCubit>().deleteFile(fileId),
                  onOpenFile: (file) => _openFile(file.filePath),
                ),
              DoctorDetailsError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary,
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            },
          ),
        );
      },
    );
  }
}
