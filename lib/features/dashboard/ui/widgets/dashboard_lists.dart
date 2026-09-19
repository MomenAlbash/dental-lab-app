import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared glass row used by the three list sections, so a spacing or radius
/// change lands on all of them at once.
class _DashboardRow extends StatelessWidget {
  const _DashboardRow({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return ClipRRect(
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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cases falling due inside the coming window.
class DashboardUpcomingDueList extends StatelessWidget {
  const DashboardUpcomingDueList({super.key, required this.cases});

  final List<UpcomingDueCaseModel> cases;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < cases.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _UpcomingDueRow(model: cases[i]),
        ],
      ],
    );
  }
}

class _UpcomingDueRow extends StatelessWidget {
  const _UpcomingDueRow({required this.model});

  final UpcomingDueCaseModel model;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final days = model.daysUntilDue();

    // Overdue is a different fact from "due soon", so it gets its own colour
    // and its own words rather than a negative number.
    final (String dueText, Color dueColor) = switch (days) {
      null => ('بدون موعد', glass.onGlassMuted),
      < 0 => ('متأخرة ${-days} يوم', glass.error),
      0 => ('اليوم', glass.error),
      1 => ('غداً', glass.warning),
      _ => ('خلال $days يوم', glass.warning),
    };

    return _DashboardRow(
      onTap: () => context.push(Routes.caseDetailScreen, extra: model.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.caseNumber?.trim().isNotEmpty ?? false
                      ? model.caseNumber!
                      : 'حالة بدون رقم',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    model.doctorName,
                    model.stageLabel.isEmpty ? null : model.stageLabel,
                  ].whereType<String>().join(' · '),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: dueColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              dueText,
              style: AppTextStyles.font12RegularHint.copyWith(color: dueColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Doctors ranked by how many cases they sent in.
class DashboardTopDoctorsList extends StatelessWidget {
  const DashboardTopDoctorsList({super.key, required this.doctors});

  final List<TopDoctorModel> doctors;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      children: [
        for (var i = 0; i < doctors.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _DashboardRow(
            onTap: () => context.push(
              Routes.doctorDetailScreen,
              extra: doctors[i].doctorId,
            ),
            child: Row(
              children: [
                _DoctorAvatar(doctor: doctors[i], rank: i + 1),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    doctors[i].name?.trim().isNotEmpty ?? false
                        ? doctors[i].name!
                        : 'طبيب بدون اسم',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${doctors[i].caseCount} حالة',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.doctor, required this.rank});

  final TopDoctorModel doctor;
  final int rank;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final imageUrl = resolveMediaUrl(doctor.imagePath);

    // The rank number is the fallback rather than initials: this list is
    // ordered, and the position is the useful fact when there is no photo.
    final fallback = Center(
      child: Text(
        '$rank',
        style: AppTextStyles.font14MediumText.copyWith(color: Colors.white),
      ),
    );

    return Container(
      width: _size,
      height: _size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: glass.brandGradient,
      ),
      child: imageUrl == null
          ? fallback
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

/// Recent stage moves across the laboratory.
class DashboardRecentActivityList extends StatelessWidget {
  const DashboardRecentActivityList({super.key, required this.activity});

  final List<RecentActivityModel> activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < activity.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _ActivityRow(model: activity[i]),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.model});

  final RecentActivityModel model;

  /// A short relative time. Deliberately coarse — the exact minute of a stage
  /// move is on the case's own history, and this row only has to say "recent".
  String _relativeTime(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    // A return is a case going backwards for rework — the one thing on this
    // list a lab manager needs to spot, so it is marked by icon and colour.
    final color = model.isReturn ? glass.warning : glass.success;
    final icon = model.isReturn ? Icons.undo_rounded : Icons.arrow_forward;

    final from = model.previousStageName?.trim();
    final to = model.stageName?.trim();
    final move = [
      if (from != null && from.isNotEmpty) from,
      if (to != null && to.isNotEmpty) to,
    ].join(' ← ');

    return _DashboardRow(
      onTap: () => context.push(Routes.caseDetailScreen, extra: model.caseId),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.caseNumber?.trim().isNotEmpty ?? false
                      ? model.caseNumber!
                      : 'حالة بدون رقم',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                if (move.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    move,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
                if (model.changedByName?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    model.changedByName!,
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
            _relativeTime(model.changedAt),
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}
