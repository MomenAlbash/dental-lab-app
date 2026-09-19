import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The four headline counters.
///
/// Each tile navigates to the list it counts — a number the user cannot act on
/// is decoration, and they came to the dashboard to get somewhere. A tile
/// whose list the user cannot even read is dropped rather than shown
/// disabled, same as the drawer: it would otherwise be a shortcut straight
/// past every other permission check to a screen that only greets them with
/// a lock.
class DashboardSummaryTiles extends StatelessWidget {
  const DashboardSummaryTiles({super.key, required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final permissions = getIt<SessionCubit>().state;

    final tiles = [
      _TileData(
        icon: Icons.folder_outlined,
        label: 'الحالات',
        value: summary.totalCases,
        color: Theme.of(context).colorScheme.primary,
        route: Routes.casesListScreen,
        requires: PermissionName.cases,
      ),
      _TileData(
        icon: Icons.medical_services_outlined,
        label: 'الأطباء',
        value: summary.totalDoctors,
        color: glass.info,
        route: Routes.doctorsListScreen,
        requires: PermissionName.users,
      ),
      _TileData(
        icon: Icons.local_hospital_outlined,
        label: 'العيادات',
        value: summary.totalClinics,
        color: glass.success,
        route: Routes.clinicsListScreen,
        requires: PermissionName.users,
      ),
      _TileData(
        icon: Icons.people_outline,
        label: 'المرضى',
        value: summary.totalPatients,
        color: glass.warning,
        route: Routes.patientsListScreen,
        requires: PermissionName.users,
      ),
    ].where((tile) => permissions.canRead(tile.requires)).toList();

    if (tiles.isEmpty) return const SizedBox.shrink();

    // Two per row on a phone, all four across from tablet up — four tiles on a
    // 360dp screen leaves each one too narrow for a five-figure count.
    return AdaptiveLayout.tabletUp(
      mobileLayout: (_) => Column(
        children: [
          _TileRow(tiles: tiles.take(2).toList()),
          if (tiles.length > 2) ...[
            const SizedBox(height: AppSpacing.md),
            _TileRow(tiles: tiles.skip(2).toList()),
          ],
        ],
      ),
      tabletLayout: (_) => _TileRow(tiles: tiles),
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.tiles});

  final List<_TileData> tiles;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: _SummaryTile(data: tiles[i])),
          ],
        ],
      ),
    );
  }
}

class _TileData {
  const _TileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.route,
    required this.requires,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final String route;
  final PermissionName requires;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.data});

  final _TileData data;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => context.push(data.route),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(data.icon, color: data.color, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${data.value}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font24BoldText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
