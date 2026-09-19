import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:flutter/material.dart';

/// What the dispatcher chose in [showAssignRepresentativeSheet].
class AssignRepresentativeChoice {
  const AssignRepresentativeChoice({this.userId, this.note});

  /// Null asks the server to pick a representative itself — there is no way
  /// to leave the session with nobody assigned through this endpoint.
  final String? userId;
  final String? note;
}

/// Picks who goes to a scanner session.
///
/// [representatives] comes from the session's own eligible list — the zone
/// decides who can take it, and offering anyone else produces an assignment
/// the server refuses.
Future<AssignRepresentativeChoice?> showAssignRepresentativeSheet(
  BuildContext context, {
  required ScannerSessionModel session,
  required List<ZoneRepresentativeModel> representatives,
}) {
  return showGlassBottomSheet<AssignRepresentativeChoice>(
    context: context,
    builder: (_) =>
        _AssignSheet(session: session, representatives: representatives),
  );
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.session, required this.representatives});

  final ScannerSessionModel session;
  final List<ZoneRepresentativeModel> representatives;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  String? _userId;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userId = widget.session.assignedRepresentativeId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? get _note =>
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final session = widget.session;

    // Primary first, then by name: the zone's first choice is the default
    // answer, and burying it in an alphabetical list wastes that.
    final sorted = [...widget.representatives]
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return (a.name ?? '').compareTo(b.name ?? '');
      });

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إسناد مندوب',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                session.title,
                if (session.zoneName?.isNotEmpty ?? false) session.zoneName!,
              ].join(' · '),
              style: AppTextStyles.font13MediumPrimary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),

            // The refusal that led here. Shown rather than swallowed: it is
            // why the dispatcher is on this sheet at all.
            if (session.representativeResponse?.needsReassignment ?? false) ...[
              const SizedBox(height: AppSpacing.md),
              _DeclineNotice(session: session),
            ],

            const SizedBox(height: AppSpacing.lg),
            if (sorted.isEmpty)
              _EmptyZone(zoneName: session.zoneName)
            else
              for (final representative in sorted) ...[
                _RepresentativeOption(
                  representative: representative,
                  isSelected: _userId == representative.userId,
                  onTap: () => setState(() => _userId = representative.userId),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظة للمندوب (اختياري)',
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                // Not a "clear assignment" action — the endpoint has none. A
                // null representative id asks the server to pick one itself
                // (zone first, then whoever is free), so this is a distinct
                // action from picking a name below, not its opposite.
                if (session.assignedRepresentativeId != null)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(AssignRepresentativeChoice(note: _note)),
                      child: const Text('إسناد تلقائي'),
                    ),
                  )
                else
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _userId == null
                        ? null
                        : () => Navigator.of(context).pop(
                            AssignRepresentativeChoice(
                              userId: _userId,
                              note: _note,
                            ),
                          ),
                    child: const Text('إسناد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeclineNotice extends StatelessWidget {
  const _DeclineNotice({required this.session});

  final ScannerSessionModel session;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final note = session.representativeResponseNote?.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.error.withValues(alpha: 0.10),
        border: Border.all(color: glass.error.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_off_outlined, size: 18, color: glass.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اعتذر ${session.assignedRepresentativeName ?? 'المندوب'}',
                  style: AppTextStyles.font13MediumPrimary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyZone extends StatelessWidget {
  const _EmptyZone({required this.zoneName});

  final String? zoneName;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.mutedSurface,
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Text(
        zoneName == null || zoneName!.isEmpty
            ? 'لا يوجد مندوبون مؤهلون لهذه الجلسة'
            : 'لا يوجد مندوبون مؤهلون في منطقة "$zoneName"',
        textAlign: TextAlign.center,
        style: AppTextStyles.font13MediumPrimary.copyWith(
          color: glass.onGlassMuted,
        ),
      ),
    );
  }
}

class _RepresentativeOption extends StatelessWidget {
  const _RepresentativeOption({
    required this.representative,
    required this.isSelected,
    required this.onTap,
  });

  final ZoneRepresentativeModel representative;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.10)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? accent : glass.strokeColor,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.glass),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: isSelected ? accent : glass.onGlassMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            representative.name ?? 'مندوب بدون اسم',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.font14MediumText.copyWith(
                              color: glass.onGlass,
                            ),
                          ),
                        ),
                        if (representative.isPrimary) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _PrimaryChip(color: accent),
                        ],
                      ],
                    ),
                    if (representative.phoneNumber?.isNotEmpty ?? false)
                      Text(
                        representative.phoneNumber!,
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryChip extends StatelessWidget {
  const _PrimaryChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      'الأساسي',
      style: AppTextStyles.font12RegularHint.copyWith(color: color),
    ),
  );
}
