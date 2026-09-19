import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/cashbox_model.dart';
import 'package:dental_lab_app/features/accounting/logic/cashbox/cashbox_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/cashbox/cashbox_state.dart';
import 'package:dental_lab_app/features/accounting/ui/widgets/cashbox_entry_dialog.dart';
import 'package:dental_lab_app/features/accounting/ui/widgets/cashbox_opening_balance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's cash drawer (`GET /Accounting/cashbox/ledger`).
///
/// **One box per currency, never a blended total.** Every verified payment,
/// every expense and every manual movement lands in the box of its own
/// currency, and the app shows them as separate ledgers with separate opening
/// and closing balances — adding a dollar box to a lira box would produce a
/// number that describes nothing in the drawer.
class CashboxPage extends StatelessWidget {
  const CashboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CashboxCubit>()..load(),
      child: const _CashboxView(),
    );
  }
}

class _CashboxView extends StatelessWidget {
  const _CashboxView();

  Future<void> _addEntry(BuildContext context) async {
    final cubit = context.read<CashboxCubit>();
    final state = cubit.state;
    if (state is! CashboxLoaded) return;

    final request = await showCashboxEntryDialog(
      context,
      currencies: state.currencies,
    );
    if (request == null) return;

    await cubit.addEntry(request);
  }

  Future<void> _setOpeningBalance(BuildContext context) async {
    final cubit = context.read<CashboxCubit>();
    final state = cubit.state;
    if (state is! CashboxLoaded) return;

    final request = await showCashboxOpeningBalanceDialog(
      context,
      currencies: state.currencies,
      existing: state.openingBalances,
    );
    if (request == null) return;

    await cubit.setOpeningBalance(request);
  }

  Future<void> _deleteEntry(
    BuildContext context,
    CashBoxLedgerEntryModel entry,
  ) async {
    final cubit = context.read<CashboxCubit>();
    final id = entry.entryId;
    if (id == null) return;

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الحركة',
      message: 'سيُحذف هذا القيد من الصندوق نهائياً.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deleteEntry(id);
  }

  Future<void> _pickWindow(BuildContext context) async {
    final cubit = context.read<CashboxCubit>();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      initialDateRange: cubit.from == null || cubit.to == null
          ? null
          : DateTimeRange(start: cubit.from!, end: cubit.to!),
    );
    if (range == null) return;

