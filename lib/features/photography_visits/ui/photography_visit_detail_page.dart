import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_card.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_info_tiles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_detail/photography_visit_detail_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_detail/photography_visit_detail_state.dart';
import 'package:dental_lab_app/features/photography_visits/ui/widgets/photography_action_sheets.dart';
import 'package:dental_lab_app/features/photography_visits/ui/widgets/photography_status_chip.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// One photography visit. Pops with `true` when anything on it changed, so
/// the list behind it knows to reload.
class PhotographyVisitDetailPage extends StatelessWidget {
  const PhotographyVisitDetailPage({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PhotographyVisitDetailCubit>()..load(visitId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  Future<void> _schedule(
    BuildContext context,
    PhotographyVisitDetailLoaded state,
  ) async {
    final cubit = context.read<PhotographyVisitDetailCubit>();
    final request = await showScheduleVisitSheet(
      context,
      visit: state.visit,
      employees: state.employees,
      currencies: state.currencies,
    );
    if (request != null) await cubit.schedule(request);
  }

  Future<void> _complete(
    BuildContext context,
    PhotographyVisitDetailLoaded state,
  ) async {
    final cubit = context.read<PhotographyVisitDetailCubit>();
    final request = await showCompleteVisitSheet(
      context,
      visit: state.visit,
      currencies: state.currencies,
    );
    if (request != null) await cubit.complete(request);
  }

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<PhotographyVisitDetailCubit>();
    final note = await showCancelVisitDialog(context);
    // Null is "dismissed"; an empty string is "cancel without a note".
    if (note != null) await cubit.cancel(note: note.isEmpty ? null : note);
  }

  Future<void> _addPhotos(BuildContext context) async {
    final cubit = context.read<PhotographyVisitDetailCubit>();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      final paths = [
        for (final file in result?.files ?? const <PlatformFile>[])
          if (file.path != null) file.path!,
      ];
      await cubit.uploadPhotos(paths);
    } catch (e) {
      showToast(message: 'تعذّر فتح منتقي الصور: $e', state: ToastState.error);
    }
  }

  Future<void> _deletePhoto(BuildContext context, String photoId) async {
    final cubit = context.read<PhotographyVisitDetailCubit>();
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الصورة',
      message: 'ستُحذف هذه الصورة من الزيارة.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed == true) await cubit.deletePhoto(photoId);
  }

  Future<void> _openPhoto(String? filePath) async {
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
      showToast(message: 'تعذّر فتح الصورة', state: ToastState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cubit = context.read<PhotographyVisitDetailCubit>();

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(cubit.changed);
      },
      child: GlassScaffold(
        appBar: GlassAppBar(
          title: Text(
            'زيارة تصوير',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
        ),
        body: SafeArea(
          child:
              BlocConsumer<
                PhotographyVisitDetailCubit,
                PhotographyVisitDetailState
              >(
                listenWhen: (_, current) =>
                    current is PhotographyVisitActionSuccess ||
                    current is PhotographyVisitActionError,
                listener: (context, state) {
                  switch (state) {
                    case PhotographyVisitActionSuccess(:final message):
                      showToast(message: message, state: ToastState.success);
                    case PhotographyVisitActionError(:final message):
                      showToast(message: message, state: ToastState.error);
                    default:
                      break;
                  }
                },
                buildWhen: (_, current) =>
                    current is! PhotographyVisitActionSuccess &&
                    current is! PhotographyVisitActionError,
                builder: (context, state) => switch (state) {
                  PhotographyVisitDetailLoaded() => SingleChildScrollView(
                    child: AdaptiveDetailSections(
                      side: [
                        if (state.visit.status.isOpen)
                          _Actions(
                            visit: state.visit,
                            isBusy: state.isBusy,
                            onSchedule: () => _schedule(context, state),
                            onComplete: () => _complete(context, state),
                            onCancel: () => _cancel(context),
                          ),
                      ],
                      main: [
                        _Info(visit: state.visit),
                        if (!state.visit.shade.isEmpty ||
                            state.visit.notes != null)
                          _ShadeInfo(visit: state.visit),
                        _Photos(
                          visit: state.visit,
                          isBusy: state.isBusy,
                          onAdd: () => _addPhotos(context),
                          onOpen: _openPhoto,
                          onDelete: (id) => _deletePhoto(context, id),
                        ),
                      ],
                    ),
                  ),
                  PhotographyVisitDetailError(:final message) => Center(
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
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.visit,
    required this.isBusy,
    required this.onSchedule,
    required this.onComplete,
    required this.onCancel,
  });

  final PhotographyVisitModel visit;
  final bool isBusy;
  final VoidCallback onSchedule;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GlassSectionTitle('الإجراءات'),
          if (visit.visitType.isSchedulable)
            OutlinedButton.icon(
              onPressed: isBusy ? null : onSchedule,
              icon: const Icon(Icons.event_available_outlined),
              label: Text(
                visit.status == PhotographyVisitStatus.scheduled
                    ? 'إعادة الجدولة'
                    : 'جدولة الزيارة',
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: isBusy ? null : onComplete,
            icon: const Icon(Icons.task_alt),
            label: const Text('إكمال الزيارة'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: isBusy ? null : onCancel,
            style: TextButton.styleFrom(foregroundColor: glass.error),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('إلغاء الزيارة'),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.visit});

  final PhotographyVisitModel visit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.doctorName ?? '—',
                  style: AppTextStyles.font18MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              PhotographyStatusChip(status: visit.status),
            ],
          ),
          const SizedBox(height: 12),
          GlassInfoTiles(
            tiles: [
              GlassInfoTile(
                icon: Icons.person_outline,
                label: 'المريض',
                value: visit.patientName,
                color: glass.info,
              ),
              GlassInfoTile(
                icon: Icons.photo_camera_outlined,
                label: 'نوع الزيارة',
                value: visit.visitType.label,
                color: glass.info,
                wide: true,
              ),
              GlassInfoTile(
                icon: Icons.event_outlined,
                label: 'الموعد',
                value: visit.scheduledAt == null
                    ? null
                    : ApiTime.displayDateTime(visit.scheduledAt),
                color: glass.warning,
              ),
              GlassInfoTile(
                icon: Icons.engineering_outlined,
                label: 'الفني',
                value: visit.assignedEmployeeName,
                color: glass.warning,
              ),
              GlassInfoTile(
                icon: Icons.payments_outlined,
                label: 'السعر',
                value: visit.priceLabel,
                color: glass.success,
              ),
              GlassInfoTile(
                icon: Icons.task_alt,
                label: 'اكتملت في',
                value: visit.completedAt == null
                    ? null
                    : ApiTime.displayDateTime(visit.completedAt),
                color: glass.success,
              ),
            ],
          ),
          if (visit.invoiceId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'سُجّل الرسم على حساب الطبيب',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShadeInfo extends StatelessWidget {
  const _ShadeInfo({required this.visit});

  final PhotographyVisitModel visit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final shade = visit.shade;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GlassSectionTitle('اللون والملاحظات'),
          GlassInfoTiles(
            tiles: [
              GlassInfoTile(
                icon: Icons.palette_outlined,
                label: 'لون السن',
                value: shade.toothShade,
                color: glass.info,
              ),
              GlassInfoTile(
                icon: Icons.style_outlined,
                label: 'دليل الألوان',
                value: shade.shadeGuideUsed ? 'استُخدم' : 'لم يُستخدم',
                color: glass.info,
              ),
              GlassInfoTile(
                icon: Icons.opacity,
                label: 'الشفافية',
                value: shade.translucencyNotes,
                color: glass.info,
                wide: true,
              ),
              GlassInfoTile(
                icon: Icons.gradient,
                label: 'التدرّج والشكل',
                value: shade.gradientAndShapeNotes,
                color: glass.info,
                wide: true,
              ),
              GlassInfoTile(
                icon: Icons.sentiment_satisfied_alt_outlined,
                label: 'خط الابتسامة',
                value: shade.smileLineNotes,
                color: glass.info,
                wide: true,
              ),
              GlassInfoTile(
                icon: Icons.water_drop_outlined,
                label: 'لون اللثة',
                value: shade.gumColorNotes,
                color: glass.info,
                wide: true,
              ),
              GlassInfoTile(
                icon: Icons.notes_outlined,
                label: 'ملاحظات',
                value: visit.notes,
                color: glass.onGlassMuted,
                wide: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({
    required this.visit,
    required this.isBusy,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  final PhotographyVisitModel visit;
  final bool isBusy;
  final VoidCallback onAdd;
  final ValueChanged<String?> onOpen;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canUpload = visit.status != PhotographyVisitStatus.cancelled;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GlassSectionTitle('الصور (${visit.photos.length})'),
              ),
              if (canUpload)
                TextButton.icon(
                  onPressed: isBusy ? null : onAdd,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('إضافة'),
                ),
            ],
          ),
          if (visit.photos.isEmpty)
            Text(
              'لا توجد صور بعد',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // As many ~110dp thumbnails as fit, never fewer than three.
                final columns = (constraints.maxWidth / 110).floor().clamp(
                  3,
                  8,
                );
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final photo in visit.photos)
                      _Thumbnail(
                        photo: photo,
                        onOpen: () => onOpen(photo.filePath),
                        onDelete: isBusy ? null : () => onDelete(photo.id),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.photo,
    required this.onOpen,
    required this.onDelete,
  });

  final PhotographyVisitPhotoModel photo;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(photo.filePath);
    final radius = BorderRadius.circular(10);

    return Stack(
      fit: StackFit.expand,
      children: [
        InkWell(
          onTap: onOpen,
          borderRadius: radius,
          child: url == null
              ? const Icon(Icons.broken_image_outlined)
              : ClipRRect(
                  borderRadius: radius,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
        PositionedDirectional(
          top: 2,
          end: 2,
          child: IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            tooltip: 'حذف',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ],
    );
  }
}
