import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/doctor_statement_model.dart';
import 'package:dental_lab_app/features/accounting/logic/doctor_statement/doctor_statement_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/doctor_statement/doctor_statement_state.dart';
import 'package:dental_lab_app/features/accounting/ui/widgets/settle_doctor_dialog.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pick a doctor, see their running ledger — one card per currency
/// (`GET /Accounting/doctors/{id}/statement`).
class DoctorStatementPage extends StatelessWidget {
  const DoctorStatementPage({super.key, this.initialDoctorId});

  final String? initialDoctorId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DoctorStatementCubit>()),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
      ],
      child: _DoctorStatementView(initialDoctorId: initialDoctorId),
    );
  }
}

class _DoctorStatementView extends StatefulWidget {
  const _DoctorStatementView({this.initialDoctorId});

  final String? initialDoctorId;

  @override
  State<_DoctorStatementView> createState() => _DoctorStatementViewState();
}

class _DoctorStatementViewState extends State<_DoctorStatementView> {
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _doctorId = widget.initialDoctorId;
    final doctorId = _doctorId;
    if (doctorId != null) {
      context.read<DoctorStatementCubit>().getStatement(doctorId);
    }
  }

  void _onDoctorChanged(String? doctorId) {
    setState(() => _doctorId = doctorId);
    if (doctorId != null) {
      context.read<DoctorStatementCubit>().getStatement(doctorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.doctorStatementScreen),
      appBar: GlassAppBar(
        title: Text(
          'كشف حساب طبيب',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text('الطبيب', style: AppTextStyles.font14MediumText),
            const SizedBox(height: 8),
            BlocBuilder<DoctorsCubit, DoctorsState>(
              builder: (context, doctorsState) {
                final doctors = doctorsState is DoctorsLoaded
                    ? doctorsState.doctors
                    : null;
                return CaseLookupDropdown(
                  value: _doctorId,
                  icon: Icons.medical_services_outlined,
                  hintText: doctorsState is DoctorsLoading
                      ? 'جارٍ تحميل الأطباء...'
                      : 'اختر الطبيب',
                  items: doctors
                      ?.map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: _onDoctorChanged,
                );
              },
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            BlocConsumer<DoctorStatementCubit, DoctorStatementState>(
              listenWhen: (previous, current) =>
                  current is DoctorStatementActionSuccess ||
                  current is DoctorStatementActionError,
              listener: (context, state) {
                switch (state) {
                  case DoctorStatementActionSuccess(:final message):
                    showToast(message: message, state: ToastState.success);
                  case DoctorStatementActionError(:final message):
                    // The server's sentence: a settle can be refused for
                    // reasons only it knows (nothing outstanding any more,
                    // a currency the doctor is not billed in).
                    showToast(message: message, state: ToastState.error);
                  default:
                    break;
                }
              },
              // The two action states are announcements, not screens: letting
              // them build would blank the statement for a frame.
              buildWhen: (previous, current) =>
                  current is! DoctorStatementActionSuccess &&
                  current is! DoctorStatementActionError,
              builder: (context, state) {
                return switch (state) {
                  DoctorStatementLoaded(:final statement, :final isBusy) =>
                    _StatementBody(statement: statement, isBusy: isBusy),
                  DoctorStatementError(:final message) => Center(
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
                  DoctorStatementLoading() => const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: CustomCircleProgressIndiacatorWidget(),
                    ),
                  ),
                  _ => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'اختر طبيباً لعرض كشف حسابه',
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ),
                  ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementBody extends StatelessWidget {
  const _StatementBody({required this.statement, this.isBusy = false});

  final DoctorStatementModel statement;

  /// A settle is in flight — the actions disable while the numbers stay.
  final bool isBusy;

  /// Closes every outstanding invoice in this one currency.
  Future<void> _settle(
    BuildContext context,
    CurrencyStatementModel stats,
  ) async {
    final cubit = context.read<DoctorStatementCubit>();
    final currencyId = stats.currency?.id;
    if (currencyId == null) return;

    final result = await showSettleDoctorDialog(
      context,
      currencyLabel:
          stats.currency?.name ?? stats.currency?.code ?? '',
      outstanding: stats.currency!.format(stats.closingBalance),
    );
    if (result == null) return;

    await cubit.settle(
      currencyId: currencyId,
      method: result.method,
      notes: result.notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (statement.currencies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد حركات مسجّلة لهذا الطبيب بعد',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final currency in statement.currencies) ...[
          _CurrencyStatementCard(
            stats: currency,
            // Offered only where there is something to settle and only to a
            // user who may take money: a doctor square with the lab, or one
            // whose balance is in credit, has nothing to close.
            onSettle:
                isBusy ||
                    currency.closingBalance <= 0 ||
                    currency.currency == null ||
                    !getIt<SessionCubit>().state.canEdit(PermissionName.finance)
                ? null
                : () => _settle(context, currency),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _CurrencyStatementCard extends StatelessWidget {
  const _CurrencyStatementCard({required this.stats, this.onSettle});

  final CurrencyStatementModel stats;

  /// Null when there is nothing outstanding in this currency, when a settle
  /// is already running, or when the user may not take money.
  final VoidCallback? onSettle;

  String _amount(double value) => stats.currency == null
      ? value.toStringAsFixed(2)
      : stats.currency!.format(value);

  String _date(DateTime? date) {
    if (date == null) return '—';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.currency?.name ?? stats.currency?.code ?? 'عملة غير معروفة',
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _row(context, 'الرصيد الافتتاحي', _amount(stats.openingBalance)),
          _row(context, 'إجمالي الفواتير', _amount(stats.totalInvoiced)),
          _row(context, 'إجمالي المدفوع', _amount(stats.totalPaid)),
          _row(
            context,
            'الرصيد الختامي',
            _amount(stats.closingBalance),
            valueColor: stats.closingBalance > 0
                ? glass.warning
                : glass.success,
            emphasize: true,
          ),
          if (onSettle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: onSettle,
                icon: const Icon(Icons.done_all, size: 18),
                // Per currency, and the label says so: the same doctor can
                // owe in two currencies and settle only one today.
                label: const Text('تسوية الحساب بهذه العملة'),
              ),
            ),
          ],
          if (stats.entries.isNotEmpty) ...[
            const Divider(height: 24),
            const GlassSectionTitle('الحركات'),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in stats.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.description ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.font14MediumText.copyWith(
                              color: glass.onGlass,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_date(entry.date)}'
                            '${entry.caseNumber != null ? ' · ${entry.caseNumber}' : ''}',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          entry.debit != null
                              ? _amount(entry.debit!)
                              : '-${_amount(entry.credit ?? 0)}',
                          style: AppTextStyles.font14MediumText.copyWith(
                            color: entry.debit != null
                                ? glass.warning
                                : glass.success,
                          ),
                        ),
                        Text(
                          _amount(entry.runningBalance),
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool emphasize = false,
  }) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style:
                (emphasize
                        ? AppTextStyles.font16MediumText
                        : AppTextStyles.font14MediumText)
                    .copyWith(color: valueColor ?? glass.onGlass),
          ),
        ],
      ),
    );
  }
}