    await cubit.load(from: range.start, to: range.end);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.finance);

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.cashboxScreen),
      appBar: GlassAppBar(
        title: Text(
          'الصندوق',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          BlocBuilder<CashboxCubit, CashboxState>(
            builder: (context, state) {
              final hasWindow =
                  state is CashboxLoaded && (state.from != null || state.to != null);

              return Row(
                children: [
                  IconButton(
                    tooltip: 'اختيار فترة',
                    isSelected: hasWindow,
                    icon: const Icon(Icons.date_range_outlined),
                    onPressed: () => _pickWindow(context),
                  ),
                  if (hasWindow)
                    IconButton(
                      tooltip: 'إلغاء الفترة',
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      onPressed: () =>
                          context.read<CashboxCubit>().load(resetWindow: true),
                    ),
                  if (canEdit)
                    IconButton(
                      tooltip: 'الرصيد الافتتاحي',
                      icon: const Icon(Icons.account_balance_outlined),
                      onPressed: () => _setOpeningBalance(context),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'حركة نقدية',
              isExtended: true,
              onPressed: () => _addEntry(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<CashboxCubit, CashboxState>(
          listenWhen: (previous, current) =>
              current is CashboxActionError || current is CashboxActionSuccess,
          listener: (context, state) {
            switch (state) {
              case CashboxActionSuccess(:final message):
                showToast(message: message, state: ToastState.success);
              case CashboxActionError(:final message):
                // The server's own sentence: the five-minute window and the
                // admin bypass are its rules, and "failed" hides which was hit.
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! CashboxActionError && current is! CashboxActionSuccess,
          builder: (context, state) => switch (state) {
            CashboxLoaded(:final ledgers) =>
              ledgers.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: () => context.read<CashboxCubit>().load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        itemCount: ledgers.length,
                        itemBuilder: (context, index) => _CurrencyLedgerCard(
                          ledger: ledgers[index],
                          onDelete: canEdit
                              ? (entry) => _deleteEntry(context, entry)
                              : null,
                        ),
                      ),
                    ),
            CashboxError(:final message) => Center(
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
            _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
          },
        ),
      ),
    );
  }
}

/// One currency's box: its own opening balance, totals and lines.
class _CurrencyLedgerCard extends StatelessWidget {
  const _CurrencyLedgerCard({required this.ledger, required this.onDelete});

  final CashBoxLedgerModel ledger;

  /// Null without `Finance:FullAccess` — the rows then carry no delete at all.
  final ValueChanged<CashBoxLedgerEntryModel>? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        // The currency is never implicit on this screen: two
                        // boxes side by side are only telling apart by name.
                        ledger.currency?.name ??
                            ledger.currency?.code ??
                            'بلا عملة',
                        style: AppTextStyles.font16MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    Text(
                      ledger.format(ledger.closingBalance),
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: ledger.closingBalance < 0
                            ? glass.error
                            : glass.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _Total(
                      label: 'الافتتاحي',
                      value: ledger.format(ledger.openingBalance),
                      color: glass.onGlassMuted,
                    ),
                    _Total(
                      label: 'وارد',
                      value: ledger.format(ledger.totalIn),
                      color: glass.success,
                    ),
                    _Total(
                      label: 'صادر',
                      value: ledger.format(ledger.totalOut),
                      color: glass.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: glass.strokeColor),
          if (ledger.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'لا توجد حركات في هذه الفترة',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            )
          else
            for (final entry in ledger.entries)
              _LedgerRow(
                entry: entry,
                ledger: ledger,
                // Only a manual line can be taken back here; a payment or an
                // expense is managed from its own screen, and the server
                // sends no id for those at all.
                onDelete: onDelete == null || !entry.isManual
                    ? null
                    : () => onDelete!(entry),
              ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font14MediumText.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.ledger,
    required this.onDelete,
  });

  final CashBoxLedgerEntryModel entry;
  final CashBoxLedgerModel ledger;

  /// Null when this line cannot be deleted from here at all.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isIn = (entry.moneyIn ?? 0) > 0;
    final amount = isIn ? entry.moneyIn! : (entry.moneyOut ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            isIn ? Icons.south_west : Icons.north_east,
            size: 16,
            color: isIn ? glass.success : glass.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description?.trim().isNotEmpty ?? false
                      ? entry.description!
                      : (entry.source?.label ?? '—'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  [
                    ApiTime.displayDateTime(entry.date),
                    if (entry.source != null) entry.source!.label,
                    if (entry.reference?.trim().isNotEmpty ?? false)
                      entry.reference!,
                  ].join(' · '),
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
              Text(
                ledger.format(amount),
                style: AppTextStyles.font14MediumText.copyWith(
                  color: isIn ? glass.success : glass.error,
                ),
              ),
              Text(
                ledger.format(entry.runningBalance),
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),
          if (onDelete != null)
            IconButton(
              // Disabled with its reason rather than hidden: the five-minute
              // window is a rule worth learning, and a control that vanishes
              // teaches it to nobody.
              tooltip: entry.canDelete
                  ? 'حذف الحركة'
                  : (entry.deleteMessage ?? 'لا يمكن حذف هذه الحركة'),
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: entry.canDelete ? glass.error : glass.onGlassMuted,
              ),
              onPressed: entry.canDelete ? onDelete : null,
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد حركات في الصندوق',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ابدأ بتعيين الرصيد الافتتاحي لكل عملة، ثم سجّل الحركات النقدية',
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
