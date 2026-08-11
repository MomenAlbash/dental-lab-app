import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_exception_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_exceptions/scanner_exceptions_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_exceptions/scanner_exceptions_state.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/widgets/scanner_exception_form_dialog.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/widgets/scanner_exception_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Date overrides — closures and one-off changed hours — for the next few
/// months.
class ScannerExceptionsTab extends StatefulWidget {
  const ScannerExceptionsTab({super.key});

  @override
  State<ScannerExceptionsTab> createState() => ScannerExceptionsTabState();
}

class ScannerExceptionsTabState extends State<ScannerExceptionsTab> {
  List<ScannerAvailabilityExceptionModel>? _lastExceptions;

  /// Called by the page's add button as well as the rows' edit action.
  Future<void> openForm({ScannerAvailabilityExceptionModel? exception}) async {
    final cubit = context.read<ScannerExceptionsCubit>();

    final body = await showDialog<SaveScannerAvailabilityExceptionRequestModel>(
      context: context,
      builder: (_) => ScannerExceptionFormDialog(initialException: exception),
    );
    if (body == null) return;

    await cubit.saveException(body);
  }

  Future<void> _confirmDelete(
    ScannerAvailabilityExceptionModel exception,
  ) async {
    final cubit = context.read<ScannerExceptionsCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الاستثناء',
      message:
          'سيعود يوم ${exception.dateLabel} إلى الدوام الأسبوعي المعتاد. متابعة؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) await cubit.deleteException(exception.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerExceptionsCubit, ScannerExceptionsState>(
      buildWhen: (previous, current) =>
          current is ScannerExceptionsInitial ||
          current is ScannerExceptionsLoading ||
          current is ScannerExceptionsLoaded ||
          current is ScannerExceptionsError,
      builder: (context, state) {
        if (state is ScannerExceptionsLoaded) {
          _lastExceptions = state.exceptions;
        }

        final exceptions = switch (state) {
          ScannerExceptionsLoaded(:final exceptions) => exceptions,
          ScannerExceptionsLoading() => _lastExceptions,
          _ => null,
        };

        return switch ((state, exceptions)) {
          (_, final List<ScannerAvailabilityExceptionModel> loaded)
              when loaded.isEmpty =>
            const _Empty(),
          (_, final List<ScannerAvailabilityExceptionModel> loaded) =>
            AdaptiveCollection<ScannerAvailabilityExceptionModel>(
              items: loaded,
              onRefresh: context.read<ScannerExceptionsCubit>().getExceptions,
              itemBuilder: (context, exception, _) =>
                  ScannerExceptionListItemWidget(
                    exception: exception,
                    onEdit: () => openForm(exception: exception),
                    onDelete: () => _confirmDelete(exception),
                  ),
            ),
          (ScannerExceptionsError(:final message), null) => Center(
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
          _ => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: GlassListSkeleton(),
          ),
        };
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: glass.surfaceGradient,
                border: Border.all(color: glass.strokeColor),
              ),
              child: Icon(
                Icons.event_busy_outlined,
                size: 40,
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا يوجد استثناءات',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'المواعيد الأسبوعية تنطبق على كل الأيام. أضف استثناءً للعطل أو '
              'لدوام مختلف بيوم محدد.',
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
