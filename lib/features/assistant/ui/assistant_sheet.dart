import 'dart:async';

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/assistant/data/models/assistant_models.dart';
import 'package:dental_lab_app/features/assistant/logic/assistant_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The assistant panel.
///
/// Ask a question in words, get one of four answer shapes back. Rule-based
/// with no AI service behind it — and the text typed here is matched against a
/// catalogue already on the device, so only the resolved intent is sent.
Future<void> showAssistantSheet(BuildContext context) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => AssistantCubit(getIt())..load(),
      child: const _AssistantSheet(),
    ),
  );
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet();

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _controller = TextEditingController();

  /// Entity lookup is the one call carrying the typed fragment, so it waits
  /// for a pause rather than firing per keystroke — the same debounce every
  /// search box in this app uses.
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final cubit = context.read<AssistantCubit>();
    // Capability matching is local and instant — it does not wait.
    cubit.setQuery(value);

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => cubit.suggest(value),
    );
  }

  void _open(String actionUrl) {
    // The server picks the destination so this app never has to know which
    // route an entity type lives at — but a url it cannot route is dropped
    // rather than throwing on a screen that was only meant to help.
    if (actionUrl.isEmpty) return;
    Navigator.of(context).pop();
    context.push(actionUrl);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: BlocBuilder<AssistantCubit, AssistantState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'المساعد',
                      style: AppTextStyles.font18MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  controller: _controller,
                  hintText: 'اسأل عن حالة، طبيب، أو رقم…',
                  prefixIcon: Icon(
                    Icons.search,
                    color: glass.onGlassMuted,
                  ),
                  validator: (_) => null,
                  onChanged: _onChanged,
                ),
                const SizedBox(height: AppSpacing.md),

                switch (state) {
                  AssistantError(:final message) => Text(
                    message,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.error,
                    ),
                  ),
                  final AssistantReady ready => _ReadyBody(
                    state: ready,
                    onOpen: _open,
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

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state, required this.onOpen});

  final AssistantReady state;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cubit = context.read<AssistantCubit>();

    final capabilities = state.query.trim().isEmpty
        ? state.quickPrompts
        : state.matches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (capabilities.isEmpty && state.suggestions.isEmpty)
          Text(
            'لا يوجد ما يطابق ما كتبته',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final capability in capabilities)
                ActionChip(
                  label: Text(capability.displayLabel),
                  onPressed: state.isAsking
                      ? null
                      : () => cubit.ask(capability),
                ),
            ],
          ),

        if (state.suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const _GroupLabel('نتائج'),
          for (final suggestion in state.suggestions)
            _SuggestionRow(
              suggestion: suggestion,
              onTap: () => onOpen(suggestion.actionUrl),
            ),
        ],

        if (state.isAsking) ...[
          const SizedBox(height: AppSpacing.lg),
          const Center(child: CircularProgressIndicator()),
        ] else if (state.answer != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _Answer(answer: state.answer!, onOpen: onOpen),
        ],
      ],
    );
  }
}

/// One answer, in whichever of the four shapes it came back as.
class _Answer extends StatelessWidget {
  const _Answer({required this.answer, required this.onOpen});

  final AssistantAnswerModel answer;
  final ValueChanged<String> onOpen;

  Color _toneColor(GlassTokens glass, String? tone) => switch (tone) {
    'critical' => glass.error,
    'warning' => glass.warning,
    'success' => glass.success,
    'info' => glass.info,
    _ => glass.onGlassMuted,
  };

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
          if (answer.headline.isNotEmpty)
            Text(
              answer.headline,
              style: AppTextStyles.font14MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),

          if (answer.stats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                for (final stat in answer.stats)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.value == stat.value.roundToDouble()
                            ? stat.value.toStringAsFixed(0)
                            : stat.value.toStringAsFixed(2),
                        style: AppTextStyles.font20BoldText.copyWith(
                          color: _toneColor(glass, stat.tone),
                        ),
                      ),
                      Text(
                        stat.displayLabel,
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],

          for (final entity in answer.entities)
            _EntityRow(
              entity: entity,
              tone: _toneColor(glass, entity.tone),
              onTap: entity.actionUrl == null
                  ? null
                  : () => onOpen(entity.actionUrl!),
            ),

          for (final line in answer.series)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      // One line per currency: money is never blended here
                      // any more than anywhere else in the product.
                      line.label ?? line.currency?.code ?? '—',
                      style: AppTextStyles.font14RegularSecondary.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ),
                  Text(
                    line.totalLabel,
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ],
              ),
            ),

          if (answer.truncatedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'و${answer.truncatedCount} أخرى',
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

class _EntityRow extends StatelessWidget {
  const _EntityRow({required this.entity, required this.tone, this.onTap});

  final AssistantEntityModel entity;
  final Color tone;

  /// Null when the row has nowhere to go — it then draws as a plain row
  /// rather than something that looks tappable and does nothing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                if (entity.subtitle?.trim().isNotEmpty ?? false)
                  Text(
                    entity.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (entity.trailingText?.trim().isNotEmpty ?? false)
                Text(
                  entity.trailingText!,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              // Every amount with its own currency, one line each — a doctor
              // can owe in several at once.
              for (final money in entity.trailingMoney)
                Text(
                  money.label,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlass,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onTap});

  final AssistantSuggestionModel suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        suggestion.kind == 'doctor'
            ? Icons.person_outline
            : Icons.folder_outlined,
        size: 20,
        color: glass.onGlassMuted,
      ),
      title: Text(
        suggestion.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.font14MediumText.copyWith(color: glass.onGlass),
      ),
      subtitle: suggestion.subtitle?.trim().isNotEmpty ?? false
          ? Text(
              suggestion.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          : null,
      trailing: suggestion.badgeLabel == null
          ? null
          : Text(
              suggestion.badgeLabel!,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
      onTap: onTap,
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
