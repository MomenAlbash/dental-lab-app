import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_state.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_details_body.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dental_lab_app/features/details_questions/ui/widgets/person_answers_sheet.dart';
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

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final cubit = context.read<DoctorDetailsCubit>();
    try {
      final result = await FilePicker.pickFiles(withData: false);
      final path = result?.files.single.path;
      if (path != null) await cubit.uploadFile(path);
    } catch (e) {
      showToast(
        message: 'تعذّر فتح منتقي الملفات: $e',
        state: ToastState.error,
      );
    }
  }

  /// Replaces the doctor's photo, then refetches.
  ///
  /// The upload answers with the updated doctor, but the detail cubit is
  /// asked again rather than the answer being spliced in: two holders of the
  /// same record, one quietly newer, is how a screen starts disagreeing with
  /// itself.
  Future<void> _changePhoto(BuildContext context, String doctorId) async {
    final cubit = context.read<DoctorDetailsCubit>();

    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    final uploaded = await getIt<DoctorsRepo>().uploadImage(
      id: doctorId,
      filePath: path,
    );

    await uploaded.fold(
      (failure) async =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) async {
        showToast(message: 'تم تحديث الصورة', state: ToastState.success);
        await cubit.getDoctor(doctorId);
      },
    );
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
            showToast(message: message, state: ToastState.success);
          case DoctorDetailsActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! DoctorDetailsActionError &&
          current is! DoctorDetailsActionSuccess,
      builder: (context, state) {
        final doctor = state is DoctorDetailsLoaded ? state.doctor : null;

        // No `appBar` here: once loaded, the body supplies its own collapsing
        // SliverAppBar. A plain glass bar is used only for the loading and
        // error states, which have no header to collapse.
        return GlassScaffold(
          appBar: doctor != null
              ? null
              : GlassAppBar(
                  title: Text(
                    'تفاصيل الدكتور',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: context.glass.onGlass,
                    ),
                  ),
                ),
          body: switch (state) {
            DoctorDetailsLoaded(:final doctor, :final isBusy) =>
              DoctorDetailsBody(
                doctor: doctor,
                isBusy: isBusy,
                onEdit: () async {
                  await context.push(Routes.doctorFormScreen, extra: doctor);
                  if (context.mounted) {
                    context.read<DoctorDetailsCubit>().getDoctor(doctor.id);
                  }
                },
                onAddFile: () => _pickAndUploadFile(context),
                onOpenAnswers: () => showPersonAnswersSheet(
                  context,
                  personId: doctor.id,
                  isDoctor: true,
                  personName: doctor.fullName,
                ),
                onChangePhoto:
                    getIt<SessionCubit>().state.canEdit(PermissionName.doctor)
                    ? () => _changePhoto(context, doctor.id)
                    : null,
                onDeleteFile: (fileId) =>
                    context.read<DoctorDetailsCubit>().deleteFile(fileId),
                onOpenFile: (file) => _openFile(file.filePath),
                onPriceTierChanged: (tierId) =>
                    context.read<DoctorDetailsCubit>().setPriceTier(tierId),
                onApprove: (choice) =>
                    context.read<DoctorDetailsCubit>().approve(
                      clinicId: choice.clinicId,
                      newClinicName: choice.newClinicName,
                      zoneId: choice.zoneId,
                      newZoneName: choice.newZoneName,
                    ),
                onReject: (reason) =>
                    context.read<DoctorDetailsCubit>().reject(reason),
              ),
            DoctorDetailsError(:final message) => Center(
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
