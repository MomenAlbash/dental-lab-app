import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/representatives/data/models/representative_agent_model.dart';
import 'package:dental_lab_app/features/representatives/data/repos/representative_agents_repo.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Which agent a representative reports to, and every agent they have
/// reported to before.
///
/// **Edited as a history, not a field.** Assigning an agent closes the current
/// spell and opens a new one, so the list keeps every arrangement with the
/// dates it held — which is what any question about a past month depends on.
/// The active spell is the highlighted row; the rest are the record.
Future<void> showRepresentativeAgentSheet(
  BuildContext context, {
  required String representativeUserId,
  required String representativeName,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    // The candidate list is loaded here rather than passed in: an agent is an
    // ordinary login, so the users list is the answer, and every caller would
    // otherwise have to fetch it just to open this.
    builder: (_) => BlocProvider(
      create: (_) => getIt<UsersCubit>()..getUsers(),
      child: _RepresentativeAgentSheet(
        representativeUserId: representativeUserId,
        representativeName: representativeName,
      ),
    ),
  );
}

class _RepresentativeAgentSheet extends StatefulWidget {
  const _RepresentativeAgentSheet({
    required this.representativeUserId,
    required this.representativeName,
  });

  final String representativeUserId;
  final String representativeName;

  @override
  State<_RepresentativeAgentSheet> createState() =>
      _RepresentativeAgentSheetState();
}

class _RepresentativeAgentSheetState extends State<_RepresentativeAgentSheet> {
  final _noteController = TextEditingController();

  List<RepresentativeAgentModel>? _history;
  String? _error;
  String? _selectedAgentId;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _history = null;
      _error = null;
    });

    final result = await getIt<RepresentativeAgentsRepo>().getHistory(
      widget.representativeUserId,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _error = failure.errorMessage),
      (history) => setState(() => _history = history),
    );
  }

  Future<void> _assign() async {
    final agentId = _selectedAgentId;
    if (agentId == null) return;

    setState(() => _isBusy = true);
    final note = _noteController.text.trim();

    final result = await getIt<RepresentativeAgentsRepo>().assign(
      AssignRepresentativeAgentRequestModel(
        representativeUserId: widget.representativeUserId,
        agentUserId: agentId,
        note: note.isEmpty ? null : note,
      ),
    );
    if (!mounted) return;

    setState(() => _isBusy = false);

    await result.fold(
      (failure) async =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) async {
        showToast(message: 'تم تعيين الوكيل', state: ToastState.success);
        _noteController.clear();
        setState(() => _selectedAgentId = null);
        await _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final history = _history;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'وكيل المندوب',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            Text(
              widget.representativeName,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const _GroupLabel('تعيين وكيل'),
            BlocBuilder<UsersCubit, UsersState>(
              builder: (context, state) {
                final users = state is UsersLoaded ? state.users : const [];

                return CaseLookupDropdown(
                  value: _selectedAgentId,
                  icon: Icons.supervisor_account_outlined,
                  hintText: 'الوكيل',
                  items: [
                    for (final user in users)
                      // Nobody reports to themselves.
                      if (user.id != widget.representativeUserId)
                        DropdownMenuItem(
                          value: user.id,
                          child: Text(user.username ?? user.email ?? '—'),
                        ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedAgentId = value),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextFormField(
              controller: _noteController,
              hintText: 'ملاحظة (اختيارية)',
              maxLines: 2,
              validator: (_) => null,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _isBusy || _selectedAgentId == null ? null : _assign,
              child: const Text('تعيين'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'يُغلق الارتباط الحالي ويبدأ ارتباط جديد من اليوم',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const _GroupLabel('السجل'),
            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              )
            else if (history == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (history.isEmpty)
              Text(
                'لم يُربط هذا المندوب بأي وكيل بعد',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              )
            else
              for (final spell in history) _SpellRow(spell: spell),
          ],
        ),
      ),
    );
  }
}

/// One spell. The active one is outlined rather than merely first: a history
/// read top-down has no other way to say which arrangement is in force.
class _SpellRow extends StatelessWidget {
  const _SpellRow({required this.spell});

  final RepresentativeAgentModel spell;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(
          color: spell.isActive ? accent : glass.strokeColor,
          width: spell.isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spell.agentLabel,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  spell.periodLabel,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                if (spell.note?.trim().isNotEmpty ?? false)
                  Text(
                    spell.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (spell.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'الحالي',
                style: AppTextStyles.font12RegularHint.copyWith(color: accent),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.font14MediumText.copyWith(
          color: context.glass.onGlass,
        ),
      ),
    );
  }
}
