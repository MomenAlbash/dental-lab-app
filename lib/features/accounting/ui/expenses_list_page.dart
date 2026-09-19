import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/expense_model.dart';
import 'package:dental_lab_app/features/accounting/logic/expenses/expenses_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/expenses/expenses_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The lab's own expenses (`GET/POST /Accounting/expenses`) — rent,
/// supplies, anything spent that is not a payment to staff or a doctor.
class ExpensesListPage extends StatelessWidget {
  const ExpensesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExpensesCubit>()..getExpenses(),
      child: const _ExpensesListView(),
    );
  }
}

class _ExpensesListView extends StatelessWidget {
  const _ExpensesListView();

  Future<void> _openForm(BuildContext context) async {
    final cubit = context.read<ExpensesCubit>();
    final state = cubit.state;
    if (state is! ExpensesLoaded) return;

    final result = await showDialog<CreateExpenseRequestModel>(
      context: context,
      builder: (_) => _ExpenseFormDialog(currencies: state.currencies),
    );
    if (result == null) return;

    await cubit.addExpense(result);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.finance);

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.expensesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'المصاريف',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'إضافة مصروف',
              isExtended: true,
              onPressed: () => _openForm(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<ExpensesCubit, ExpensesState>(
          listenWhen: (previous, current) => current is ExpensesActionError,
          listener: (context, state) {
            if (state case ExpensesActionError(:final message)) {
              showToast(message: message, state: ToastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              ExpensesLoaded(:final expenses) =>
                expenses.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<ExpenseModel>(
                        items: expenses,
                        cardHeight: 108,
                        onRefresh: () =>
                            context.read<ExpensesCubit>().getExpenses(),
                        itemBuilder: (context, expense, _) =>
                            _ExpenseListItem(expense: expense),
                      ),
              ExpensesError(:final message) => Center(
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
                Icons.savings_outlined,
                size: 40,
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'لا توجد مصاريف بعد',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  const _ExpenseListItem({required this.expense});

  final ExpenseModel expense;

  String _date(DateTime? date) {
    if (date == null) return '—';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: radius,
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expense.category ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_date(expense.expenseDate)}'
                  '${expense.createdByName != null ? ' · ${expense.createdByName}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                if (expense.notes?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 3),
                  Text(
                    expense.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            expense.currency == null
                ? expense.amount.toStringAsFixed(2)
                : expense.currency!.format(expense.amount),
            style: AppTextStyles.font14MediumText.copyWith(color: glass.error),
          ),
        ],
      ),
    );
  }
}

class _ExpenseFormDialog extends StatefulWidget {
  const _ExpenseFormDialog({required this.currencies});

  final List<CurrencyModel> currencies;

  @override
  State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _currencyId;
  DateTime _expenseDate = DateTime.now();

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(_expenseDate.year - 3),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  String _isoDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      CreateExpenseRequestModel(
        currencyId: _currencyId,
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        category: _categoryController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        expenseDate: _isoDate(_expenseDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة مصروف', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  controller: _categoryController,
                  hintText: 'الفئة (مثال: إيجار، مستلزمات)',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'الفئة مطلوبة'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _amountController,
                  hintText: 'المبلغ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'أدخل مبلغاً صحيحاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CaseLookupDropdown(
                  value: _currencyId,
                  icon: Icons.attach_money_outlined,
                  hintText: 'اختر العملة (اختياري)',
                  items: widget.currencies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name ?? c.code ?? '—'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _currencyId = value),
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _notesController,
                  hintText: 'ملاحظات (اختياري)',
                  maxLines: 2,
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: context.glass.onGlassMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isoDate(_expenseDate),
                        style: AppTextStyles.font14MediumText,
                      ),
                    ],
                  ),
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
