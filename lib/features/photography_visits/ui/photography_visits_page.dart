import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_card.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visits/photography_visits_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visits/photography_visits_state.dart';
import 'package:dental_lab_app/features/photography_visits/ui/widgets/photography_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Standalone photography visits — shade-matching and cosmetic photography
/// for a doctor, tied to no case.
class PhotographyVisitsPage extends StatelessWidget {
  const PhotographyVisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PhotographyVisitsCubit>()..init(),
      child: const _PhotographyVisitsView(),
    );
  }
}

class _PhotographyVisitsView extends StatelessWidget {
  const _PhotographyVisitsView();

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<PhotographyVisitsCubit>();
    final created = await context.push<PhotographyVisitModel>(
      Routes.photographyVisitFormScreen,
    );
    if (created != null) await cubit.load();
  }

  Future<void> _open(BuildContext context, PhotographyVisitModel visit) async {
    final cubit = context.read<PhotographyVisitsCubit>();
    final changed = await context.push<bool>(
      Routes.photographyVisitDetailScreen,
      extra: visit.id,
    );
    if (changed ?? false) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.photographyVisitsScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'زيارات التصوير',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: GlassAddButton(
        label: 'طلب زيارة',
        isExtended: true,
        onPressed: () => _create(context),
      ),
      body: SafeArea(
        child: BlocBuilder<PhotographyVisitsCubit, PhotographyVisitsState>(
          builder: (context, state) => Column(
            children: [
              _Filters(state: state),
              Expanded(
                child: switch (state) {
                  PhotographyVisitsLoaded(:final visits) when visits.isEmpty =>
                    Center(
                      child: Text(
                        'لا توجد زيارات تصوير',
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ),
                  PhotographyVisitsLoaded(:final visits) => AdaptiveCollection(
                    items: visits,
                    onRefresh: context.read<PhotographyVisitsCubit>().load,
                    itemBuilder: (context, visit, _) => _VisitCard(
                      visit: visit,
                      onTap: () => _open(context, visit),
                    ),
                  ),
                  PhotographyVisitsError(:final message) => Center(
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
                  PhotographyVisitsLoading() => const Center(
                    child: CustomCircleProgressIndiacatorWidget(),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final PhotographyVisitsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PhotographyVisitsCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in <PhotographyVisitStatus?>[
                  null,
                  ...PhotographyVisitStatus.values,
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(status?.label ?? 'الكل'),
                      selected: state.status == status,
                      onSelected: (_) => cubit.setStatus(status),
                    ),
                  ),
              ],
            ),
          ),
          if (state.doctors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DropdownButtonFormField<String?>(
                  initialValue: state.doctorId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الطبيب',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(child: Text('كل الأطباء')),
                    for (final doctor in state.doctors)
                      DropdownMenuItem<String?>(
                        value: doctor.id,
                        child: Text(
                          doctor.fullName.isEmpty ? '—' : doctor.fullName,
                        ),
                      ),
                  ],
                  onChanged: cubit.setDoctor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.onTap});

  final PhotographyVisitModel visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final muted = AppTextStyles.font12RegularHint.copyWith(
      color: glass.onGlassMuted,
    );

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.doctorName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              PhotographyStatusChip(status: visit.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            visit.visitType.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
          const SizedBox(height: 2),
          Text(
            [
              if (visit.patientName != null) visit.patientName!,
              if (visit.scheduledAt != null)
                ApiTime.displayDateTime(visit.scheduledAt),
              visit.priceLabel,
              if (visit.photos.isNotEmpty) '${visit.photos.length} صور',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ],
      ),
    );
  }
}
