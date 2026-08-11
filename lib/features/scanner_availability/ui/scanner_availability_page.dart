import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_calendar/scanner_calendar_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_exceptions/scanner_exceptions_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_exceptions/scanner_exceptions_state.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_state.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/widgets/scanner_calendar_tab.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/widgets/scanner_exceptions_tab.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/widgets/scanner_rules_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Scanner availability — when the lab's scanner takes appointments.
///
/// Three views of one thing: the weekly windows, the date overrides, and the
/// calendar those two resolve into. The calendar is what the doctor sees when
/// booking a scan for a case, so this screen is upstream of every scanner
/// session in the app.
class ScannerAvailabilityPage extends StatelessWidget {
  const ScannerAvailabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ScannerRulesCubit>()..getRules()),
        BlocProvider(
          create: (_) => getIt<ScannerExceptionsCubit>()..getExceptions(),
        ),
        BlocProvider(
          create: (_) => getIt<ScannerCalendarCubit>()..getCalendar(),
        ),
      ],
      child: const _ScannerAvailabilityView(),
    );
  }
}

class _ScannerAvailabilityView extends StatefulWidget {
  const _ScannerAvailabilityView();

  @override
  State<_ScannerAvailabilityView> createState() =>
      _ScannerAvailabilityViewState();
}

class _ScannerAvailabilityViewState extends State<_ScannerAvailabilityView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  final _rulesKey = GlobalKey<ScannerRulesTabState>();
  final _exceptionsKey = GlobalKey<ScannerExceptionsTabState>();

  /// Which tab is showing — the add button belongs to the tab, and the
  /// calendar has nothing to add.
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == _tabIndex) return;
    setState(() => _tabIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  /// The calendar is derived from the other two, so it refetches whenever one
  /// of them changes — otherwise the preview quietly shows the old rules.
  void _refreshCalendar() => context.read<ScannerCalendarCubit>().getCalendar();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.scannerAvailabilityScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'مواعيد السكنر',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: glass.onGlassMuted,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'أسبوعياً'),
            Tab(text: 'استثناءات'),
            Tab(text: 'التقويم'),
          ],
        ),
      ),
      floatingActionButton: switch (_tabIndex) {
        0 =>
          GlassAddButton(
            label: 'إضافة موعد',
            isExtended: true,
            onPressed: () => _rulesKey.currentState?.openForm(),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
        1 =>
          GlassAddButton(
            label: 'إضافة استثناء',
            isExtended: true,
            onPressed: () => _exceptionsKey.currentState?.openForm(),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
        // The calendar is read-only — it is changed by editing the other tabs.
        _ => null,
      },
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<ScannerRulesCubit, ScannerRulesState>(
              listener: (context, state) {
                switch (state) {
                  case ScannerRuleSaved():
                    ShowToast(
                      message: 'تم حفظ الموعد الأسبوعي',
                      state: toastState.success,
                    );
                    _refreshCalendar();
                  case ScannerRuleDeleted():
                    ShowToast(
                      message: 'تم حذف الموعد الأسبوعي',
                      state: toastState.success,
                    );
                    _refreshCalendar();
                  case ScannerRuleSaveError(:final message):
                  case ScannerRuleDeleteError(:final message):
                    ShowToast(message: message, state: toastState.error);
                  default:
                    break;
                }
              },
            ),
            BlocListener<ScannerExceptionsCubit, ScannerExceptionsState>(
              listener: (context, state) {
                switch (state) {
                  case ScannerExceptionSaved():
                    ShowToast(
                      message: 'تم حفظ الاستثناء',
                      state: toastState.success,
                    );
                    _refreshCalendar();
                  case ScannerExceptionDeleted():
                    ShowToast(
                      message: 'تم حذف الاستثناء',
                      state: toastState.success,
                    );
                    _refreshCalendar();
                  case ScannerExceptionSaveError(:final message):
                  case ScannerExceptionDeleteError(:final message):
                    ShowToast(message: message, state: toastState.error);
                  default:
                    break;
                }
              },
            ),
          ],
          child: Column(
            children: [
              const _Intro(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ScannerRulesTab(key: _rulesKey),
                    ScannerExceptionsTab(key: _exceptionsKey),
                    const ScannerCalendarTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line saying who this screen is for. Without it, "أسبوعياً" and
/// "استثناءات" do not explain that the output is what doctors book against.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: glass.accentSurface,
          borderRadius: BorderRadius.circular(AppRadius.glass),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'يحدد الطبيب موعد جلسة السكنر من الأوقات المتاحة هنا',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
