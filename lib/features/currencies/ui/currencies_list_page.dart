import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/currencies/data/models/save_currency_request_models.dart';
import 'package:dental_lab_app/features/currencies/logic/currencies/currencies_cubit.dart';
import 'package:dental_lab_app/features/currencies/logic/currencies/currencies_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Currencies (`/api/clinic/Currencies`) — every other feature's currency
/// picker (expenses, restoration-type pricing, case restorations, ...) reads
/// from the same list this screen manages.
class CurrenciesListPage extends StatelessWidget {
  const CurrenciesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CurrenciesCubit>()..getCurrencies(),
      child: const _CurrenciesListView(),
    );
  }
}

class _CurrenciesListView extends StatelessWidget {
  const _CurrenciesListView();

  Future<void> _openForm(
    BuildContext context, {
    CurrencyModel? currency,
  }) async {
    final cubit = context.read<CurrenciesCubit>();
    final result =
        await showDialog<({String name, String code, String? symbol})>(
          context: context,
          builder: (_) => _CurrencyFormDialog(initialCurrency: currency),
        );
    if (result == null) return;

    if (currency == null) {
      await cubit.addCurrency(
        CreateCurrencyRequestModel(
          name: result.name,
          code: result.code,
          symbol: result.symbol,
        ),
      );
    } else {
      await cubit.editCurrency(
        id: currency.id,
        requestBody: UpdateCurrencyRequestModel(
          name: result.name,
          code: result.code,
          symbol: result.symbol,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CurrencyModel currency,
  ) async {
    if (!currency.canDelete) {
      showToast(
        message: currency.deleteMessage ?? 'لا يمكن حذف هذه العملة',
        state: ToastState.error,
      );
      return;
    }

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف العملة',
      message: 'هل أنت متأكد من حذف "${currency.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<CurrenciesCubit>().removeCurrency(currency.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.currenciesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'العملات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'إضافة عملة',
            isExtended: true,
            onPressed: () => _openForm(context),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
      body: SafeArea(
        child: BlocConsumer<CurrenciesCubit, CurrenciesState>(
          listenWhen: (previous, current) => current is CurrenciesActionError,
          listener: (context, state) {
            if (state case CurrenciesActionError(:final message)) {
              showToast(message: message, state: ToastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              CurrenciesLoaded(:final currencies) =>
                currencies.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<CurrencyModel>(
                        items: currencies,
                        cardHeight: 92,
                        onRefresh: () =>
                            context.read<CurrenciesCubit>().getCurrencies(),
                        itemBuilder: (context, currency, _) =>
                            _CurrencyListItem(
                              currency: currency,
                              onEdit: () =>
                                  _openForm(context, currency: currency),
                              onDelete: () => _confirmDelete(context, currency),
                            ),
                      ),
              CurrenciesError(:final message) => Center(
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
            };
          },
        ),
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
                    Icons.attach_money_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد عملات بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول عملة بالضغط على زر الإضافة',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

class _CurrencyListItem extends StatelessWidget {
  const _CurrencyListItem({
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  final CurrencyModel currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: glass.brandGradient,
                          ),
                          child: Text(
                            (currency.symbol?.trim().isNotEmpty ?? false)
                                ? currency.symbol!.trim()
                                : (currency.code ?? '—'),
                            style: AppTextStyles.font14MediumText.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currency.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                currency.code ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onEdit != null || onDelete != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          if (onEdit != null)
                            IconButton(
                              tooltip: 'تعديل',
                              onPressed: onEdit,
                              icon: Icon(
                                Icons.edit_outlined,
                                color: glass.onGlassMuted,
                              ),
                            ),
                          if (onDelete != null)
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                color: glass.error,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyFormDialog extends StatefulWidget {
  const _CurrencyFormDialog({this.initialCurrency});

  final CurrencyModel? initialCurrency;

  @override
  State<_CurrencyFormDialog> createState() => _CurrencyFormDialogState();
}

class _CurrencyFormDialogState extends State<_CurrencyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialCurrency?.name ?? '',
  );
  late final _codeController = TextEditingController(
    text: widget.initialCurrency?.code ?? '',
  );
  late final _symbolController = TextEditingController(
    text: widget.initialCurrency?.symbol ?? '',
  );

  bool get _isEditing => widget.initialCurrency != null;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      symbol: _symbolController.text.trim().isEmpty
          ? null
          : _symbolController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل العملة' : 'إضافة عملة',
        style: AppTextStyles.font18MediumText,
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  controller: _nameController,
                  hintText: 'اسم العملة (مثال: ليرة سورية)',
                  prefixIcon: Icon(
                    Icons.attach_money_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اسم العملة مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _codeController,
                  hintText: 'الرمز الدولي (مثال: SYP)',
                  prefixIcon: Icon(
                    Icons.tag_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'الرمز الدولي مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _symbolController,
                  hintText: 'رمز العملة (اختياري، مثال: ل.س)',
                  prefixIcon: Icon(
                    Icons.currency_exchange_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (_) => null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('حفظ')),
      ],
    );
  }
}
