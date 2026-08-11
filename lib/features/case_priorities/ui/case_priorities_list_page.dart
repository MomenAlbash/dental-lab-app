import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/case_priorities_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CasePrioritiesListPage extends StatelessWidget {
  const CasePrioritiesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Inactive rows are included here and only here: this is the screen
      // where a retired priority has to stay visible to be edited back on.
      create: (_) =>
          getIt<CasePrioritiesCubit>()
            ..getCasePriorities(includeInactive: true),
      child: const _CasePrioritiesListView(),
    );
  }
}

class _CasePrioritiesListView extends StatefulWidget {
  const _CasePrioritiesListView();

  @override
  State<_CasePrioritiesListView> createState() =>
      _CasePrioritiesListViewState();
}

class _CasePrioritiesListViewState extends State<_CasePrioritiesListView> {
  final _scrollController = ScrollController();

  /// Last successfully loaded priorities, kept so a refresh can show the
  /// existing rows instead of replacing them with the loading skeleton.
  List<CasePriorityModel>? _lastPriorities;

  /// The add button collapses to an icon once the user starts scrolling, so a
  /// wide button never sits on top of the rows they are reading.
  bool _addButtonExtended = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldExtend = _scrollController.offset < 40;
    if (shouldExtend == _addButtonExtended) return;
    setState(() => _addButtonExtended = shouldExtend);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CasePriorityModel priority,
  ) async {
    final cubit = context.read<CasePrioritiesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الأولوية',
      message: 'هل أنت متأكد من حذف أولوية "${priority.displayName}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteCasePriority(priority.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.casePrioritiesListScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'أولويات الحالات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة أولوية',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.casePriorityFormScreen);
                if (context.mounted) {
                  context.read<CasePrioritiesCubit>().getCasePriorities(
                    includeInactive: true,
                  );
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      ),
      body: SafeArea(
        child: BlocConsumer<CasePrioritiesCubit, CasePrioritiesState>(
          listener: (context, state) {
            switch (state) {
              case CasePriorityDeleted():
                ShowToast(
                  message: 'تم حذف الأولوية',
                  state: toastState.success,
                );
              case CasePriorityDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              case CasePrioritiesSeeded():
                ShowToast(
                  message: 'تمت إضافة الأولويات الافتراضية',
                  state: toastState.success,
                );
              case CasePrioritiesSeedError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! CasePriorityDeleted &&
              current is! CasePriorityDeleteError &&
              current is! CasePrioritiesSeeded &&
              current is! CasePrioritiesSeedError,
          builder: (context, state) {
            if (state is CasePrioritiesLoaded) {
              _lastPriorities = state.priorities;
            }

            final priorities = switch (state) {
              CasePrioritiesLoaded(:final priorities) => priorities,
              CasePrioritiesLoading() => _lastPriorities,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, priorities)) {
                (_, final List<CasePriorityModel> loaded) when loaded.isEmpty =>
                  _EmptyState(
                    key: const ValueKey('case-priorities-empty'),
                    onSeedDefaults: () =>
                        context.read<CasePrioritiesCubit>().seedDefaults(),
                  ),
                (_, final List<CasePriorityModel> loaded) =>
                  CasePrioritiesListView(
                    key: const ValueKey('case-priorities-loaded'),
                    priorities: loaded,
                    scrollController: _scrollController,
                    onDelete: (priority) => _confirmDelete(context, priority),
                  ),
                (CasePrioritiesError(:final message), null) => Center(
                  key: const ValueKey('case-priorities-error'),
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
                _ => const Padding(
                  key: ValueKey('case-priorities-loading'),
                  padding: EdgeInsets.only(top: 24),
                  child: GlassListSkeleton(),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

/// Shown while the lab has no priorities. Cases cannot be created without
/// one, so this offers the API's default set as a one-tap way out instead of
/// making the user type four rows by hand.
class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.onSeedDefaults});

  final VoidCallback onSeedDefaults;

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
                    Icons.flag_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد أولويات بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أولوية بالضغط على زر الإضافة، أو ابدأ بالأولويات الافتراضية',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onSeedDefaults,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('إضافة الأولويات الافتراضية'),
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
