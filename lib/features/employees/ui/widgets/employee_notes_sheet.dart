import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/logic/employee_hr/employee_hr_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The notes on one employee's file.
///
/// Append-only by design: each note carries who wrote it and when, and the way
/// to correct one is another note rather than an edit — there is no update
/// endpoint, and that is the right shape for a personnel record.
Future<void> showEmployeeNotesSheet(
  BuildContext context, {
  required String employeeId,
  required String employeeName,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<EmployeeHrCubit>()..loadNotes(employeeId),
      child: _EmployeeNotesSheet(
        employeeId: employeeId,
        employeeName: employeeName,
      ),
    ),
  );
}

class _EmployeeNotesSheet extends StatefulWidget {
  const _EmployeeNotesSheet({
    required this.employeeId,
    required this.employeeName,
  });

  final String employeeId;
  final String employeeName;

  @override
  State<_EmployeeNotesSheet> createState() => _EmployeeNotesSheetState();
}

class _EmployeeNotesSheetState extends State<_EmployeeNotesSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await context.read<EmployeeHrCubit>().addNote(
      employeeId: widget.employeeId,
      note: text,
    );
    if (mounted) _controller.clear();
  }

  Future<void> _delete(EmployeeNoteModel note) async {
    final cubit = context.read<EmployeeHrCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الملاحظة',
      message: 'لا يمكن التراجع.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deleteNote(employeeId: widget.employeeId, noteId: note.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.users);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: BlocBuilder<EmployeeHrCubit, EmployeeHrState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ملاحظات الموظف',
                  style: AppTextStyles.font18MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  widget.employeeName,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (canEdit) ...[
                  AppTextFormField(
                    controller: _controller,
                    hintText: 'اكتب ملاحظة…',
                    maxLines: 3,
                    validator: (_) => null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      onPressed: state is EmployeeHrBusy ? null : _add,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                switch (state) {
                  EmployeeHrNotesLoaded(:final notes) =>
                    notes.isEmpty
                        ? Text(
                            'لا توجد ملاحظات على هذا الموظف',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          )
                        : Column(
                            children: [
                              for (final note in notes)
                                _NoteRow(
                                  note: note,
                                  onDelete: canEdit
                                      ? () => _delete(note)
                                      : null,
                                ),
                            ],
                          ),
                  EmployeeHrError(:final message) => Text(
                    message,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.error,
                    ),
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                },
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, this.onDelete});

  final EmployeeNoteModel note;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            note.note ?? '',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  // Who and when, always: a personnel note nobody can trace
                  // back to an author is not a record, it is a rumour.
                  [
                    if (note.authorName?.trim().isNotEmpty ?? false)
                      note.authorName!,
                    ApiTime.displayDateTime(note.createdAt),
                  ].join(' · '),
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'حذف',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: glass.error,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
