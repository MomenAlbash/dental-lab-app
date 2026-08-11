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
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:dental_lab_app/features/restoration_types/ui/widgets/restoration_types_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RestorationTypesListPage extends StatelessWidget {
  const RestorationTypesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RestorationTypesCubit>()..getRestorationTypes(),
      child: const _RestorationTypesListView(),
    );
  }
}

class _RestorationTypesListView extends StatefulWidget {
  const _RestorationTypesListView();

  @override
  State<_RestorationTypesListView> createState() =>
      _RestorationTypesListViewState();
}

class _RestorationTypesListViewState extends State<_RestorationTypesListView> {
  final _scrollController = ScrollController();

  /// Last successfully loaded types, kept so a refresh can show the existing
  /// rows instead of replacing them with the loading skeleton.
  List<RestorationTypeModel>? _lastTypes;

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
    RestorationTypeModel type,
  ) async {
    final cubit = context.read<RestorationTypesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف التعويض',
      message: 'هل أنت متأكد من حذف تعويض "${type.displayName}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteRestorationType(type.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.restorationTypesListScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'التعويضات السنية',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة تعويض',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.restorationTypeFormScreen);
                if (context.mounted) {
                  context.read<RestorationTypesCubit>().getRestorationTypes();
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      ),
      body: SafeArea(
        child: BlocConsumer<RestorationTypesCubit, RestorationTypesState>(
          listener: (context, state) {
            switch (state) {
              case RestorationTypeDeleted():
                ShowToast(message: 'تم حذف التعويض', state: toastState.success);
              case RestorationTypeDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! RestorationTypeDeleted &&
              current is! RestorationTypeDeleteError,
          builder: (context, state) {
            if (state is RestorationTypesLoaded) _lastTypes = state.types;

            final types = switch (state) {
              RestorationTypesLoaded(:final types) => types,
              RestorationTypesLoading() => _lastTypes,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, types)) {
                (_, final List<RestorationTypeModel> loaded)
                    when loaded.isEmpty =>
                  _EmptyState(key: const ValueKey('restoration-types-empty')),
                (_, final List<RestorationTypeModel> loaded) =>
                  RestorationTypesListView(
                    key: const ValueKey('restoration-types-loaded'),
                    types: loaded,
                    scrollController: _scrollController,
                    onDelete: (type) => _confirmDelete(context, type),
                  ),
                (RestorationTypesError(:final message), null) => Center(
                  key: const ValueKey('restoration-types-error'),
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
                  key: ValueKey('restoration-types-loading'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

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
                    Icons.category_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد تعويضات بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول تعويض بالضغط على زر الإضافة',
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
