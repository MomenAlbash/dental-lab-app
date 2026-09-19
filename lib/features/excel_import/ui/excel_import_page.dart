import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/excel_import/data/models/import_session_model.dart';
import 'package:dental_lab_app/features/excel_import/logic/excel_import/excel_import_cubit.dart';
import 'package:dental_lab_app/features/excel_import/ui/widgets/import_session_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bulk import from a spreadsheet.
///
/// Two steps, in this order on the screen because that is the order they
/// happen: download the blank template for the thing you are importing, fill
/// it in, upload it. The server then works through the file in the background,
/// and the runs below update themselves while anything is still going.
class ExcelImportPage extends StatelessWidget {
  const ExcelImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExcelImportCubit>()..load(),
      child: const _ExcelImportView(),
    );
  }
}

class _ExcelImportView extends StatefulWidget {
  const _ExcelImportView();

  @override
  State<_ExcelImportView> createState() => _ExcelImportViewState();
}

class _ExcelImportViewState extends State<_ExcelImportView> {
  ImportEntityType _entityType = ImportEntityType.doctors;

  Future<void> _upload(BuildContext context) async {
    final cubit = context.read<ExcelImportCubit>();

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    await cubit.upload(entityType: _entityType, filePath: path);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    // Bulk-creating doctors, patients or employees is the same authority as
    // creating them one at a time — and this creates far more of them.
    final canImport = getIt<SessionCubit>().state.canEdit(
      PermissionName.users,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.excelImportScreen),
      appBar: GlassAppBar(
        title: Text(
          'استيراد من Excel',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: !canImport
            ? const _NoAccess()
            : BlocConsumer<ExcelImportCubit, ExcelImportState>(
                listenWhen: (previous, current) =>
                    current is ExcelImportActionError ||
                    current is ExcelImportTemplateReady,
                listener: (context, state) {
                  switch (state) {
                    case ExcelImportActionError(:final message):
                      showToast(message: message, state: ToastState.error);
                    case ExcelImportTemplateReady(:final entityType, :final bytes):
                      showToast(
                        message:
                            'جاهز قالب ${entityType.label} '
                            '(${bytes.length ~/ 1024} ك.ب) — احفظوه من المشاركة',
                        state: ToastState.success,
                      );
                    default:
                      break;
                  }
                },
                buildWhen: (previous, current) =>
                    current is! ExcelImportActionError &&
                    current is! ExcelImportTemplateReady,
                builder: (context, state) => switch (state) {
                  ExcelImportLoaded() => RefreshIndicator(
                    onRefresh: () => context.read<ExcelImportCubit>().load(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AdaptiveDetailSections(
                        main: [_Sessions(sessions: state.sessions)],
                        // The two steps come first on a phone: somebody
                        // opening this screen is here to import something,
                        // not to read a history of past runs.
                        side: [
                          _Steps(
                            entityType: _entityType,
                            isUploading: state.isUploading,
                            onEntityChanged: (type) =>
                                setState(() => _entityType = type),
                            onDownloadTemplate: () => context
                                .read<ExcelImportCubit>()
                                .downloadTemplate(_entityType),
                            onUpload: () => _upload(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ExcelImportError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
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
}

class _Steps extends StatelessWidget {
  const _Steps({
    required this.entityType,
    required this.isUploading,
    required this.onEntityChanged,
    required this.onDownloadTemplate,
    required this.onUpload,
  });

  final ImportEntityType entityType;
  final bool isUploading;
  final ValueChanged<ImportEntityType> onEntityChanged;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ماذا تستوردون؟',
            style: AppTextStyles.font14MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final type in ImportEntityType.values)
                ChoiceChip(
                  label: Text(type.label),
                  selected: entityType == type,
                  onSelected: (_) => onEntityChanged(type),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onDownloadTemplate,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('١ — تنزيل القالب'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.sm),
            child: Text(
              // Said, because uploading an arbitrary spreadsheet is the
              // commonest way this goes wrong: the columns have to match.
              'املؤوا القالب بلا تغيير أسماء الأعمدة',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),

          FilledButton.icon(
            onPressed: isUploading ? null : onUpload,
            icon: const Icon(Icons.upload_file_outlined, size: 16),
            label: Text(isUploading ? 'جارٍ الرفع…' : '٢ — رفع الملف'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              // The screen can be left: the run belongs to the server, not to
              // this page, and people close apps mid-upload.
              'يعالَج الملف على الخادم — يمكنكم إغلاق الشاشة والعودة لاحقاً',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sessions extends StatelessWidget {
  const _Sessions({required this.sessions});

  final List<ImportSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'لا توجد عمليات استيراد بعد',
          textAlign: TextAlign.center,
          style: AppTextStyles.font14RegularSecondary.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'العمليات',
          style: AppTextStyles.font16MediumText.copyWith(color: glass.onGlass),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final session in sessions)
          ImportSessionCard(session: session),
      ],
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا تملك صلاحية الاستيراد',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

