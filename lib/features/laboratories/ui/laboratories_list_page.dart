import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
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
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_state.dart';
import 'package:dental_lab_app/features/laboratories/ui/widgets/laboratory_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// An admin owns one lab by default (see "مختبري") but can create and switch
/// into operating as a different one, per `/api/clinic/Laboratories`.
class LaboratoriesListPage extends StatelessWidget {
  const LaboratoriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LaboratoriesCubit>()..getLaboratories(),
      child: const _LaboratoriesListView(),
    );
  }
}

class _LaboratoriesListView extends StatefulWidget {
  const _LaboratoriesListView();

  @override
  State<_LaboratoriesListView> createState() => _LaboratoriesListViewState();
}

class _LaboratoriesListViewState extends State<_LaboratoriesListView> {
  final _scrollController = ScrollController();

  /// Last successfully loaded laboratories, kept so a refresh can show the
  /// existing rows instead of replacing them with the loading skeleton.
  List<LaboratoryModel>? _lastLaboratories;

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
    LaboratoryModel laboratory,
  ) async {
    final cubit = context.read<LaboratoriesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المخبر',
      message: 'هل أنت متأكد من حذف مخبر "${laboratory.name ?? ''}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteLaboratory(laboratory.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.laboratoriesListScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'المخابر',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة مخبر',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.laboratoryFormScreen);
                if (context.mounted) {
                  context.read<LaboratoriesCubit>().getLaboratories();
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      ),
      body: SafeArea(
        child: BlocConsumer<LaboratoriesCubit, LaboratoriesState>(
          listener: (context, state) {
            switch (state) {
              case LaboratoryDeleted():
                ShowToast(message: 'تم حذف المخبر', state: toastState.success);
              case LaboratoryDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! LaboratoryDeleted &&
              current is! LaboratoryDeleteError,
          builder: (context, state) {
            if (state is LaboratoriesLoaded)
              _lastLaboratories = state.laboratories;

            final laboratories = switch (state) {
              LaboratoriesLoaded(:final laboratories) => laboratories,
              LaboratoriesLoading() => _lastLaboratories,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, laboratories)) {
                (_, final List<LaboratoryModel> loaded) => _LaboratoriesList(
                  key: const ValueKey('laboratories-loaded'),
                  laboratories: loaded,
                  activeLaboratoryId: context
                      .read<LaboratoriesCubit>()
                      .activeLaboratoryId,
                  scrollController: _scrollController,
                  onDelete: (laboratory) => _confirmDelete(context, laboratory),
                ),
                (LaboratoriesError(:final message), null) => Center(
                  key: const ValueKey('laboratories-error'),
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
                  key: ValueKey('laboratories-loading'),
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

class _LaboratoriesList extends StatelessWidget {
  const _LaboratoriesList({
    super.key,
    required this.laboratories,
    required this.activeLaboratoryId,
    required this.onDelete,
    this.scrollController,
  });

  final List<LaboratoryModel> laboratories;
  final String? activeLaboratoryId;
  final ValueChanged<LaboratoryModel> onDelete;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (laboratories.isEmpty) return _EmptyState();

    return AdaptiveCollection<LaboratoryModel>(
      items: laboratories,
      scrollController: scrollController,
      onRefresh: () => context.read<LaboratoriesCubit>().getLaboratories(),
      itemBuilder: (context, laboratory, _) => LaboratoryListItemWidget(
        name: laboratory.name ?? '—',
        address: laboratory.address ?? '',
        isActive: laboratory.isActive,
        isCurrent: laboratory.id == activeLaboratoryId,
        onTap: () =>
            context.push(Routes.laboratoryDetailScreen, extra: laboratory.id),
        onEdit: () async {
          await context.push(Routes.laboratoryFormScreen, extra: laboratory);
          if (context.mounted) {
            context.read<LaboratoriesCubit>().getLaboratories();
          }
        },
        onDelete: () => onDelete(laboratory),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
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
                    Icons.science_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد مخابر بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول مخبر بالضغط على زر الإضافة',
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
