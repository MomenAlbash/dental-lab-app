import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
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
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dental_lab_app/features/zones/logic/zones/zones_cubit.dart';
import 'package:dental_lab_app/features/zones/logic/zones/zones_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ZonesListPage extends StatelessWidget {
  const ZonesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ZonesCubit>()..getZones(),
      child: const _ZonesListView(),
    );
  }
}

class _ZonesListView extends StatefulWidget {
  const _ZonesListView();

  @override
  State<_ZonesListView> createState() => _ZonesListViewState();
}

class _ZonesListViewState extends State<_ZonesListView> {
  /// Last successfully loaded zones, kept so a refresh shows the existing
  /// rows instead of a skeleton.
  List<ZoneModel>? _lastZones;

  bool get _canEdit =>
      getIt<SessionCubit>().state.canEdit(PermissionName.users);

  Future<void> _openForm({ZoneModel? zone}) async {
    final saved = await context.push<ZoneModel>(
      Routes.zoneFormScreen,
      extra: zone,
    );
    if (saved != null && mounted) {
      context.read<ZonesCubit>().getZones();
    }
  }

  Future<void> _confirmDelete(ZoneModel zone) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المنطقة',
      message: 'هل أنت متأكد من حذف منطقة "${zone.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;
    await context.read<ZonesCubit>().deleteZone(zone.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = _canEdit;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.zonesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'المناطق',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'إضافة منطقة',
              isExtended: true,
              onPressed: () => _openForm(),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<ZonesCubit, ZonesState>(
          listener: (context, state) {
            if (state is ZonesActionError) {
              showToast(message: state.message, state: ToastState.error);
            }
          },
          buildWhen: (_, current) => current is! ZonesActionError,
          builder: (context, state) {
            if (state is ZonesLoaded) _lastZones = state.zones;

            final zones = switch (state) {
              ZonesLoaded(:final zones) => zones,
              ZonesLoading() => _lastZones,
              _ => null,
            };

            if (zones != null) {
              return zones.isEmpty
                  ? const _EmptyState()
                  : AdaptiveCollection<ZoneModel>(
                      items: zones,
                      cardHeight: 132,
                      itemBuilder: (context, zone, _) => _ZoneListItem(
                        zone: zone,
                        onEdit: canEdit ? () => _openForm(zone: zone) : null,
                        onDelete: canEdit ? () => _confirmDelete(zone) : null,
                      ),
                    );
            }

            if (state is ZonesError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              );
            }

            return const GlassListSkeleton();
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
                    Icons.map_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد مناطق بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول منطقة بالضغط على زر الإضافة',
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

class _ZoneListItem extends StatelessWidget {
  const _ZoneListItem({
    required this.zone,
    required this.onEdit,
    required this.onDelete,
  });

  final ZoneModel zone;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                Container(
                  width: 4,
                  color: zone.isActive ? accent : glass.error,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: glass.brandGradient,
                          ),
                          child: const Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                zone.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${zone.areas.length} حي · ${zone.representatives.length} مندوب',
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                              if (!zone.isActive) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'غير مفعّلة',
                                  style: AppTextStyles.font12RegularHint
                                      .copyWith(color: glass.error),
                                ),
                              ],
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
