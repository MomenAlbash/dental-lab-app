import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_excluded_representatives/doctor_excluded_representatives_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_excluded_representatives/doctor_excluded_representatives_state.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Representatives vetoed from this doctor's scanner sessions
/// (`DoctorRouting`) — a whole zone's rep never sent to one particular
/// doctor, without barring them from the rest of the zone.
class DoctorExcludedRepresentativesSection extends StatelessWidget {
  const DoctorExcludedRepresentativesSection({
    super.key,
    required this.doctorId,
    this.zoneId,
  });

  final String doctorId;
  final String? zoneId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<DoctorExcludedRepresentativesCubit>()
            ..load(doctorId: doctorId, zoneId: zoneId),
      child: const _ExcludedRepresentativesView(),
    );
  }
}

class _ExcludedRepresentativesView extends StatelessWidget {
  const _ExcludedRepresentativesView();

  Future<void> _addExclusion(
    BuildContext context,
    List<ZoneRepresentativeModel> candidates,
  ) async {
    final cubit = context.read<DoctorExcludedRepresentativesCubit>();

    if (candidates.isEmpty) {
      showToast(
        message: 'لا يوجد مندوبون في منطقة الطبيب لاستثناؤهم',
        state: ToastState.error,
      );
      return;
    }

    final choice = await showDialog<({String userId, String? reason})>(
      context: context,
      builder: (_) => _ExcludeRepresentativeDialog(candidates: candidates),
    );
    if (choice == null) return;

    await cubit.exclude(userId: choice.userId, reason: choice.reason);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocConsumer<
      DoctorExcludedRepresentativesCubit,
      DoctorExcludedRepresentativesState
    >(
      listener: (context, state) {
        if (state is DoctorExcludedRepresentativesMessage) {
          showToast(
            message: state.message,
            state: state.isError ? ToastState.error : ToastState.success,
          );
        }
      },
      buildWhen: (_, current) =>
          current is! DoctorExcludedRepresentativesMessage,
      builder: (context, state) {
        final loaded = state is DoctorExcludedRepresentativesLoaded
            ? state
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSectionTitle(
              'مندوبون مستثنون',
              count: loaded?.excluded.length,
              trailing: TextButton.icon(
                onPressed: loaded == null || loaded.isBusy
                    ? null
                    : () => _addExclusion(context, loaded.candidates),
                icon: const Icon(Icons.person_off_outlined, size: 18),
                label: const Text('استثناء'),
              ),
            ),
            Text(
              'هؤلاء لن يُرشَّحوا لجلسات مسح هذا الطبيب، حتى لو كانوا من '
              'مندوبي منطقته.',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            switch (state) {
              DoctorExcludedRepresentativesError(:final message) => Text(
                message,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              ),
              DoctorExcludedRepresentativesLoaded(:final excluded) =>
                excluded.isEmpty
                    ? Text(
                        'لا يوجد مندوبون مستثنون',
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final rep in excluded) ...[
                            _ExcludedRepresentativeRow(
                              representative: rep,
                              onRemove: () => context
                                  .read<DoctorExcludedRepresentativesCubit>()
                                  .unexclude(rep.userId),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
              _ => const GlassSkeletonBox(height: 80),
            },
          ],
        );
      },
    );
  }
}

class _ExcludedRepresentativeRow extends StatelessWidget {
  const _ExcludedRepresentativeRow({
    required this.representative,
    required this.onRemove,
  });

  final ZoneRepresentativeModel representative;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.surfaceColor,
        border: Border.all(color: glass.strokeColor),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          Icon(Icons.person_off_outlined, size: 18, color: glass.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              representative.name ?? 'مندوب بدون اسم',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
          IconButton(
            tooltip: 'إلغاء الاستثناء',
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18, color: glass.onGlassMuted),
          ),
        ],
      ),
    );
  }
}

/// Picks a representative from the zone's roster and an optional reason.
class _ExcludeRepresentativeDialog extends StatefulWidget {
  const _ExcludeRepresentativeDialog({required this.candidates});

  final List<ZoneRepresentativeModel> candidates;

  @override
  State<_ExcludeRepresentativeDialog> createState() =>
      _ExcludeRepresentativeDialogState();
}

class _ExcludeRepresentativeDialogState
    extends State<_ExcludeRepresentativeDialog> {
  final _reasonController = TextEditingController();
  String? _userId;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('استثناء مندوب', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final rep in widget.candidates)
                    ChoiceChip(
                      label: Text(rep.name ?? 'مندوب بدون اسم'),
                      selected: _userId == rep.userId,
                      onSelected: (_) => setState(() => _userId = rep.userId),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _reasonController,
                hintText: 'السبب (اختياري)',
                maxLines: 2,
                validator: (_) => null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: _userId == null
              ? null
              : () => Navigator.of(context).pop((
                  userId: _userId!,
                  reason: _reasonController.text.trim().isEmpty
                      ? null
                      : _reasonController.text.trim(),
                )),
          child: const Text('استثناء'),
        ),
      ],
    );
  }
}
