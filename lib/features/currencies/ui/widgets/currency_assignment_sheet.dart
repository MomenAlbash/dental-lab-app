import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/currencies/logic/currency_assignment/currency_assignment_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Which currencies this laboratory trades in, and which one forms
/// pre-select.
Future<void> showLaboratoryCurrenciesSheet(BuildContext context) {
  return _show(context, clinicId: null, title: 'عملات المخبر');
}

/// Which of the laboratory's currencies one clinic settles in.
///
/// No default is asked for here: a clinic narrows the set, but which currency
/// a form pre-selects stays the laboratory's call.
Future<void> showClinicCurrenciesSheet(
  BuildContext context, {
  required String clinicId,
  required String clinicName,
}) {
  return _show(context, clinicId: clinicId, title: 'عملات $clinicName');
}

Future<void> _show(
  BuildContext context, {
  required String? clinicId,
  required String title,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = getIt<CurrencyAssignmentCubit>();
        if (clinicId == null) {
          cubit.loadForLaboratory();
        } else {
          cubit.loadForClinic(clinicId);
        }
        return cubit;
      },
      child: _CurrencyAssignmentSheet(isClinic: clinicId != null, title: title),
    ),
  );
}

class _CurrencyAssignmentSheet extends StatefulWidget {
  const _CurrencyAssignmentSheet({
    required this.isClinic,
    required this.title,
  });

  final bool isClinic;
  final String title;

  @override
  State<_CurrencyAssignmentSheet> createState() =>
      _CurrencyAssignmentSheetState();
}

class _CurrencyAssignmentSheetState extends State<_CurrencyAssignmentSheet> {
  /// Null until the first loaded state seeds it — the sheet has no opinion of
  /// its own about what is assigned.
  Set<String>? _selected;
  String? _defaultId;

  void _seed(CurrencyAssignmentLoaded state) {
    _selected ??= {for (final c in state.assignment.currencies) c.id};
    _defaultId ??= state.assignment.defaultCurrencyId;
  }

  void _toggle(String id) {
    setState(() {
      final selected = _selected ??= <String>{};
      if (selected.remove(id)) {
        // A default outside the set would leave forms pre-selecting a currency
        // the lab cannot invoice in, so it is cleared with the currency.
        if (_defaultId == id) _defaultId = null;
      } else {
        selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocConsumer<CurrencyAssignmentCubit, CurrencyAssignmentState>(
      listenWhen: (previous, current) =>
          current is CurrencyAssignmentSaved ||
          current is CurrencyAssignmentActionError,
      listener: (context, state) {
        switch (state) {
          case CurrencyAssignmentSaved(:final message):
            showToast(message: message, state: ToastState.success);
            Navigator.of(context).pop();
          case CurrencyAssignmentActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! CurrencyAssignmentSaved &&
          current is! CurrencyAssignmentActionError,
      builder: (context, state) {
        if (state is CurrencyAssignmentLoaded) _seed(state);

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.font16MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),

              switch (state) {
                CurrencyAssignmentLoaded(:final assignment, :final catalogue) =>
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The distinction is the feature: an inherited set
                      // follows later edits to the lab, an override freezes
                      // whatever it said the day it was set.
                      if (widget.isClinic && assignment.isInherited)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'تتبع حالياً عملات المخبر — الحفظ سيجعل لها قائمة خاصة',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.info,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final currency in catalogue)
                            FilterChip(
                              label: Text(currency.label),
                              tooltip: currency.name,
                              selected:
                                  _selected?.contains(currency.id) ?? false,
                              onSelected: (_) => _toggle(currency.id),
                            ),
                        ],
                      ),

                      if (!widget.isClinic) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'العملة الافتراضية',
                          style: AppTextStyles.font14MediumText.copyWith(
                            color: glass.onGlass,
                          ),
                        ),
                        Text(
                          'ما تفتح عليه النماذج. بلا اختيار، يسأل كل نموذج.',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            // Only what is actually assigned can be the
                            // default — offering the rest would invite exactly
                            // the mismatch the server rejects.
                            for (final currency in catalogue)
                              if (_selected?.contains(currency.id) ?? false)
                                ChoiceChip(
                                  label: Text(currency.label),
                                  selected: _defaultId == currency.id,
                                  onSelected: (selected) => setState(
                                    () => _defaultId = selected
                                        ? currency.id
                                        : null,
                                  ),
                                ),
                          ],
                        ),
                      ],

                      if (widget.isClinic && (_selected?.isEmpty ?? true))
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Text(
                            'بلا اختيار، تعود العيادة إلى عملات المخبر',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.lg),
                      CustomButtonWidget(
                        buttonText: 'حفظ',
                        onPressed: state.isBusy
                            ? null
                            : () => context
                                  .read<CurrencyAssignmentCubit>()
                                  .save(
                                    currencyIds: [...?_selected],
                                    defaultCurrencyId: _defaultId,
                                  ),
                      ),
                    ],
                  ),
                CurrencyAssignmentError(:final message) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CustomCircleProgressIndiacatorWidget(),
                ),
              },
            ],
          ),
        );
      },
    );
  }
}
